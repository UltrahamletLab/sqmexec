// 自動生成: dr_sbcl/interface/glsl.lisp — veinedmarble.lisp から。手で編集しない。
export default {
  name: "veinedmarble",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 0.5 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.8 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.4 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.075 },
    { name: "specularcolor", uniform: "u_specularcolor", type: "color", default: [1.0, 1.0, 1.0] },
    { name: "veinfreq", uniform: "u_veinfreq", type: "float", default: 1.0 },
    { name: "veinlevels", uniform: "u_veinlevels", type: "float", default: 2.0 },
    { name: "warpfreq", uniform: "u_warpfreq", type: "float", default: 1.0 },
    { name: "warping", uniform: "u_warping", type: "float", default: 0.5 },
    { name: "veincolor", uniform: "u_veincolor", type: "color", default: [0.6, 0.5, 0.1] },
    { name: "sharpness", uniform: "u_sharpness", type: "float", default: 8.0 },
    { name: "network", uniform: "u_network", type: "float", default: 0.0 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_roughness;
uniform vec3 u_specularcolor;
uniform float u_veinfreq;
uniform float u_veinlevels;
uniform float u_warpfreq;
uniform float u_warping;
uniform vec3 u_veincolor;
uniform float u_sharpness;
uniform float u_network;
void sl_surface()
{
{
Color MARBLE;
Float AMP;
Float FREQ;
Float LEV;
Float VEIN;
Float PHASE;
Float WARP;
Point PP;
Point VDIR;
Point NF;
{
Point t_POINT0;
Point t_POINT1;

stf_normalize (t_POINT0, sgv_.N);
stf_faceforward (t_POINT1, t_POINT0, sgv_.I);
NF[0] = t_POINT1[0];
NF[1] = t_POINT1[1];
NF[2] = t_POINT1[2];
}
{
Point t_POINT0;
Point t_POINT1;

t_POINT0[0] =  - sgv_.I[0];
t_POINT0[1] =  - sgv_.I[1];
t_POINT0[2] =  - sgv_.I[2];
stf_normalize (t_POINT1, t_POINT0);
VDIR[0] = t_POINT1[0];
VDIR[1] = t_POINT1[1];
VDIR[2] = t_POINT1[2];
}
{

PP[0] = sgv_.Pg[0];
PP[1] = sgv_.Pg[1];
PP[2] = sgv_.Pg[2];
}
{

WARP =     0.0;
}
{

PHASE =     0.0;
}
{

VEIN =     0.0;
}
{

LEV =     0.0;
}
{

FREQ =     1.0;
}
{

AMP =     1.0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     1.0,     1.0,     1.0);
MARBLE[0] = t_COLOR0[0];
MARBLE[1] = t_COLOR0[1];
MARBLE[2] = t_COLOR0[2];
}
{

if ((true && (u_network <     0.5))) {
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Point t_POINT0;

t_POINT0[0] = PP[0] * u_warpfreq;
t_POINT0[1] = PP[1] * u_warpfreq;
t_POINT0[2] = PP[2] * u_warpfreq;
t_FLOAT0 = stf_turbulence (t_POINT0,     5.0);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = u_warping * t_FLOAT2;
WARP = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;

t_FLOAT0 = _SQ_xcomp (PP);
t_FLOAT1 = _SQ_zcomp (PP);
t_FLOAT2 =    0.35 * t_FLOAT1;
t_FLOAT3 = t_FLOAT0 + t_FLOAT2;
t_FLOAT4 = u_veinfreq * t_FLOAT3;
t_FLOAT5 = t_FLOAT4 + WARP;
PHASE = t_FLOAT5;
}
{
for (;;) {

if (!((true && (LEV < u_veinlevels)))) break;
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Float t_FLOAT6;
Float t_FLOAT7;

t_FLOAT0 = PHASE * FREQ;
t_FLOAT1 = sin (t_FLOAT0);
t_FLOAT2 = _SQ_abs (t_FLOAT1);
t_FLOAT3 =     1.0 - t_FLOAT2;
t_FLOAT4 = _SQ_clamp (t_FLOAT3,     0.0,     1.0);
t_FLOAT5 = pow (t_FLOAT4, u_sharpness);
t_FLOAT6 = AMP * t_FLOAT5;
t_FLOAT7 = VEIN + t_FLOAT6;
VEIN = t_FLOAT7;
}
{
Float t_FLOAT0;

t_FLOAT0 = FREQ *     2.0;
FREQ = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = AMP *     0.5;
AMP = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = LEV +     1.0;
LEV = t_FLOAT0;
}
}
}
} else {
{

AMP =     0.5;
}
{

WARP =     0.0;
}
{

PHASE =     0.0;
}
{

FREQ =     0.0;
}
{

LEV =     0.0;
}
{
for (;;) {

if (!((true && (LEV <     6.0)))) break;
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;

t_FLOAT0 = stf_fnoisep (PP);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = AMP * t_FLOAT2;
t_FLOAT4 = WARP + t_FLOAT3;
WARP = t_FLOAT4;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Point t_POINT0;
Point t_POINT1;

t_POINT0[0] =    17.3;
t_POINT0[1] =     0.0;
t_POINT0[2] =     0.0;
t_POINT1[0] = PP[0] + t_POINT0[0];
t_POINT1[1] = PP[1] + t_POINT0[1];
t_POINT1[2] = PP[2] + t_POINT0[2];
t_FLOAT0 = stf_fnoisep (t_POINT1);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = AMP * t_FLOAT2;
t_FLOAT4 = PHASE + t_FLOAT3;
PHASE = t_FLOAT4;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Point t_POINT0;
Point t_POINT1;

t_POINT0[0] =     0.0;
t_POINT0[1] =    31.7;
t_POINT0[2] =     0.0;
t_POINT1[0] = PP[0] + t_POINT0[0];
t_POINT1[1] = PP[1] + t_POINT0[1];
t_POINT1[2] = PP[2] + t_POINT0[2];
t_FLOAT0 = stf_fnoisep (t_POINT1);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = AMP * t_FLOAT2;
t_FLOAT4 = FREQ + t_FLOAT3;
FREQ = t_FLOAT4;
}
{
Float t_FLOAT0;

t_FLOAT0 = AMP *     0.5;
AMP = t_FLOAT0;
}
{
Point t_POINT0;

t_POINT0[0] = PP[0] *     2.0;
t_POINT0[1] = PP[1] *     2.0;
t_POINT0[2] = PP[2] *     2.0;
PP[0] = t_POINT0[0];
PP[1] = t_POINT0[1];
PP[2] = t_POINT0[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = LEV +     1.0;
LEV = t_FLOAT0;
}
}
}
{
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;

t_POINT0[0] = WARP;
t_POINT0[1] = PHASE;
t_POINT0[2] = FREQ;
t_POINT1[0] = sgv_.Pg[0] + t_POINT0[0];
t_POINT1[1] = sgv_.Pg[1] + t_POINT0[1];
t_POINT1[2] = sgv_.Pg[2] + t_POINT0[2];
t_POINT2[0] = t_POINT1[0] * u_veinfreq;
t_POINT2[1] = t_POINT1[1] * u_veinfreq;
t_POINT2[2] = t_POINT1[2] * u_veinfreq;
PP[0] = t_POINT2[0];
PP[1] = t_POINT2[1];
PP[2] = t_POINT2[2];
}
{

FREQ =     1.0;
}
{

LEV =     0.0;
}
{

VEIN =     0.0;
}
{
for (;;) {

if (!((true && (LEV < u_veinlevels)))) break;
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Point t_POINT0;

t_POINT0[0] = PP[0] * FREQ;
t_POINT0[1] = PP[1] * FREQ;
t_POINT0[2] = PP[2] * FREQ;
t_FLOAT0 = stf_fnoisep (t_POINT0);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = _SQ_abs (t_FLOAT2);
WARP = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 =     1.0 - WARP;
t_FLOAT1 = _SQ_smoothstep (    0.8,     1.0, t_FLOAT0);
t_FLOAT2 = pow (t_FLOAT1, u_sharpness);
t_FLOAT3 = t_FLOAT2 / FREQ;
WARP = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 =     1.0 - VEIN;
t_FLOAT1 = t_FLOAT0 * WARP;
t_FLOAT2 = VEIN + t_FLOAT1;
VEIN = t_FLOAT2;
}
{
Float t_FLOAT0;

t_FLOAT0 = FREQ *     3.0;
FREQ = t_FLOAT0;
}
{
Point t_POINT0;

t_POINT0[0] = PP[0] *     3.0;
t_POINT0[1] = PP[1] *     3.0;
t_POINT0[2] = PP[2] *     3.0;
PP[0] = t_POINT0[0];
PP[1] = t_POINT0[1];
PP[2] = t_POINT0[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = LEV +     1.0;
LEV = t_FLOAT0;
}
}
}
}
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_clamp (VEIN,     0.0,     1.0);
VEIN = t_FLOAT0;
}
{
Color t_COLOR0;

stf_mix (t_COLOR0, sgv_.Cs, u_veincolor, VEIN);
MARBLE[0] = t_COLOR0[0];
MARBLE[1] = t_COLOR0[1];
MARBLE[2] = t_COLOR0[2];
}
{

sgv_.Oi[0] = sgv_.Os[0];
sgv_.Oi[1] = sgv_.Os[1];
sgv_.Oi[2] = sgv_.Os[2];
}
{
Color t_COLOR0;
Color t_COLOR1;
Color t_COLOR2;
Color t_COLOR3;
Color t_COLOR4;
Color t_COLOR5;
Color t_COLOR6;
Color t_COLOR7;
Color t_COLOR8;
Color t_COLOR9;

stf_ambient (t_COLOR0);
t_COLOR1[0] = u_ka * t_COLOR0[0];
t_COLOR1[1] = u_ka * t_COLOR0[1];
t_COLOR1[2] = u_ka * t_COLOR0[2];
stf_diffuse (t_COLOR2, NF);
t_COLOR3[0] = u_kd * t_COLOR2[0];
t_COLOR3[1] = u_kd * t_COLOR2[1];
t_COLOR3[2] = u_kd * t_COLOR2[2];
t_COLOR4[0] = t_COLOR1[0] + t_COLOR3[0];
t_COLOR4[1] = t_COLOR1[1] + t_COLOR3[1];
t_COLOR4[2] = t_COLOR1[2] + t_COLOR3[2];
t_COLOR5[0] = MARBLE[0] * t_COLOR4[0];
t_COLOR5[1] = MARBLE[1] * t_COLOR4[1];
t_COLOR5[2] = MARBLE[2] * t_COLOR4[2];
stf_specular (t_COLOR6, NF, VDIR, u_roughness);
t_COLOR7[0] = u_specularcolor[0] * u_ks * t_COLOR6[0];
t_COLOR7[1] = u_specularcolor[1] * u_ks * t_COLOR6[1];
t_COLOR7[2] = u_specularcolor[2] * u_ks * t_COLOR6[2];
t_COLOR8[0] = t_COLOR5[0] + t_COLOR7[0];
t_COLOR8[1] = t_COLOR5[1] + t_COLOR7[1];
t_COLOR8[2] = t_COLOR5[2] + t_COLOR7[2];
t_COLOR9[0] = sgv_.Oi[0] * t_COLOR8[0];
t_COLOR9[1] = sgv_.Oi[1] * t_COLOR8[1];
t_COLOR9[2] = sgv_.Oi[2] * t_COLOR8[2];
sgv_.Ci[0] = t_COLOR9[0];
sgv_.Ci[1] = t_COLOR9[1];
sgv_.Ci[2] = t_COLOR9[2];
}
}
}
`
};
