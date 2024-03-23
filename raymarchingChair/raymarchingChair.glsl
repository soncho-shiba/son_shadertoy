const int MAX_MARCHING_STEPS=255;
const float MIN_DIST=0.;
const float MAX_DIST=100.;
const float PRECISION=.001;

// 箱型の距離関数
float box_d(vec3 p,float size){
    
    // 【Shadertoy】レイマーチング基礎② https://logicalbeat.jp/blog/8203/
    //  まずabs(pos)によって座標を絶対値に変換します、これは計算を第1象限だけに絞るためです。
    // 次にxとy要素それぞれで考え、どちらかの要素で正方形の範囲内だった場合(今回はyが範囲内と考える)、距離はx-正方形のサイズになります。
    // どちらの要素も範囲外だった場合は、頂点と点との距離になるのでlengthで計算できます。
    // これら二つの計算式を一つで表現できるのようにしたのがlength(max(q-size,0.))になります。
    vec3 q=abs(p)-size;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
    
}

float rayMarch(vec3 ro,vec3 rayDir,float start,float end){
    float depth=start;
    
    for(int i=0;i<MAX_MARCHING_STEPS;i++){
        vec3 p=ro+depth*rayDir;
        float d=box_d(p,1.);
        depth+=d;
        if(d<PRECISION||depth>end)break;
    }
    
    return depth;
}

vec3 calcNormal(vec3 p){
    vec2 e=vec2(1.,-1.)*.0005;// epsilon
    float r=1.;// radius of sphere
    return normalize(
        e.xyy*box_d(p+e.xyy,r)+
        e.yyx*box_d(p+e.yyx,r)+
        e.yxy*box_d(p+e.yxy,r)+
        e.xxx*box_d(p+e.xxx,r));
    }
    
    void mainImage(out vec4 fragColor,in vec2 fragCoord)
    {
        vec2 uv=(fragCoord-.5*iResolution.xy)/iResolution.y;
        vec3 backgroundColor=vec3(.85,.85,.85);
        
        vec3 col=vec3(0);
        
        // ray origin(=カメラの位置)
        vec3 rayOrigin=vec3(0.,0.,3.);
        // ray direction(rayOrigin から描画位置へのベクトル)
        vec3 rayDir = normalize(vec3(uv,0.));
        
        float d=rayMarch(rayOrigin,rayDir,MIN_DIST,MAX_DIST);// distance to sphere
        
        if(d>MAX_DIST){
            col=backgroundColor;// ray didn't hit anything
        }else{
            vec3 p=rayOrigin+rayDir*d;// point on sphere we discovered from ray marching
            vec3 normal=calcNormal(p);
            vec3 lightPosition=vec3(-1,6,3);
            vec3 lightDirection=normalize(lightPosition-p);
            
            // Calculate diffuse reflection by taking the dot product of
            // the normal and the light direction.
            float dif=clamp(dot(normal,lightDirection),.3,1.);
            
            // Multiply the diffuse reflection value by an orange color and add a bit
            // of the background color to the sphere to blend it more with the background.
            col=dif*vec3(1,.58,.29)+backgroundColor*.2;
        }
        
        // Output to screen
        fragColor=vec4(col,1.);
    }
    