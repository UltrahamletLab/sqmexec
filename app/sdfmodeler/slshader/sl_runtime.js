// sl_runtime.js — dr_sbcl の GLSL バックエンド (interface/glsl.lisp) が出した
// <name>.sl.js を Three.js の ShaderMaterial にするランタイム。
//
// 前置き GLSL は sqm 側の実装 (dist/shade_dr.cpp の w_* / sqm_*、dist/noise.cpp)
// を1対1で写したもの。**sqm と式を揃える**のが目的なので、Three.js 流の照明
// (物理単位・距離減衰・sRGB 変換) は一切使わない:
//   - 点光源は距離減衰なし (light_dir: Cl = col × intensity)
//   - diffuse() は全灯の和を 1 でクランプ (sqm_diffuse)
//   - specular() は Blinn-Phong、sharpness = 1/roughness (sqm_specular)
//   - ambient() は 0.15 固定 (-O / -g なしの sqm_ambient)
//   - Ci は [0,1] にクランプして**そのまま**出す (sqm は -T 無しならリニア値を PNG に書く)
// Oi < 1 の透過は未対応 (不透明として描く)。occlusion は無い。environment() は trace() と
// 同じ共有の環境キューブマップを引く (マップ名は無視)。
//
// ── sqm の既定に**足す**もの (どれも既定オフ = 見比べの絵は変わらない) ──
//   - trace(): レイは飛ばさず、setSLEnv() で渡した環境キューブマップを引く縮退版
//   - 影: setSLShadow() で最大 2 灯にシャドウマップを付ける (diffuse/specular/lightsel
//         が可視度を掛ける = sqm の -s と同じ場所)
//   - setSLOutput({ hdr: true }) で Ci のクランプを外す (後段でトーンマップする用)、
//     diffuseClamp で diffuse() の上限 1 を緩める
// ライト・環境・影・出力設定は全マテリアルで**共有**する uniform (slShared)。

import * as THREE from 'three';

export const MAX_LIGHTS = 8;

