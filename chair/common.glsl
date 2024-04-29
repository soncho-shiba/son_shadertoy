// http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(vec2 co){
    return fract(sin(dot(co.xy,vec2(12.9898,78.233)))*43758.5453)*.5-.25;
}

vec3 noise(vec3 col,vec2 uv,float level){
    return vec3(rand(uv+1.)*level,rand(uv+2.)*level,rand(uv+3.)*level);
}

// https://gist.github.com/keijiro/3731297 Perlin Noise(fBm)を使ったカメラ揺れエフェクト
// https://mrl.cs.nyu.edu/~perlin/noise/
vec3 perlinNoise(){
    return vec3(0.);
}
