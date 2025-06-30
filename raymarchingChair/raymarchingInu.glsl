#define PI     3.14159265

//頭のサイズを定数として定義
const float head_size=0.9;
const vec3 blackParts_color=vec3(.9,.8,.5);
const vec3 head_color=vec3(.3,.2,.2);

const vec3 sunColor=vec3(.8,.7,.4);


/// 回転行列の生成----------------------
//https://wgld.org/d/glsl/g017.html
vec3 rotate(vec3 p, float angle, vec3 axis)
{
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

//マウス座標からクオータニオン取得----------------------------------
//取得したマウス座標をもとに回転軸ベクトルと回転角を割り出しクォータニオンを生成。
//https://wgld.org/d/webgl/w033.html

vec3 getRotatePosFromMouse(vec2 pos,vec3 rayPos){


    float canvasW = iResolution.x;
    float canvasH = iResolution.y;
    float wh = 1.0 / sqrt(canvasW * canvasW + canvasH * canvasH);
    
    //float x = e.clientX - c.offsetLeft - cw * 0.5;
    //float y = e.clientY - c.offsetTop - ch * 0.5;
    //canvas の中心点からマウスポインタまでの相対的な位置を調べる
    vec2 mouse_pos=(iMouse.xy*2.-iResolution.xy)/min(iResolution.x,iResolution.y);
    
    //軸ベクトルと回転角を算出
    float sq = sqrt(mouse_pos.x * mouse_pos.x + mouse_pos.y * mouse_pos.y);
    float angle = sq * 2.0 * PI;
    if(angle <-90.0){
        angle = -90.0;
    }
    if(angle >90.0){
        angle = 90.0;
    }
    if(sq != 1.0 && sq > 0.0001){
        sq = 1.0 / sq;
        mouse_pos.x *= sq;
        mouse_pos.y *= sq;
        }
    vec3 rotatePos = rotate(rayPos, -angle, vec3(-mouse_pos.y,mouse_pos.x, 0.0));
    //vec3 rotatePos = vec3(rayPos.x,rayPos.y,rayPos.z);
    return rotatePos;
    
}

/// 基本の距離関数----------------------

// 楕円体の距離関数
// 鼻パーツに使用
//https://qiita.com/muripo_life/items/9d8043ea24295c310f73
float ellipsoidDistance(vec3 p,vec3 r)
{
    return(sqrt(p.x/r.x*p.x/r.x+p.y/r.y*p.y/r.y+p.z/r.z*p.z/r.z)-1.)*min(min(r.x,r.y),r.z);
}

//トーラスの距離関数
//https://qiita.com/muripo_life/items/1736da4175028e3fb2b7
//https://kaiware007.hatenablog.jp/entry/2020/12/03/233714

float sdTorus(vec3 p,float largeRadius,float smallRadius)
{
    vec2 t = vec2(largeRadius,smallRadius);
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

/// オブジェクト同士を補間して結合する関数----------------------
//https://wgld.org/d/glsl/g016.html
float smoothMin(float distance1, float distance2, float intensity){
    float h = exp(-intensity * distance1) + exp(-intensity * distance2);
    return -log(h) / intensity;
}

///各パーツの距離関数作成-------------------------------------
// オブジェクトの中心を原点とした時の引数の位置と球の距離を返す
 //現在のレイ地点からの顔までの距離を取得

// 顔パーツの距離関数
float headDistance(vec3 rayPos)
{
    ///ベースの頭作成---------
    float head_distance = length(rayPos+vec3(0.))-head_size;
    
    
    ///眉間しわ作成---------
    
    //頭のサイズに合わせて眉間しわ調整
    vec3 shiwa_l_pos = vec3(head_size*0.13, head_size*-0.45,-head_size*0.73);
    vec3 shiwa_r_pos = vec3(head_size*-0.15, head_size*-0.47,-head_size*0.72);
    
    //眉間しわの位置を回転調整
    vec3 shiwa_l_rotatePos = rotate(rayPos+shiwa_l_pos, radians(-85.0), vec3(0,1,1)); 
    vec3 shiwa_r_rotatePos = rotate(rayPos+shiwa_r_pos, radians(85.0), vec3(0,1,1)); 
    
    //眉間しわをトーラスで作成
    float shiwa_l_torus =  sdTorus(shiwa_l_rotatePos,  head_size*0.15, head_size*0.06);
    float shiwa_r_torus =  sdTorus(shiwa_r_rotatePos,  head_size*0.14, head_size*0.06);
    
    float shiwa_torus = smoothMin(shiwa_l_torus,shiwa_r_torus,300.0);
    
    ///鼻タブ作成---------
    
    //頭のサイズに合わせて鼻タブサイズ調整
    float hanatabu_size=head_size*.2;

    //頭のサイズに合わせて鼻タブ位置調整
    vec3 hanatabu_l_pos=vec3(head_size*.15,0.0,-head_size*0.95);
    vec3 hanatabu_r_pos=vec3(-hanatabu_l_pos.x,-hanatabu_l_pos.y,hanatabu_l_pos.z);

    //現在のレイ地点からの鼻タブまでの距離を取得
    float hanatabu_l_sphere=length(rayPos+hanatabu_l_pos)-hanatabu_size;
    float hanatabu_r_sphere=length(rayPos+hanatabu_r_pos)-hanatabu_size;

    //左右の鼻タブをなめらかに補間和集合
    float hanatabu = smoothMin(hanatabu_l_sphere,hanatabu_r_sphere,130.0);

    ///唇作成---------

    //頭のサイズに合わせて唇の位置調整
    vec3 kutibiru_pos = vec3(0.0, head_size*0.15,-head_size*0.95);
    //唇の位置をx軸を基準に90度回転
    vec3 kutibiru_rotatePos = rotate(rayPos+kutibiru_pos, radians(90.0), vec3(1,0,0)); 
    //唇をトーラスで作成
    float kutibiru_torus =  sdTorus(kutibiru_rotatePos, head_size*0.1, head_size*0.07);
    
    //口の穴作成---------
    //唇に合わせて二重顎の位置調整
    vec3 ana_pos = vec3(kutibiru_pos.x, kutibiru_pos.y, kutibiru_pos.z+0.1);
    float ana_sphere=length(rayPos+ana_pos)-0.1;

    
    ///二重顎作成---------

    //唇に合わせて二重顎の位置調整
    vec3 ago_pos = vec3(kutibiru_pos.x, kutibiru_pos.y + 0.07, kutibiru_pos.z+0.05);
    //唇の位置をx軸を基準に90度回転
    vec3 ago_rotatePos = rotate(rayPos+ago_pos, radians(90.0), vec3(1,0,0));
    //二十顎をトーラスで作成
    float ago_torus =  sdTorus(ago_rotatePos, head_size*0.15, head_size*0.05);

    //パーツを合体----------
    
    float base = smoothMin(head_distance,shiwa_torus,100.0);
    base = smoothMin(base,smoothMin(kutibiru_torus,ago_torus,130.0),100.0);
    base = min(hanatabu,base);
    //口に穴をあける
    //base = min(base,ana_sphere);
    base = max(base,-ana_sphere);
    return base;

}

//目のパーツの距離関数
float eyeDistance(vec3 rayPos)
{
    //頭のサイズに合わせて目のサイズ調整
    float eye_size=head_size*.1;

    //頭のサイズに合わせて目の位置調整
    vec3 eye_l_pos=vec3(head_size*.3,head_size*-.3,-head_size*0.9);
    vec3 eye_r_pos=vec3(head_size*-.3,head_size*-.3,-head_size*0.9);

    //現在のレイ地点からの目までの距離を取得
    float eye_l_sphere=length(rayPos+eye_l_pos)-eye_size;
    float eye_r_sphere=length(rayPos+eye_r_pos)-eye_size;

    return min(eye_l_sphere,eye_r_sphere);
}

//鼻パーツの距離関数
float noseDistance(vec3 rayPos)
{
    //頭のサイズに合わせて鼻のサイズ調整
    vec3 nose_size=vec3(head_size*.12,head_size*.05,head_size*.08);

    //頭のサイズに合わせて鼻の位置調整
    vec3 nose_pos=vec3(0.,head_size*-.18,-head_size*0.95);

    //現在のレイ地点からの鼻までの距離を取得
    float nose_ellipsoid=ellipsoidDistance(rayPos+nose_pos,nose_size);
    return nose_ellipsoid;
}

//頭目鼻の距離関数を合体させる
float getAllDistance(vec3 rayPos)
{
    //頭と目と鼻の距離関数を和集合する
    float allDistance = min(headDistance(rayPos),min(eyeDistance(rayPos),noseDistance(rayPos)));
    return allDistance;
}

//頭目鼻の距離関数を使用してカラーを変更する
vec3 getAllColor(vec3 rayPos)
{
    float blackParts_distance=min(eyeDistance(rayPos),noseDistance(rayPos));
    //複数のオブジェクトを描く場合には、戻り値として距離関数の結果が小さい（0に近い）ほうを採用する
    vec3 color=headDistance(rayPos) < blackParts_distance ? blackParts_color:head_color;
    return color;
}

///法線処理-------------------------------------

// 法線ベクトル取得関数
// レイがぶつかった位置を偏微分をして球の法線ベクトルを計算
vec3 getNormal(vec3 rayPos)
{
    float delta=.0001;
    return normalize(vec3(
            getAllDistance(rayPos)-getAllDistance(vec3(rayPos.x-delta,rayPos.y,rayPos.z)),
            getAllDistance(rayPos)-getAllDistance(vec3(rayPos.x,rayPos.y-delta,rayPos.z)),
            getAllDistance(rayPos)-getAllDistance(vec3(rayPos.x,rayPos.y,rayPos.z-delta))
        ));
}
///背景-------------------------------------

//後光作成関数
vec3 createGokou(float distance)
{
    //頭のサイズに合わせて後光を作成

    float outline=1.-distance;
    float ring=abs(.01/(distance-head_size));
    vec3 gokou=sunColor*outline+ring;
    return gokou;
}

//後光マスク作成関数
vec3 createGokouMask(float distance)
{
    vec3 white=(1.-distance)*vec3(1.,1.,1.);
    vec3 black=distance*vec3(0.,0.,0.);
    vec3 mask=white+black;
    return mask;
}

// エントリポイント-------------------------------------
void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    ///原点の定義 ---------------------------------
    // 原点が中心となる二次元座標を生成する
    // 描画位置がpxで返ってくるので-1.0 ~ +1.0に正規化
    vec2 pos=(fragCoord.xy*2.-iResolution.xy)/min(iResolution.x,iResolution.y);

    ///原点からの距離を定義---------------------------------
    float distance_from_origin=length(pos);

    ///カラーの定義--------------------------------
    vec3 col= createGokou(distance_from_origin);

    ///ライトの定義---------------------------------

    // ライトの方向と色を決定
    vec3 lightDir=normalize(vec3(.6,0.9,.9));
    vec3 lightCol=vec3(1.,1.,1.);

    ///カメラの定義---------------------------------

    // カメラの位置
    vec3 cameraPos=vec3(0.,0.,300.);
    // カメラの向き
    vec3 cameraDir=vec3(0.,0.,-1.);
    // カメラの天面の向き
    vec3 cameraUP=vec3(0.,1.,0.);
    // カメラの進行方向と天面方向から横方向を計算
    vec3 cameraSide=cross(cameraDir,cameraUP);
    // フォーカスする深度
    float targetDepth=1.;

    ///レイの定義---------------------------------

    // カメラパラメータから三次元のレイの情報を生成する
    vec3 ray=normalize(cameraSide*pos.x+cameraUP*pos.y+cameraDir*targetDepth);

    // レイの方向(カメラから描画位置へのベクトル)を決定
    vec3 rayDir=ray;

    // 現在のレイの先端座標
    vec3 rayPos=cameraPos;

    // レイが進んだ総距離
    float rayLen=0.;

    // 距離関数の戻り値を格納するための変数
    float dist=0.;

    ///レイマーチンググループ---------------------------------

    // 今回はレイを進める回数が最大256回
    const float MAX_DIST = 100.0;
    for(int i=0;i<256;i++)
    {
        // レイの先端と球の距離を計測
        vec3 rotatePos  = vec3(getRotatePosFromMouse(pos,rayPos));
        //vec3 rotatePos = rotate(rayPos, radians(-15.0), vec3(1,1,-0.5)); 
        float distance=getAllDistance(rotatePos);

        
        // 距離が限りなく0に近い＝レイと球が衝突している
        if(distance<.00001)
        {     
            ///ハーフランバート拡散
            vec3 normal=getNormal(rotatePos);
            float diff=dot(normal,lightDir);
            float harfDiff = (diff * 0.5 + 0.5)*(diff * 0.5 + 0.5);
            
            vec3 diffuseReflection =vec3(harfDiff)*getAllColor(rotatePos)* lightCol;
            
            // 環境
            // https://megumisoft.hatenablog.com/entry/2015/10/09/224207
	        vec3 ambientColor = sunColor*0.4;    
            col = diffuseReflection +  ambientColor;
            

            break;
        }

        // Check if ray has traveled too far
        rayLen += distance;
        if(rayLen > MAX_DIST) {
            break;
        }

        rayPos+=rayDir*distance;

    }

    fragColor=vec4(col,1.0);

}