const PRELUDE = /* glsl */ `
#define Float float
#define Point vec3
#define Color vec3
#define SLS_shader 1
#define SLS_world 0
#define SLS_camera 0
#define SLS_object 0
#define SLS_current 0

struct SLGlobals {
  vec3 Cs; vec3 Os; vec3 P; vec3 Pg; vec3 Po; vec3 dPdu; vec3 dPdv; vec3 N; vec3 Ng;
  float u; float v; float s; float t; vec3 L; vec3 Cl; vec3 I; vec3 Ci; vec3 Oi; vec3 E;
  float pi; float ncomps; float alpha; float dispOut;
};
SLGlobals sgv_;

uniform int  sl_nLights;
uniform vec3 sl_lightPos[${MAX_LIGHTS}];
uniform vec3 sl_lightCol[${MAX_LIGHTS}];   // col × intensity
uniform vec3 sl_ambient;                   // sqm_ambient の定数 (0.15)
uniform float sl_diffClamp;                // sqm_diffuse の上限 (1)
uniform bool sl_clampOut;                  // Ci を [0,1] に (sqm の -T 無し)
uniform bool sl_hasEnv;
uniform samplerCube sl_env;                // trace() が引く環境
uniform float sl_envGain;
uniform vec3 sl_envColor;                  // 環境が無いときの trace() の色
uniform int  sl_shLight0, sl_shLight1;     // 影を持つライトの番号 (-1 = なし)
uniform sampler2D sl_shMap0, sl_shMap1;    // 光源から見た深度
uniform mat4 sl_shMat0, sl_shMat1;         // world → 光源のクリップ座標
uniform float sl_shSoft0, sl_shSoft1;      // PCF の半径 (テクセル)
uniform float sl_shTexel;
uniform mat3 sl_ssR;                       // (shader-space ..) の回転・拡縮
uniform vec3 sl_ssO;                       //                   並進

// ── shader.lisp の *C-data-types* にある inline 関数 ─────────────────
float _SQ_xcomp(vec3 p){ return p.x; }
float _SQ_ycomp(vec3 p){ return p.y; }
float _SQ_zcomp(vec3 p){ return p.z; }
float _SQ_comp(vec3 c, float i){ return c[int(i)]; }
float _SQ_sqrt(float x){ return sqrt(max(x, 0.0)); }
float _SQ_log(float x){ return x > 0.0 ? log(x) : -1e10; }
float _SQ_mod(float x, float y){ return y != 0.0 ? x - y * trunc(x / y) : 0.0; } // C の fmod
float _SQ_abs(float x){ return abs(x); }
float _SQ_sign(float x){ return sign(x); }
float _SQ_clamp(float x, float lo, float hi){ return x < lo ? lo : (x > hi ? hi : x); }
float _SQ_ceiling(float x){ return ceil(x); }
float _SQ_step(float e, float x){ return x < e ? 0.0 : 1.0; }
float _SQ_smoothstep(float e0, float e1, float x){
  float t = clamp((x - e0) / (e1 - e0), 0.0, 1.0); return t * t * (3.0 - 2.0 * t); }
float _SQ_radians(float x){ return x * 3.14159265358979323846 / 180.0; }
float _SQ_degrees(float x){ return x * 180.0 / 3.14159265358979323846; }
float _SQ_dot(vec3 a, vec3 b){ return dot(a, b); }
float atan2(float y, float x){ return atan(y, x); }   // C の libm 名がそのまま出る (他の sin/pow 等は GLSL に同名がある)
float _SQ_length(vec3 v){ return length(v); }

// ── stf (shade_dr.cpp の w_* / sqm_*) ────────────────────────────────
float stf_min(float a, float b){ return a < b ? a : b; }
float stf_max(float a, float b){ return a > b ? a : b; }
void stf_makecolor(out vec3 c, float r, float g, float b){ c = vec3(r, g, b); }
void stf_normalize(out vec3 o, vec3 i){ float l = length(i); o = l < 1e-10 ? vec3(0,0,1) : i / l; }
void stf_faceforward(out vec3 o, vec3 N, vec3 I){ o = dot(N, I) > 0.0 ? -N : N; }
void stf_reflect(out vec3 o, vec3 I, vec3 N){ o = I - 2.0 * dot(I, N) * N; }
void stf_refract(out vec3 o, vec3 I, vec3 N, float eta){
  float c = -dot(I, N); float k = 1.0 - eta*eta*(1.0 - c*c);
  o = k < 0.0 ? vec3(0) : eta * I + (eta * c - sqrt(k)) * N; }
void stf_cross(out vec3 o, vec3 a, vec3 b){ o = cross(a, b); }
float stf_distance(vec3 a, vec3 b){ return length(a - b); }
void stf_mix(out vec3 o, vec3 a, vec3 b, float t){ o = a * (1.0 - t) + b * t; }
void stf_transform(out vec3 o, int space, vec3 p){ o = space == SLS_shader ? sl_ssR * p + sl_ssO : p; }
void stf_camera(out vec3 o, vec3 p){ o = p; }
void stf_world(out vec3 o, vec3 p){ o = p; }
void stf_object(out vec3 o, vec3 p){ o = p; }
float stf_depth(vec3 p){ return length(p); }
void stf_links(out vec3 o, vec3 a, vec3 b, vec3 c, vec3 d){ o = a; }

void stf_ambient(out vec3 c){ c = sl_ambient; }

/*@SL_HEAD@*/
// ── 影 (シャドウマップ + 回転ポアソン PCF) ───────────────────────────
const vec2 SL_POISSON[16] = vec2[16](
  vec2(-0.94201624,-0.39906216), vec2(0.94558609,-0.76890725), vec2(-0.09418410,-0.92938870),
  vec2(0.34495938,0.29387760),   vec2(-0.91588581,0.45771432), vec2(-0.81544232,-0.87912464),
  vec2(-0.38277543,0.27676845),  vec2(0.97484398,0.75648379),  vec2(0.44323325,-0.97511554),
  vec2(0.53742981,-0.47373420),  vec2(-0.26496911,-0.41893023),vec2(0.79197514,0.19090188),
  vec2(-0.24188840,0.99706507),  vec2(-0.81409955,0.91437590), vec2(0.19984126,0.78641367),
  vec2(0.14383161,-0.14100790));
float sl_pcf(sampler2D map, mat4 M, float soft){
  vec3 p = sgv_.P + sgv_.N * 0.006;                 // 法線方向へずらして自己影の縞を消す
  vec4 c = M * vec4(p, 1.0);
  vec3 n = c.xyz / c.w;
  if (any(greaterThan(abs(n), vec3(1.0)))) return 1.0;
  vec2 uv = n.xy * 0.5 + 0.5; float z = n.z * 0.5 + 0.5 - 0.0002;
  float a = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831853;
  mat2 R = mat2(cos(a), sin(a), -sin(a), cos(a));
  float vis = 0.0;
  for (int k = 0; k < 16; k++)
    vis += texture(map, uv + R * SL_POISSON[k] * soft * sl_shTexel).r < z ? 0.0 : 1.0;
  return vis / 16.0;
}
float sl_vis(int i){
  float v = 1.0;
  if (i == sl_shLight0) v = sl_pcf(sl_shMap0, sl_shMat0, sl_shSoft0);
  else if (i == sl_shLight1) v = sl_pcf(sl_shMap1, sl_shMat1, sl_shSoft1);
#ifdef SL_EXTRA_VIS
  v *= sl_extraVis(i);   // opts.head で定義する追加の可視度 (SDF のレイマーチ影など)
#endif
  return v;
}

void stf_trace(out vec3 c, vec3 P, vec3 dir, out float hit){
  if (sl_hasEnv) { c = texture(sl_env, dir).rgb * sl_envGain; hit = 1.0; }
  else           { c = sl_envColor; hit = 0.0; }
}
// environment(name, dir): マップ名 (GLSL では使わない int) は無視して共有の環境キューブマップを引く
void stf_environment(out vec3 c, int name, vec3 dir){
  c = sl_hasEnv ? texture(sl_env, dir).rgb * sl_envGain : sl_envColor;
}
void stf_diffuse(out vec3 o, vec3 N){
  o = vec3(0);
  for (int i = 0; i < ${MAX_LIGHTS}; i++) {
    if (i >= sl_nLights) break;
    vec3 L = sl_lightPos[i] - sgv_.P; float len = length(L);
    if (len < 1e-10) continue;
    L /= len;
    float d = dot(L, N);
    if (d <= 0.0) continue;
    o += d * sl_lightCol[i] * sl_vis(i);
  }
  o = min(o, vec3(sl_diffClamp));
}
void stf_specular(out vec3 o, vec3 N, vec3 V, float rough){
  o = vec3(0);
  float sharp = rough > 1e-6 ? 1.0 / rough : 100.0;
  for (int i = 0; i < ${MAX_LIGHTS}; i++) {
    if (i >= sl_nLights) break;
    vec3 L = sl_lightPos[i] - sgv_.P; float len = length(L);
    if (len < 1e-10) continue;
    L /= len;
    vec3 H = L + V; float hl = length(H);
    if (hl < 1e-10) continue;
    float nd = dot(N, H / hl);
    if (nd <= 0.0) continue;
    o += pow(nd, sharp) * sl_lightCol[i] * sl_vis(i);
  }
}
void stf_phong(out vec3 o, vec3 N, vec3 V, float sharpness){   // sqm_phong: 反射ベクトル R·V
  o = vec3(0);
  for (int i = 0; i < ${MAX_LIGHTS}; i++) {
    if (i >= sl_nLights) break;
    vec3 L = sl_lightPos[i] - sgv_.P; float len = length(L);
    if (len < 1e-10) continue;
    L /= len;
    float NdL = dot(L, N);
    if (NdL <= 0.0) continue;
    float RdV = dot(2.0 * NdL * N - L, V);
    if (RdV <= 0.0) continue;
    o += pow(RdV, sharpness) * sl_lightCol[i] * sl_vis(i);
  }
}
float stf_lightcount(){ return float(sl_nLights); }
float stf_lightsel(float j){
  int i = int(j);
  sgv_.Cl = vec3(0);
  if (i < 0 || i >= sl_nLights) return 0.0;
  vec3 L = sl_lightPos[i] - sgv_.P; float len = length(L);
  if (len < 1e-10) return 0.0;
  float vis = sl_vis(i);
  sgv_.L = L / len; sgv_.Cl = sl_lightCol[i] * vis;
  return vis;
}

// ── Perlin (shade_dr.cpp perlin3) ────────────────────────────────────
const int SL_PERM[256] = int[256](
  151,160,137, 91, 90, 15,131, 13,201, 95, 96, 53,194,233,  7,225,
  140, 36,103, 30, 69,142,  8, 99, 37,240, 21, 10, 23,190,  6,148,
  247,120,234, 75,  0, 26,197, 62, 94,252,219,203,117, 35, 11, 32,
   57,177, 33, 88,237,149, 56, 87,174, 20,125,136,171,168, 68,175,
   74,165, 71,134,139, 48, 27,166, 77,146,158,231, 83,111,229,122,
   60,211,133,230,220,105, 92, 41, 55, 46,245, 40,244,102,143, 54,
   65, 25, 63,161,  1,216, 80, 73,209, 76,132,187,208, 89, 18,169,
  200,196,135,130,116,188,159, 86,164,100,109,198,173,186,  3, 64,
   52,217,226,250,124,123,  5,202, 38,147,118,126,255, 82, 85,212,
  207,206, 59,227, 47, 16, 58, 17,182,189, 28, 42,223,183,170,213,
  119,248,152,  2, 44,154,163, 70,221,153,101,155,167, 43,172,  9,
  129, 22, 39,253, 19, 98,108,110, 79,113,224,232,178,185,112,104,
  218,246, 97,228,251, 34,242,193,238,210,144, 12,191,179,162,241,
   81, 51,145,235,249, 14,239,107, 49,192,214, 31,181,199,106,157,
  184, 84,204,176,115,121, 50, 45,127,  4,150,254,138,236,205, 93,
  222,114, 67, 29, 24, 72,243,141,128,195, 78, 66,215, 61,156,180);
int sl_np(int i){ return SL_PERM[i & 255]; }
float sl_fade(float t){ return t*t*t*(t*(t*6.0-15.0)+10.0); }
float sl_grad(int h, float x, float y, float z){
  int hh = h & 15;
  float u = hh < 8 ? x : y;
  float v = hh < 4 ? y : ((hh == 12 || hh == 14) ? x : z);
  return ((hh & 1) != 0 ? -u : u) + ((hh & 2) != 0 ? -v : v);
}
float sl_perlin3(float x, float y, float z){
  int X = int(floor(x)) & 255, Y = int(floor(y)) & 255, Z = int(floor(z)) & 255;
  x -= floor(x); y -= floor(y); z -= floor(z);
  float u = sl_fade(x), v = sl_fade(y), w = sl_fade(z);
  int A = sl_np(X)+Y, AA = sl_np(A)+Z, AB = sl_np(A+1)+Z;
  int B = sl_np(X+1)+Y, BA = sl_np(B)+Z, BB = sl_np(B+1)+Z;
  return mix(mix(mix(sl_grad(sl_np(AA),x,y,z),     sl_grad(sl_np(BA),x-1.0,y,z),     u),
                 mix(sl_grad(sl_np(AB),x,y-1.0,z), sl_grad(sl_np(BB),x-1.0,y-1.0,z), u), v),
             mix(mix(sl_grad(sl_np(AA+1),x,y,z-1.0),     sl_grad(sl_np(BA+1),x-1.0,y,z-1.0),     u),
                 mix(sl_grad(sl_np(AB+1),x,y-1.0,z-1.0), sl_grad(sl_np(BB+1),x-1.0,y-1.0,z-1.0), u), v), w);
}
float stf_fnoisef(float x){ return 0.5*(1.0+sl_perlin3(x,0.5,0.5)); }
void  stf_pnoisef(out vec3 o, float x){
  o = 0.5*(1.0+vec3(sl_perlin3(x,0.5,0.5), sl_perlin3(x+31.7,0.5,0.5), sl_perlin3(x+67.3,0.5,0.5))); }
void  stf_cnoisef(out vec3 o, float x){ stf_pnoisef(o, x); }
float stf_fnoisep(vec3 p){ return 0.5*(1.0+sl_perlin3(p.x,p.y,p.z)); }
void  stf_pnoisep(out vec3 o, vec3 p){
  o = 0.5*(1.0+vec3(sl_perlin3(p.x,p.y,p.z), sl_perlin3(p.x+17.3,p.y,p.z), sl_perlin3(p.x,p.y+31.7,p.z))); }
void  stf_cnoisep(out vec3 o, vec3 p){ stf_pnoisep(o, p); }
float stf_turbulence(vec3 p, float octaves){
  int n = octaves >= 1.0 ? int(octaves) : 5; n = clamp(n, 1, 12);
  float r = 0.0, f = 1.0, amp = 1.0;
  for (int i = 0; i < 12; i++) {
    if (i >= n) break;
    r += amp * abs(sl_perlin3(p.x*f, p.y*f, p.z*f));
    f *= 2.0; amp *= 0.5;
  }
  return r;
}

// ── 値格子ノイズ (dist/noise.cpp) ─────────────────────────────────────
float sl_ihash3(int x, int y, int z){
  uint n = uint(x)*374761393u + uint(y)*668265263u + uint(z)*1274126177u;
  n = (n ^ (n >> 13u)) * 1274126177u;
  return float((n ^ (n >> 16u)) & 0x7fffffffu) / 2147483647.0;
}
float sl_value3(vec3 p){
  ivec3 i = ivec3(floor(p)); vec3 f = p - vec3(i);
  vec3 u = f*f*f*(f*(f*6.0-15.0)+10.0);
  float c000=sl_ihash3(i.x,i.y,i.z),     c100=sl_ihash3(i.x+1,i.y,i.z);
  float c010=sl_ihash3(i.x,i.y+1,i.z),   c110=sl_ihash3(i.x+1,i.y+1,i.z);
  float c001=sl_ihash3(i.x,i.y,i.z+1),   c101=sl_ihash3(i.x+1,i.y,i.z+1);
  float c011=sl_ihash3(i.x,i.y+1,i.z+1), c111=sl_ihash3(i.x+1,i.y+1,i.z+1);
  float x00=c000+u.x*(c100-c000), x10=c010+u.x*(c110-c010);
  float x01=c001+u.x*(c101-c001), x11=c011+u.x*(c111-c011);
  float y0=x00+u.y*(x10-x00), y1=x01+u.y*(x11-x01);
  return y0+u.z*(y1-y0);
}
float stf_vnoise(vec3 p){ return sl_value3(p); }
float stf_vfbm(vec3 p, float octaves){
  int n = octaves >= 1.0 ? int(octaves) : 5; n = clamp(n, 1, 12);
  float a = 0.5, f = 1.0, s = 0.0, norm = 0.0; vec3 o = vec3(0);
  for (int i = 0; i < 12; i++) {
    if (i >= n) break;
    s += a * sl_value3(p*f + o); norm += a; f *= 2.02; a *= 0.5;
    o += vec3(37.13, 17.71, 91.37);
  }
  return norm > 0.0 ? s / norm : 0.0;
}
`;

