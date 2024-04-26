
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

float getMap(vec3 p){
    float floor=sdPlane(p,vec3(0,1,0),0.);
    float chair=sdRoundBox(p,vec3(40.,80.,40.),1.);
    return min(chair,floor);
}

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    vec2 uv=fragCoord/iResolution.xy;
    uv-=.5;
    uv.x*=iResolution.x/iResolution.y;
    
    // ワールド基底ベクトル
    vec3 forward=vec3(0.,0.,-1.);
    vec3 up=vec3(0.,1.,0.);
    
    // camera
    vec3 camOrigin=vec3(0.,136.1,816);
    vec3 camRot=vec3(-3.,-.8,0.);
    mat3 camRotMatrix=getRotationMatrix(camRot);
    
    vec3 camForward=normalize(camRotMatrix*forward);
    vec3 camUp=normalize(camRotMatrix*forward);
    vec3 camRight=normalize(cross(camForward,camUp));
    float fov=100.;
    
    vec3 ray=normalize(camRight*uv.x+camUp*uv.y+camForward/tan(fov/360.*PI));
    vec3 p=camOrigin;
    
    float total=0.;
    bool hit=false;
    for(int i=0;i<512;i++)
    {
        float d=getMap(p);
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
        col=.5+.5*cos(iTime+uv.xyx+vec3(0,2,4));
    }
    else{
        col=vec3(0.,0.,0.);
    }
    fragColor=vec4(col,1.);
}