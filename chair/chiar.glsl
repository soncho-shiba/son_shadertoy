
#define PI 3.14159265
const int MAX_MARCHING_STEPS=511;
const float MIN_DIST=0.;
const float MAX_DIST=1000.;
const float PRECISION=.0001;

struct Surface{
    float sd;// signed distance value
    vec3 col;// color
};
// 角度ベクトルからXYZ順で回転行列を生成する関数
mat3 getRotationMatrix(vec3 rot){
    
    // 角度をラジアンに変換
    float radX=radians(rot.x);
    float radY=radians(rot.y);
    float radZ=radians(rot.z);
    
    mat3 rotX=mat3(
        1.,0.,0.,
        0.,cos(radX),-sin(radX),
        0.,sin(radX),cos(radX)
    );
    
    mat3 rotY=mat3(
        cos(radY),0.,sin(radY),
        0.,1.,0.,
        -sin(radY),0.,cos(radY)
    );
    
    mat3 rotZ=mat3(
        cos(radZ),-sin(radZ),0.,
        sin(radZ),cos(radZ),0.,
        0.,0.,1.
    );
    
    // 全体の回転行列を合成 (XYZ順)
    mat3 rotationMatrix=rotZ*rotY*rotX;
    return rotationMatrix;
}

// 任意の軸周りでベクトルを回転させる関数
vec3 rotate(vec3 p,float angle,vec3 axis){
    
    // 回転軸を正規化
    vec3 a=normalize(axis);
    // サインとコサインを計算
    float s=sin(angle);
    float c=cos(angle);
    
    // 1 - cos(angle) を計算
    float r=1.-c;
    
    // 回転行列の成分を計算
    mat3 m=mat3(
        a.x*a.x*r+c,// 列1, 行1
        a.y*a.x*r+a.z*s,// 列1, 行2
        a.z*a.x*r-a.y*s,// 列1, 行3
        a.x*a.y*r-a.z*s,// 列2, 行1
        a.y*a.y*r+c,// 列2, 行2
        a.z*a.y*r+a.x*s,// 列2, 行3
        a.x*a.z*r+a.y*s,// 列3, 行1
        a.y*a.z*r-a.x*s,// 列3, 行2
        a.z*a.z*r+c// 列3, 行3
    );
    // 行列をベクトルに適用して回転したベクトルを返す
    return m*p;
}

float sdRoundBox(vec3 p,vec3 b,float r,vec3 offset){
    //原点をYminに変更
    p=p-b.y;
    p=p-offset;
    vec3 q=abs(p)-b+r;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)-r;
}
//https://iquilezles.org/articles/distfunctions/
float sdPlane(vec3 p,vec3 n,float h){
    // nは正規化された法線である必要がある
    return dot(p,n)+h;
}

float sdChair(vec3 p){
    p=rotate(p,90.,vec3(0.,1.,0.));
    // TODO ：回転軸を合わせる
    //float whiteBox=sdRoundBox(rotP,vec3(40.,80.,40.),vec3(0.,80.,0.),1.);
    float legs=sdRoundBox(vec3(abs(p.x),p.y,abs(p.z)),vec3(3.,35.,3.),1.,vec3(0.,0.,0.));
    float seat=sdRoundBox(p,vec3(37.,6.,37.),1.,vec3(0.,70.,0.));
    float backrestSupport=sdRoundBox(vec3(p.x,p.y,abs(p.z)),vec3(3.,44.,3.),1.,vec3(0.,70.,0.));
    float backrest=sdRoundBox(vec3(p.x,p.y,p.z),vec3(3.,22.,37.),1.,vec3(0.,100.,0.));
    
    float d=min(min(min(legs,seat),backrestSupport),backrest);
    return d;
}

float sdRoom(vec3 p){
    float floor=sdPlane(p,vec3(0.,1.,0.),0.);
    // float wall=sdPlane(p,vec3(0.,5.,1.),1000.);
    return floor;
}

float map(vec3 p){
    vec3 sceneColor=vec3(.9,.9,.9);
    float room=sdRoom(p);
    float chair=sdChair(p);
    return min(chair,room);
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal(in vec3 p){
    vec2 e=vec2(1.,-1.)*.5773;
    const float eps=.0005;
    return normalize(e.xyy*map(p+e.xyy*eps)+
    e.yyx*map(p+e.yyx*eps)+
    e.yxy*map(p+e.yxy*eps)+
    e.xxx*map(p+e.xxx*eps));
}

float rayMarch(vec3 ro,vec3 rd,float start,float end){
    float depth=start;
    for(int i=0;i<MAX_MARCHING_STEPS;i++){
        vec3 p=ro+depth*rd;
        depth+=map(p);
        if(depth<PRECISION||depth>end)break;
    }
    return depth;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    vec2 uv=fragCoord/iResolution.xy;
    uv-=.5;
    uv.x*=iResolution.x/iResolution.y;
    
    vec3 camOrigin=vec3(0.,130.,-817.);
    vec3 camTarget=vec3(0.,45.,0.);
    vec3 camRot=vec3(-5.,0.,0.);
    mat3 camRotMatrix=getRotationMatrix(camRot);
    
    vec3 camUp=normalize(camRotMatrix*vec3(0.,1.,0.));
    vec3 camForward=normalize(camOrigin-camTarget);
    vec3 camRight=normalize(cross(camForward,camUp));
    float fov=150.;
    //TOOD:zoomを作成する
    
    vec3 ray=normalize(camRight*uv.x+camUp*uv.y+camForward/tan(radians(fov)));
    vec3 p=camOrigin;
    
    float total=0.;
    bool hit=false;
    for(int i=0;i<512;i++)
    {
        float d=map(p);
        if(d<PRECISION)
        {
            hit=true;
            break;
        }
        total+=d;
        p=camOrigin+ray*total;
    }
    
    vec3 col=vec3(0);
    vec3 sceneCol=vec3(.8,1.,1.);
    if(hit){
        vec3 normal=calcNormal(p);
        vec3 diffuseCol=vec3(.8,.8,.7);
        float diffuse=clamp(dot(normal,vec3(.57703)),0.,1.);
        vec3 ambientCol=vec3(.8,1.,1.);
        float ambient=.5+.5*dot(normal,vec3(0.,1.,0.));
        col=diffuseCol*diffuse+ambientCol*ambient;
    }
    else{
        col=vec3(0.,0.,0.);
    }
    fragColor=vec4(col,1.);
}