const VERTEX = /* glsl */ `
out vec3 vPw;
out vec3 vNw;
out vec3 vPo;
void main() {
  vec4 pw = modelMatrix * vec4(position, 1.0);
  vPw = pw.xyz;
  vNw = normalize(mat3(modelMatrix) * normal);
  vPo = position;
  gl_Position = projectionMatrix * viewMatrix * pw;
}`;

// sl_shade(P, N, Po, I): 面の 1 点を sl_surface() で塗って出力色を返す。
// メッシュ用の main (FRAGMENT_MAIN) も、opts.main で差し替えたレイマーチ等の main もこれを呼ぶ。
const FRAGMENT_SHADE = /* glsl */ `
uniform vec3 sl_Cs;
uniform float sl_kt;
out vec4 slFragColor;
vec4 sl_shade(vec3 P, vec3 N, vec3 Po, vec3 I) {
  sgv_.P = P; sgv_.Po = Po;
#ifdef SL_PG_FROM_PO
  sgv_.Pg = Po;                                // 模様の座標を呼び出し側が決める (レイマーチの局所座標など)
#else
  sgv_.Pg = P;
#endif
  sgv_.N = N; sgv_.Ng = N;
  sgv_.I = I;                                  // sqm: I = 一次レイの方向 (単位)
  sgv_.E = cameraPosition;
  sgv_.s = atan(N.z, N.x) / (2.0 * 3.14159265358979) + 0.5;   // blob/SDF の球面 s,t
  sgv_.t = acos(clamp(N.y, -1.0, 1.0)) / 3.14159265358979;
  sgv_.u = 0.0; sgv_.v = 0.0;
  {  // setup_sgv: UV の無い面は N と最も平行でない軸から接線を作る
    vec3 a = abs(N), ax = a.x < a.y && a.x < a.z ? vec3(1,0,0) : (a.y < a.z ? vec3(0,1,0) : vec3(0,0,1));
    sgv_.dPdu = normalize(cross(ax, N)); sgv_.dPdv = cross(N, sgv_.dPdu);
  }
  sgv_.Cs = sl_Cs; sgv_.Os = vec3(1.0 - sl_kt);
  sgv_.Ci = vec3(0); sgv_.Oi = vec3(1);
  sgv_.L = vec3(0); sgv_.Cl = vec3(0);
  sgv_.pi = 3.14159265358979; sgv_.ncomps = 3.0;
  sl_surface();
  return vec4(sl_clampOut ? clamp(sgv_.Ci, 0.0, 1.0) : max(sgv_.Ci, 0.0), 1.0);
}`;

