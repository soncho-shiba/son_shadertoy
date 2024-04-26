
#define PI 3.14159265

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

float sdSphere(vec3 p,float r)
{
    return length(p)-r;
}

float sdRoundBox(vec3 p,vec3 b,float r)
{
    vec3 q=abs(p)-b+r;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)-r;
}

float sdPlane(vec3 p,vec3 n,float h){
    // nは正規化された法線
    // hは原点からの距離
    return dot(p,n)+h;
}

float map(vec3 p){
    float floor=sdPlane(p,vec3(0,1,0),0.);
    float chair=sdRoundBox(p,vec3(40.,80.,40.),1.);
    return min(chair,floor);
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal(in vec3 pos)
{
    vec2 e=vec2(1.,-1.)*.5773;
    const float eps=.0005;
    return normalize(e.xyy*map(pos+e.xyy*eps)+
    e.yyx*map(pos+e.yyx*eps)+
    e.yxy*map(pos+e.yxy*eps)+
    e.xxx*map(pos+e.xxx*eps));
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
    vec3 ray=normalize(camRight*uv.x+camUp*uv.y+camForward/tan(radians(fov)));
    vec3 p=camOrigin;
    
    float total=0.;
    bool hit=false;
    for(int i=0;i<512;i++)
    {
        float d=map(p);
        if(d<.0001)
        {
            hit=true;
            break;
        }
        total+=d;
        p=camOrigin+ray*total;
    }
    
    vec3 col=vec3(0.,0.,0.);
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