
// ---PostEffect---
// http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(vec2 co){
    return fract(sin(dot(co.xy,vec2(12.9898,78.233)))*43758.5453)*.5-.25;
}

vec3 noise(vec2 uv,float level){
    return vec3(rand(uv+1.)*level,rand(uv+2.)*level,rand(uv+3.)*level);
}

// https://mrl.cs.nyu.edu/~perlin/noise/
// https://gist.github.com/keijiro/3731297 Perlin Noise(fBm)を使ったカメラ揺れエフェクト
// vec3 perlinNoise(){
    //     return vec3(0.);
// }

// ---Camera Shake---
float rand(float p){
    return fract(sin(dot(p,12.9898))*43758.5453)*.5-.25;
}

// Fractal brown motion(fbb) fubnc
// noiseをoctaveを変えて重ねる
// --- Noise reference ---
// The Book of Shaders by Patricio Gonzalez Vivo&Jen Lowe
// https://thebookofshaders.com/13
//さつき先生  UHTK 03-ノイズ関数を利用する【理論的な知識をもってHoudiniを使う】 
// https://www.youtube.com/watch?list=PLAsWwUHApt3MVF8ByjGNFTwZ2DYUG8NGG&time_continue=1289&v=tEevAPnxbI8&source_ve_path=MzY4NDIsMjg2NjY&feature=emb_logo

float fbm(float p, float frequency, float amplitude, int octave)
{
    float result=0.;
    for(int i=0;i<octave;i++)
    {
        result+=amplitude*rand(p);
        amplitude*=.5;
        p*2.;
    }
    return result;
}