const FRAGMENT_MAIN = /* glsl */ `
in vec3 vPw;
in vec3 vNw;
in vec3 vPo;
void main() {
  slFragColor = sl_shade(vPw, normalize(vNw), vPo, normalize(vPw - cameraPosition));
}`;

/** 全マテリアルで共有する uniform (同じオブジェクトを各マテリアルに差す)。 */
export const slShared = {
  sl_ambient: { value: new THREE.Vector3(0.15, 0.15, 0.15) },
  sl_diffClamp: { value: 1 },
  sl_clampOut: { value: true },
  sl_hasEnv: { value: false },
  sl_env: { value: null },
  sl_envGain: { value: 1 },
  sl_envColor: { value: new THREE.Vector3(0.15, 0.15, 0.15) },
  sl_nLights: { value: 0 },
  sl_lightPos: { value: Array.from({ length: MAX_LIGHTS }, () => new THREE.Vector3()) },
  sl_lightCol: { value: Array.from({ length: MAX_LIGHTS }, () => new THREE.Vector3()) },
  sl_shLight0: { value: -1 }, sl_shLight1: { value: -1 },
  sl_shMap0: { value: null }, sl_shMap1: { value: null },
  sl_shMat0: { value: new THREE.Matrix4() }, sl_shMat1: { value: new THREE.Matrix4() },
  sl_shSoft0: { value: 1.5 }, sl_shSoft1: { value: 1.5 },
  sl_shTexel: { value: 1 / 2048 },
};

