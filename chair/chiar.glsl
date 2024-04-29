#include "D:/CG_Work/Work/Git/son_shadertoy/chair/func.glsl"

#define PI 3.14159265
const int MAX_MARCHING_STEPS=511;
const float MIN_DIST=0.;
const float MAX_DIST=5000.;
const float PRECISION=.0001;
const vec3 SKY_COLOR=vec3(.6627,.9608,.9137);

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

float sdBox(vec3 p,vec3 b,vec3 offset)
{
    offset.y+=b.y;//原点を(b.y)Yminに設定してoffsetする
    p-=offset;
    vec3 q=abs(p)-b;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
}

float sdRoundBox(vec3 p,vec3 b,float r,vec3 offset){
    offset.y+=b.y;//原点を(b.y)Yminに設定してoffsetする
    p-=offset;
    vec3 q=abs(p)-b+r;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)-r;
}

float sdChair(vec3 p){
    
    p*=rotationMatrix(vec3(0.,200.,0));
    
    float seat=sdRoundBox(p,vec3(30.,4.,28.),3.,vec3(0.,59.,0.));
    float legR=sdRoundBox(p,vec3(3.,30.,3.),1.,vec3(25.,0.,20.));
    float legL=sdRoundBox(p,vec3(3.,30.,3.),1.,vec3(-25.,0.,20.));
    float frontSupport=sdRoundBox(p,vec3(25.,3.,3.),1.,vec3(0.,53.,20.));
    float backSupportR=sdRoundBox(p,vec3(3.,68.,3.),1.,vec3(25.,0.,-27.));
    float backSupportL=sdRoundBox(p,vec3(3.,68.,3.),1.,vec3(-25.,0.,-27.));
    float sideSupportTopR=sdRoundBox(p,vec3(3.,3.,21.),1.,vec3(25.,53.,0.));
    float sideSupportTopL=sdRoundBox(p,vec3(3.,3.,21.),1.,vec3(25.,53.,0.));
    float sideSupportMiddleR=sdRoundBox(p,vec3(3.,3.,21.),1.,vec3(25.,42.,0.));
    float sideSupportMiddleL=sdRoundBox(p,vec3(3.,3.,21.),1.,vec3(-25.,42.,0.));
    float backrest=sdRoundBox(p,vec3(32.,18.,3.),3.,vec3(0.,103.,-20.));
    
    float whiteBox=sdRoundBox(p,vec3(40.,80.,40.),1.,vec3(0.));
    
    float d=0.;
    d=min(legR,legL);
    d=min(d,seat);
    d=min(d,frontSupport);
    d=min(d,backSupportR);
    d=min(d,backSupportL);
    d=min(d,sideSupportTopR);
    d=min(d,sideSupportTopL);
    d=min(d,sideSupportMiddleR);
    d=min(d,sideSupportMiddleL);
    d=min(d,backrest);
    //d=min(d,whiteBox);
    return d;
}

float sdRoom(vec3 p){
    float floor=sdPlane(p,vec3(0.,1.,0.),0.);
    float ceiling=sdBox(p,vec3(300.,1.,500.),vec3(0.,400.,0.));
    float backWall=sdBox(p,vec3(300.,200.,1.),vec3(0.,0.,140.));
    float sideWindow=sdBox(p,vec3(2.,150.,200.),vec3(300.,0.,0.));
    float sideWallR=sdBox(p,vec3(1.,200.,500.),vec3(300.,0.,-100.));
    float sideWallL=sdBox(p,vec3(1.,200.,500.),vec3(-300.,0.,0.));
    float d=0.;
    d=min(floor,ceiling);
    d=min(d,backWall);
    d=min(d,max(sideWallR,-sideWindow));
    d=min(d,sideWallL);
    return d;
}

