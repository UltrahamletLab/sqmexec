// 自動生成: dr_sbcl/interface/glsl.lisp — wood2.lisp から。手で編集しない。
export default {
  name: "wood2",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 1.0 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.75 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.4 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.1 },
    { name: "ringscale", uniform: "u_ringscale", type: "float", default: 15.0 },
    { name: "txtscale", uniform: "u_txtscale", type: "float", default: 1.0 },
    { name: "lightwood", uniform: "u_lightwood", type: "color", default: [0.69, 0.44, 0.25] },
    { name: "darkwood", uniform: "u_darkwood", type: "color", default: [0.35, 0.22, 0.08] },
    { name: "grainy", uniform: "u_grainy", type: "float", default: 1.0 },
    { name: "mapping", uniform: "u_mapping", type: "float", default: 1.0 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_roughness;
uniform float u_ringscale;
uniform float u_txtscale;
uniform vec3 u_lightwood;
uniform vec3 u_darkwood;
uniform float u_grainy;
uniform float u_mapping;
void sl_surface()
{
{
Color CT;
Float MIXV;
Float R2;
Float RR;
Float MYT;
Point PQ;
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

PP[0] = sgv_.Po[0];
PP[1] = sgv_.Po[1];
PP[2] = sgv_.Po[2];
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     0.0;
PQ[0] = t_POINT0[0];
PQ[1] = t_POINT0[1];
PQ[2] = t_POINT0[2];
}
{

MYT =     0.0;
}
{

RR =     0.0;
}
{

R2 =     0.0;
}
{

MIXV =     0.0;
}
{

CT[0] = u_lightwood[0];
CT[1] = u_lightwood[1];
CT[2] = u_lightwood[2];
}
{

if ((true && (u_mapping <     0.5))) {
{
Point t_POINT0;

t_POINT0[0] = sgv_.s;
t_POINT0[1] = sgv_.t;
t_POINT0[2] =     0.0;
PP[0] = t_POINT0[0];
PP[1] = t_POINT0[1];
PP[2] = t_POINT0[2];
}
}
}
{

if ((true && (u_mapping >     1.5))) {
{

PP[0] = sgv_.Pg[0];
PP[1] = sgv_.Pg[1];
PP[2] = sgv_.Pg[2];
}
}
}
{
Point t_POINT0;

t_POINT0[0] = PP[0] * u_txtscale;
t_POINT0[1] = PP[1] * u_txtscale;
t_POINT0[2] = PP[2] * u_txtscale;
PP[0] = t_POINT0[0];
PP[1] = t_POINT0[1];
PP[2] = t_POINT0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 = _SQ_zcomp (PP);
t_FLOAT1 = stf_max (u_ringscale,  0.0001);
t_FLOAT2 = t_FLOAT0 / t_FLOAT1;
MYT = t_FLOAT2;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Point t_POINT0;

t_FLOAT0 = _SQ_xcomp (PP);
t_FLOAT1 = t_FLOAT0 *     8.0;
t_FLOAT2 = _SQ_ycomp (PP);
t_FLOAT3 = t_FLOAT2 *     8.0;
t_FLOAT4 = _SQ_zcomp (PP);
t_POINT0[0] = t_FLOAT1;
t_POINT0[1] = t_FLOAT3;
t_POINT0[2] = t_FLOAT4;
PQ[0] = t_POINT0[0];
PQ[1] = t_POINT0[1];
PQ[2] = t_POINT0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 = stf_fnoisep (PQ);
t_FLOAT1 = t_FLOAT0 /    16.0;
t_FLOAT2 = MYT + t_FLOAT1;
MYT = t_FLOAT2;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Point t_POINT0;

t_FLOAT0 = _SQ_xcomp (PP);
t_FLOAT1 = _SQ_ycomp (PP);
t_FLOAT2 = t_FLOAT1 +   12.93;
t_POINT0[0] = t_FLOAT0;
t_POINT0[1] = MYT;
t_POINT0[2] = t_FLOAT2;
PQ[0] = t_POINT0[0];
PQ[1] = t_POINT0[1];
PQ[2] = t_POINT0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = stf_fnoisep (PQ);
t_FLOAT1 = u_ringscale * t_FLOAT0;
RR = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = floor (RR);
t_FLOAT1 = RR - t_FLOAT0;
RR = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;

t_FLOAT0 = _SQ_smoothstep (    0.2,    0.55, RR);
t_FLOAT1 = _SQ_smoothstep (   0.75,     0.8, RR);
t_FLOAT2 =     1.0 - t_FLOAT1;
t_FLOAT3 =     0.8 * t_FLOAT0 * t_FLOAT2;
t_FLOAT4 =     0.2 + t_FLOAT3;
RR = t_FLOAT4;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Float t_FLOAT6;
Float t_FLOAT7;
Float t_FLOAT8;
Point t_POINT0;

t_FLOAT0 = _SQ_xcomp (PP);
t_FLOAT1 = t_FLOAT0 *   128.0;
t_FLOAT2 = t_FLOAT1 +     5.0;
t_FLOAT3 = _SQ_zcomp (PP);
t_FLOAT4 = t_FLOAT3 *     8.0;
t_FLOAT5 = t_FLOAT4 -     3.0;
t_FLOAT6 = _SQ_ycomp (PP);
t_FLOAT7 = t_FLOAT6 *   128.0;
t_FLOAT8 = t_FLOAT7 +     1.0;
t_POINT0[0] = t_FLOAT2;
t_POINT0[1] = t_FLOAT5;
t_POINT0[2] = t_FLOAT8;
PQ[0] = t_POINT0[0];
PQ[1] = t_POINT0[1];
PQ[2] = t_POINT0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;

t_FLOAT0 = stf_fnoisep (PQ);
t_FLOAT1 =     1.3 - t_FLOAT0;
t_FLOAT2 = u_grainy * t_FLOAT1;
t_FLOAT3 =     1.0 - u_grainy;
t_FLOAT4 = t_FLOAT2 + t_FLOAT3;
R2 = t_FLOAT4;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = RR * R2 * R2;
t_FLOAT1 = _SQ_clamp (t_FLOAT0,     0.0,     1.0);
MIXV = t_FLOAT1;
}
{
Color t_COLOR0;

stf_mix (t_COLOR0, u_lightwood, u_darkwood, MIXV);
CT[0] = t_COLOR0[0];
CT[1] = t_COLOR0[1];
CT[2] = t_COLOR0[2];
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
t_COLOR5[0] = CT[0] * t_COLOR4[0];
t_COLOR5[1] = CT[1] * t_COLOR4[1];
t_COLOR5[2] = CT[2] * t_COLOR4[2];
stf_specular (t_COLOR6, NF, VDIR, u_roughness);
t_COLOR7[0] = u_ks * t_COLOR6[0];
t_COLOR7[1] = u_ks * t_COLOR6[1];
t_COLOR7[2] = u_ks * t_COLOR6[2];
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