/**
 * 生成モジュールから ShaderMaterial を作る。
 * @param mod     import した <name>.sl.js の default
 * @param opts.params  { "<lisp param 名>": number | [r,g,b] } — 既定値を上書き
 * @param opts.color   シーンの (color ..) = Cs
 * @param opts.kt      シーンの (kt ..) — Os = 1-kt
 * @param opts.shaderSpace  THREE.Matrix4 — (shader-space ..) 相当 (transform "shader")
 * @param opts.lights  [{ pos, color, intensity }] — 指定すると共有ライトを置き換える
 * @param opts.head    前置きの影の節の直前に入れる GLSL。`#define SL_EXTRA_VIS` と
 *                     `float sl_extraVis(int i)` を書くと、全ライトの可視度にそれが掛かる
 *                     (sgv_.P / sgv_.N / sl_lightPos[i] が使える)
 * @param opts.main    フラグメントの main を差し替える GLSL (既定はメッシュの面を塗る)。
 *                     `sl_shade(P, N, Po, I)` を呼んで slFragColor に書く。頂点側は既定のまま
 *                     (vPw / vNw / vPo を出す) なので、in で受けて使える
 * @param opts.uniforms 追加の uniform ({ name: { value } }。共有したいなら同じオブジェクトを渡す)
 * @param opts.displace [{ mod, params, amp }] — :displacement の .sl.js (keyword "displacement")。
 *                     各 mod.glsl を前置きの SL_HEAD マーカー (opts.head が入る場所) の**前**に差し込むので、opts.head の
 *                     距離関数から `float <mod.fn>(vec3 P)` (= sl_disp_<name>。シェーダーの (setvar disp h)
 *                     の値そのまま) を呼べる。params は :surface と同じ上書き ({ "<lisp 名>": 値 })。
 *                     amp は number か { value } (複数マテリアルで共有するなら同じオブジェクト) で、
 *                     `uniform float <mod.fn>_amp` になる。head では sqm と同じ符号で
 *                       d -= <fn>_amp * <fn>(p);
 *                     と書く (h>0 で面が外へ出る)。レイマーチの歩幅は d / (1 + amp*L) に落とすこと
 *                     (L = |∇h| の上界。sqm の (lipschitz L) と同じ考え。例は metaball_disp.html)。
 *                     opts.displace 無しの出力は従来と 1 バイトも変わらない。
 *
 * ── dr_sbcl 側の出し方と制約 ──
 *   sbcl --script glsl-build.lisp <out-dir> <name> ..   (dr_sbcl/ で。interface/glsl.lisp が本体)
 *   :surface と :displacement だけ通る。:displacement は sgv->P だけ読める (sqm と同じ)。
 *   GLSL 版の P は**レイマーチが渡した座標そのまま** — sqm の (local) / (shader-space ..) /
 *   ノード局所座標に相当するものは無いので、必要なら呼ぶ側で p を変換してから渡す。
 *   uniform は u_<shader名>_<param名> (ceramictiles と ceramictilesdisp のように同名 param を持つ
 *   :surface と同居するため)。occlusion / shadow / texture を使うシェーダーは生成時に止まる。
 */
