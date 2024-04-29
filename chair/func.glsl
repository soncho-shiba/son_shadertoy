
#define PI 3.14159265

// The Book of Shaders by Patricio Gonzalez Vivo&Jen Lowe
// https://thebookofshaders.com/10/
float ramdom1d(float x)
{
    return sin(2.*x)+sin(PI*x);
}
float random2d(vec2 st){
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453)*.5-.25;
}

vec3 noise(vec2 uv,float level){
    return vec3(random2d(uv+1.)*level,random2d(uv+2.)*level,random2d(uv+3.)*level);
}

// Fractal Brownian Motion(fbb)
// noiseをoctaveを変えて重ねる
//
// The Book of Shaders by Patricio Gonzalez Vivo&Jen Lowe
// https://thebookofshaders.com/13
// さつき先生  UHTK 03-ノイズ関数を利用する【理論的な知識をもってHoudiniを使う】
// https://www.youtube.com/watch?list=PLAsWwUHApt3MVF8ByjGNFTwZ2DYUG8NGG&time_continue=1289&v=tEevAPnxbI8&source_ve_path=MzY4NDIsMjg2NjY&feature=emb_logo
// Perlin Noise(fBm)を使ったカメラ揺れエフェクト
// https://gist.github.com/keijiro/3731297
float fbm(float x)
{
    float result=0.;
    
    // TODO: 手振れっぽいノイズになるように周波数/振幅/オクターブ調整をする
    float frequency=1.;
    float amplitude=1.;
    int octave=5;
    
    float y=ramdom1d(x*frequency);
    
    for(int i=0;i<octave;i++)
    {
        result+=amplitude*y;
        
        amplitude*=.5;
        y*2.;// octave jamp
    }
    return result;
}