float map(vec3 p){
    
    float room=sdRoom(p);
    float chair=sdChair(p);
    float d=0.;
    d=min(chair,room);
    return d;
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

float calcAO(vec3 pos,vec3 nor)
{
    float occ=0.;
    float sca=1.;
    for(int i=0;i<5;i++)
    {
        float h=.01+.12*float(i)/4.;
        float d=map(pos+h*nor);
        occ+=(h-d)*sca;
        sca*=.95;
        if(occ>.35)break;
    }
    return clamp(1.-3.*occ,0.,1.)*(.5+.5*nor.y);
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow(vec3 ro,vec3 rd,float mint,float tmax)
{
    // bounding volume
    float tp=(.8-ro.y)/rd.y;
    if(tp>0.)tmax=min(tmax,tp);
    
    float res=1.;
    float t=mint;
    for(int i=0;i<MAX_MARCHING_STEPS;i++)
    {
        float h=map(ro+rd*t);
        float s=clamp(8.*h/t,0.,1.);
        res=min(res,s*s*(3.-2.*s));
        t+=clamp(h,.02,.2);
        if(res<.004||t>tmax)break;
    }
    return clamp(res,0.,1.);
}

vec3 screenComposition(vec3 bottom,vec3 top)
{
    return bottom+top-bottom*top/1.;
}

v

vec3 acesFilm(vec3 x)
{
    const float a=2.51;
    const float b=.03;
    const float c=2.43;
    const float d=.59;
    const float e=.14;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e),0.,1.);
}

vec3 render(vec3 ro,vec3 rd){
    vec3 col=vec3(0.);
    
    float d=rayMarch(ro,rd,MIN_DIST,MAX_DIST);
    
    if(d>MAX_DIST)return col;// ray didn't hit anything
    vec3 p=ro+rd*d;
    vec3 normal=calcNormal(p);
    
    vec3 lightPosition=vec3(2000.,2000.,0.);
    //vec3 lightDir=normalize(lightPosition-p);
    vec3 lightDir=vec3(.2,.11,-.029);
    vec3 albedo=vec3(.7,.6,.6);
    float diffuse=clamp(dot(normal,lightDir),.3,1.);
    float specular=pow(clamp(dot(reflect(lightDir,normal),rd),0.,1.),10.);
    float ao=calcAO(p,normal);
    float shadow=calcSoftshadow(p,lightDir,.25,5.);
    
    vec3 newRayOrigin=p+normal*PRECISION*2.;
    float shadowRayLength=rayMarch(newRayOrigin,lightDir,MIN_DIST,MAX_DIST);
    if(shadowRayLength<length(lightPosition-newRayOrigin))diffuse*=0.;// shadow
    
    col+=albedo*diffuse*shadow;
    col+=albedo*ao*SKY_COLOR;
    
    return col;
}

vec3 postprocess(vec3 col,vec2 uv)
{   
    vec3 noiseCol = noise(uv,.5);
    col=screenComposition(col,noiseCol);
    //col=acesFilm(col*.8);
    return col;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    vec3 col=vec3(0);
    
    vec2 uv=fragCoord/iResolution.xy;
    uv-=.5;
    uv.x*=iResolution.x/iResolution.y;
    
    vec3 camBasePos=vec3(-200.,160.,-817.);
    vec3 camMover=vec3(fbm(iTime*.3),fbm(iTime*.2+.5)*.3,0.);
    vec3 ro=camBasePos+camMover;

    vec3 camTarget=vec3(0.,100.,50.);
    mat3 camRotMatrix=rotationMatrix(vec3(-5.,0.,0.));
    
    vec3 camUp=normalize(camRotMatrix*vec3(0.,1.,0.));
    vec3 camForward=normalize(camBasePos-camTarget);
    vec3 camRight=normalize(cross(camForward,camUp));
    float fov=145.;
    
    vec3 rd=normalize(camRight*uv.x+camUp*uv.y+camForward/tan(radians(fov)));
    vec3 p=ro;
    float d=rayMarch(p,rd,MIN_DIST,MAX_DIST);
    if(uv.x>.3||uv.x<-.3||uv.y>.3||uv.y<-.3)
    {
        col=vec3(0.);
    }
    else
    {
        col=render(ro,rd);
        col=postprocess(col,uv);
    }
    
    fragColor=vec4(col,1.);
}