export function makeSLMaterial(mod, opts = {}) {
  if (mod.keyword === 'displacement')
    throw new Error(`makeSLMaterial(${mod.name}): :displacement は opts.displace に渡す (面を塗る :surface ではない)`);
  const ss = opts.shaderSpace || new THREE.Matrix4();
  const uniforms = {
    ...slShared,
    ...(opts.uniforms || {}),
    sl_Cs: { value: new THREE.Vector3(...(opts.color || [1, 1, 1])) },
    sl_kt: { value: opts.kt || 0 },
    sl_ssR: { value: new THREE.Matrix3().setFromMatrix4(ss) },
    sl_ssO: { value: new THREE.Vector3().setFromMatrixPosition(ss) },
  };
  if (opts.ambient !== undefined) setSLAmbient(opts.ambient);
  slParamUniforms(mod, opts.params || {}, uniforms);
  // 変位シェーダー: GLSL を head の前に積み、param と amp の uniform を足す
  let dispGlsl = '';
  for (const d of (opts.displace || [])) {
    const m = d.mod;
    if (!m || m.keyword !== 'displacement' || !m.fn)
      throw new Error(`makeSLMaterial(${mod.name}): displace の ${m && m.name} は :displacement の .sl.js ではない`);
    slParamUniforms(m, d.params || {}, uniforms);
    const ampU = `${m.fn}_amp`;
    uniforms[ampU] = (d.amp !== null && typeof d.amp === 'object') ? d.amp : { value: d.amp ?? 0 };
    dispGlsl += `${m.glsl}uniform float ${ampU};
`;
  }
  if (opts.lights) setSLLights(opts.lights);
  return new THREE.ShaderMaterial({
    name: `sl:${mod.name}`,
    glslVersion: THREE.GLSL3,
    uniforms,
    vertexShader: VERTEX,
    fragmentShader: PRELUDE.replace('/*@SL_HEAD@*/', dispGlsl + (opts.head || '')) + mod.glsl
                    + FRAGMENT_SHADE + (opts.main || FRAGMENT_MAIN),
  });
}

