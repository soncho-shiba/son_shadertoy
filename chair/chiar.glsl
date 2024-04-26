
#define PI 3.14159265
const int MAX_MARCHING_STEPS=511;
const float MIN_DIST=0.;
const float MAX_DIST=5000.;
const float PRECISION=.0001;
const vec3 SCENE_COLOR=vec3(.8,1.,1.);

// 角度ベクトルからXYZ順で回転行列を生成する関数
mat3 rotationMatrix(vec3 rot){
    
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

//https://iquilezles.org/articles/distfunctions/
float sdPlane(vec3 p,vec3 n,float h){
    // nは正規化された法線である必要がある
    return dot(p,n)+h;
}

float sdRoundBox(vec3 p,vec3 b,float r,vec3 offset){
    offset.y+=b.y;//原点を(b.y)Yminに設定してoffsetする
    p-=offset;
    vec3 q=abs(p)-b+r;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)-r;
}

float sdChair(vec3 p){
    p*=rotationMatrix(vec3(0.,200.,0));
    
    float seat=sdRoundBox(p,vec3(30.,5.,28.),3.,vec3(0.,60.,0.));
    float legR=sdRoundBox(p,vec3(3.,30.,3.),1.,vec3(22.,0.,20.));
    float legL=sdRoundBox(p,vec3(3.,30.,3.),1.,vec3(-22.,0.,20.));
    float frontSupport=sdRoundBox(p,vec3(25.,3.,3.),1.,vec3(0.,57.,20.));
    float backSupportR=sdRoundBox(p,vec3(3.,68.,3.),1.,vec3(22.,0.,-27.));
    float backSupportL=sdRoundBox(p,vec3(3.,68.,3.),1.,vec3(-22.,0.,-27.));
    
    float backrest=sdRoundBox(p,vec3(32.,20.,3.),3.,vec3(0.,100.,-20.));
    
    float whiteBox=sdRoundBox(p,vec3(40.,80.,40.),1.,vec3(0.));
    
    float d=0.;
    d=min(legR,legL);
    d=min(d,seat);
    d=min(d,frontSupport);
    d=min(d,backSupportR);
    d=min(d,backSupportL);
    d=min(d,backrest);
    // d=min(d,whiteBox);
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

float rayMarch(vec3 ro,vec3 rd,float start,float end){
    float depth=start;
    
    for(int i=0;i<MAX_MARCHING_STEPS;i++){
        vec3 p=ro+depth*rd;
        float d=map(p);
        depth+=d;
        if(d<PRECISION||depth>end)break;
    }
    
    return depth;
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

vec3 render(vec3 ro,vec3 rd){
    vec3 col=SCENE_COLOR;
    float d=rayMarch(ro,rd,MIN_DIST,MAX_DIST);
    
    if(d>MAX_DIST)return col;// ray didn't hit anything
    vec3 p=ro+rd*d;
    vec3 normal=calcNormal(p);
    
    vec3 lightPosition=vec3(357.,600.,6.);
    mat3 lightRotMatrix=rotationMatrix(vec3(-88.,5.5,-60.));
    vec3 lightDirection=normalize(lightRotMatrix*vec3(0.,0.,-1.));
    float dif=clamp(dot(normal,lightDirection),.3,1.);
    
    col=dif*SCENE_COLOR;
    
    return col;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    vec3 col=vec3(0);
    vec3 sceneCol=vec3(.8,1.,1.);
    
    vec2 uv=fragCoord/iResolution.xy;
    uv-=.5;
    uv.x*=iResolution.x/iResolution.y;
    
    vec3 ro=vec3(0.,130.,-817.);
    vec3 camTarget=vec3(0.,45.,0.);
    mat3 camRotMatrix=rotationMatrix(vec3(-5.,0.,0.));
    
    vec3 camUp=normalize(camRotMatrix*vec3(0.,1.,0.));
    vec3 camForward=normalize(ro-camTarget);
    vec3 camRight=normalize(cross(camForward,camUp));
    float fov=150.;
    //TOOD:zoomを作成する
    
    vec3 rd=normalize(camRight*uv.x+camUp*uv.y+camForward/tan(radians(fov)));
    vec3 p=ro;
    float d=rayMarch(p,rd,MIN_DIST,MAX_DIST);
    
    col=render(ro,rd);
    
    fragColor=vec4(col,1.);
}