/** mod の param を uniforms に入れる (given で既定値を上書き)。:surface と :displacement 共用。 */
function slParamUniforms(mod, given, uniforms) {
  // 名前は lisp の param を小文字化したもので完全一致。外れたキーは黙って既定値になるので知らせる
  for (const k of Object.keys(given)) {
    if (!mod.params.some(p => p.name === k)) {
      const near = mod.params.find(p => p.name === k.toLowerCase());
      console.warn(`makeSLMaterial(${mod.name}): param "${k}" はシェーダーに無い — 無視する`
                   + (near ? ` ("${near.name}" のこと?)` : ''));
    }
  }
  for (const p of mod.params) {
    // 文字列 param (environment のマップ名など) は GLSL では int の空き uniform。値は使わない
    if (p.type === 'string') { uniforms[p.uniform] = { value: 0 }; continue; }
    const v = p.name in given ? given[p.name] : p.default;
    uniforms[p.uniform] = { value: p.type === 'float' ? v : new THREE.Vector3(...v) };
  }
}

export function setSLLights(lights) {
  if (lights.length > MAX_LIGHTS) throw new Error(`lights > ${MAX_LIGHTS}`);
  slShared.sl_nLights.value = lights.length;
  lights.forEach((l, i) => {
    slShared.sl_lightPos.value[i].set(...l.pos);
    const k = l.intensity ?? 1;
    slShared.sl_lightCol.value[i].set(l.color[0] * k, l.color[1] * k, l.color[2] * k);
  });
}

export function setSLAmbient(a) {
  slShared.sl_ambient.value.set(...(Array.isArray(a) ? a : [a, a, a]));
}

/** 出力設定: hdr = Ci のクランプを外す / diffuseClamp = diffuse() の上限。 */
export function setSLOutput({ hdr, diffuseClamp } = {}) {
  if (hdr !== undefined) slShared.sl_clampOut.value = !hdr;
  if (diffuseClamp !== undefined) slShared.sl_diffClamp.value = diffuseClamp;
}

/** trace() が引く環境 (WebGLCubeRenderTarget.texture など)。null で無効。 */
export function setSLEnv(cubeTexture, gain = 1) {
  slShared.sl_env.value = cubeTexture;
  slShared.sl_hasEnv.value = !!cubeTexture;
  slShared.sl_envGain.value = gain;
}

/**
 * ライト lightIndex にシャドウマップを付ける (slot 0/1)。
 * camera は光源位置に置いた PerspectiveCamera (lookAt 済み)。
 * 返り値の update(renderer, scene) を、物が動いたら呼ぶ (静止シーンなら1回)。
 * 影を落とさない物 (発光体・窓の外) は layers 1 だけに置けば深度パスに入らない。
 */
export function setSLShadow(slot, lightIndex, camera, { size = 2048, soft = 1.5 } = {}) {
  const rt = new THREE.WebGLRenderTarget(size, size);
  rt.depthTexture = new THREE.DepthTexture(size, size, THREE.FloatType);
  const depthMat = new THREE.MeshBasicMaterial({ colorWrite: false, side: THREE.DoubleSide });
  slShared[`sl_shLight${slot}`].value = lightIndex;
  slShared[`sl_shMap${slot}`].value = rt.depthTexture;
  slShared[`sl_shSoft${slot}`].value = soft;
  slShared.sl_shTexel.value = 1 / size;
  return {
    camera, target: rt,
    update(renderer, scene) {
      camera.updateMatrixWorld();
      slShared[`sl_shMat${slot}`].value.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
      const prevO = scene.overrideMaterial, prevT = renderer.getRenderTarget();
      scene.overrideMaterial = depthMat;
      renderer.setRenderTarget(rt);
      renderer.clear();
      renderer.render(scene, camera);
      renderer.setRenderTarget(prevT);
      scene.overrideMaterial = prevO;
    },
  };
}
