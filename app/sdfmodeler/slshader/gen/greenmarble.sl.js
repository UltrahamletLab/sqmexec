// 自動生成: dr_sbcl/interface/glsl.lisp — greenmarble.lisp から。手で編集しない。
export default {
  name: "greenmarble",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 0.1 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.6 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.4 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.1 },
    { name: "specularcolor", uniform: "u_specularcolor", type: "color", default: [1.0, 1.0, 1.0] },
    { name: "darkcolor", uniform: "u_darkcolor", type: "color", default: [0.01, 0.12, 0.004] },
    { name: "lightcolor", uniform: "u_lightcolor", type: "color", default: [0.06, 0.18, 0.02] },
    { name: "veincolor", uniform: "u_veincolor", type: "color", default: [0.47, 0.57, 0.03] },
    { name: "veinfreq", uniform: "u_veinfreq", type: "float", default: 1.0 },
    { name: "sharpness", uniform: "u_sharpness", type: "float", default: 25.0 },
    { name: "txtscale", uniform: "u_txtscale", type: "float", default: 1.0 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_roughness;
uniform vec3 u_specularcolor;
uniform vec3 u_darkcolor;
uniform vec3 u_lightcolor;
uniform vec3 u_veincolor;
uniform float u_veinfreq;
uniform float u_sharpness;
uniform float u_txtscale;
void sl_surface()
{
{
Float GATE;
Float TSUM;
Float TB;
Float FRQ;
Color CT;
Float WZ;
Float WY;
Float WX;
Float J;
Float FACC;
Float FAMP;
Point Q;
Point PP;
Point IR;
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
IR[0] = t_POINT1[0];
IR[1] = t_POINT1[1];
IR[2] = t_POINT1[2];
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     0.0;
PP[0] = t_POINT0[0];
PP[1] = t_POINT0[1];
PP[2] = t_POINT0[2];
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     0.0;
Q[0] = t_POINT0[0];
Q[1] = t_POINT0[1];
Q[2] = t_POINT0[2];
}
{

FAMP =     0.0;
}
{

FACC =     0.0;
}
{

J =     0.0;
}
{

WX =     0.0;
}
{

WY =     0.0;
}
{

WZ =     0.0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
CT[0] = t_COLOR0[0];
CT[1] = t_COLOR0[1];
CT[2] = t_COLOR0[2];
}
{

FRQ =     0.0;
}
{

TB =     0.0;
}
{

TSUM =     0.0;
}
{

GATE =     0.0;
}
{
Point t_POINT0;
Point t_POINT1;

stf_transform (t_POINT0, SLS_shader, sgv_.Pg);
t_POINT1[0] = t_POINT0[0] * u_txtscale;
t_POINT1[1] = t_POINT0[1] * u_txtscale;
t_POINT1[2] = t_POINT0[2] * u_txtscale;
PP[0] = t_POINT1[0];
PP[1] = t_POINT1[1];
PP[2] = t_POINT1[2];
}
{

FAMP =     1.0;
}
{

FACC =     0.0;
}
{

Q[0] = PP[0];
Q[1] = PP[1];
Q[2] = PP[2];
}
{

J =     0.0;
}
{
for (;;) {

if (!((true && (J <     5.0)))) break;
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;

t_FLOAT0 = stf_fnoisep (Q);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = _SQ_abs (t_FLOAT2);
t_FLOAT4 = FAMP * t_FLOAT3;
t_FLOAT5 = FACC + t_FLOAT4;
FACC = t_FLOAT5;
}
{
Float t_FLOAT0;

t_FLOAT0 = FAMP *     0.5;
FAMP = t_FLOAT0;
}
{
Point t_POINT0;

t_POINT0[0] = Q[0] *     2.0;
t_POINT0[1] = Q[1] *     2.0;
t_POINT0[2] = Q[2] *     2.0;
Q[0] = t_POINT0[0];
Q[1] = t_POINT0[1];
Q[2] = t_POINT0[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = J +     1.0;
J = t_FLOAT0;
}
}
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Color t_COLOR0;

t_FLOAT0 =     0.5 * FACC;
t_FLOAT1 = _SQ_smoothstep (    0.1,    0.35, t_FLOAT0);
stf_mix (t_COLOR0, u_darkcolor, u_lightcolor, t_FLOAT1);
CT[0] = t_COLOR0[0];
CT[1] = t_COLOR0[1];
CT[2] = t_COLOR0[2];
}
{

FAMP =     0.5;
}
{

WX =     0.0;
}
{

WY =     0.0;
}
{

WZ =     0.0;
}
{

Q[0] = PP[0];
Q[1] = PP[1];
Q[2] = PP[2];
}
{

J =     0.0;
}
{
for (;;) {

if (!((true && (J <     6.0)))) break;
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;

t_FLOAT0 = stf_fnoisep (Q);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = FAMP * t_FLOAT2;
t_FLOAT4 = WX + t_FLOAT3;
WX = t_FLOAT4;
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
t_POINT1[0] = Q[0] + t_POINT0[0];
t_POINT1[1] = Q[1] + t_POINT0[1];
t_POINT1[2] = Q[2] + t_POINT0[2];
t_FLOAT0 = stf_fnoisep (t_POINT1);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = FAMP * t_FLOAT2;
t_FLOAT4 = WY + t_FLOAT3;
WY = t_FLOAT4;
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
t_POINT1[0] = Q[0] + t_POINT0[0];
t_POINT1[1] = Q[1] + t_POINT0[1];
t_POINT1[2] = Q[2] + t_POINT0[2];
t_FLOAT0 = stf_fnoisep (t_POINT1);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = FAMP * t_FLOAT2;
t_FLOAT4 = WZ + t_FLOAT3;
WZ = t_FLOAT4;
}
{
Float t_FLOAT0;

t_FLOAT0 = FAMP *     0.5;
FAMP = t_FLOAT0;
}
{
Point t_POINT0;

t_POINT0[0] = Q[0] *     2.0;
t_POINT0[1] = Q[1] *     2.0;
t_POINT0[2] = Q[2] *     2.0;
Q[0] = t_POINT0[0];
Q[1] = t_POINT0[1];
Q[2] = t_POINT0[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = J +     1.0;
J = t_FLOAT0;
}
}
}
{
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;
Point t_POINT3;

t_POINT0[0] =    35.2;
t_POINT0[1] =   -21.9;
t_POINT0[2] =    6.25;
t_POINT1[0] = WX;
t_POINT1[1] = WY;
t_POINT1[2] = WZ;
t_POINT2[0] = t_POINT0[0] + t_POINT1[0];
t_POINT2[1] = t_POINT0[1] + t_POINT1[1];
t_POINT2[2] = t_POINT0[2] + t_POINT1[2];
t_POINT3[0] = PP[0] + t_POINT2[0];
t_POINT3[1] = PP[1] + t_POINT2[1];
t_POINT3[2] = PP[2] + t_POINT2[2];
PP[0] = t_POINT3[0];
PP[1] = t_POINT3[1];
PP[2] = t_POINT3[2];
}
{
Point t_POINT0;

t_POINT0[0] = PP[0] * u_veinfreq;
t_POINT0[1] = PP[1] * u_veinfreq;
t_POINT0[2] = PP[2] * u_veinfreq;
PP[0] = t_POINT0[0];
PP[1] = t_POINT0[1];
PP[2] = t_POINT0[2];
}
{

TSUM =     0.0;
}
{

FRQ =     1.0;
}
{

J =     0.0;
}
{
for (;;) {

if (!((true && (J <     3.0)))) break;
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Point t_POINT0;

t_POINT0[0] = PP[0] * FRQ;
t_POINT0[1] = PP[1] * FRQ;
t_POINT0[2] = PP[2] * FRQ;
t_FLOAT0 = stf_fnoisep (t_POINT0);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = _SQ_abs (t_FLOAT2);
TB = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 =     1.0 - TB;
t_FLOAT1 = _SQ_smoothstep (    0.8,     1.0, t_FLOAT0);
t_FLOAT2 = pow (t_FLOAT1, u_sharpness);
t_FLOAT3 = t_FLOAT2 / FRQ;
TB = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 =     1.0 - TSUM;
t_FLOAT1 = t_FLOAT0 * TB;
t_FLOAT2 = TSUM + t_FLOAT1;
TSUM = t_FLOAT2;
}
{
Float t_FLOAT0;

t_FLOAT0 = FRQ *     2.0;
FRQ = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = J +     1.0;
J = t_FLOAT0;
}
}
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;

t_POINT0[0] =    -4.4;
t_POINT0[1] =    8.34;
t_POINT0[2] =    27.1;
t_POINT1[0] = PP[0] + t_POINT0[0];
t_POINT1[1] = PP[1] + t_POINT0[1];
t_POINT1[2] = PP[2] + t_POINT0[2];
t_POINT2[0] = t_POINT1[0] *     2.0;
t_POINT2[1] = t_POINT1[1] *     2.0;
t_POINT2[2] = t_POINT1[2] *     2.0;
t_FLOAT0 = stf_fnoisep (t_POINT2);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = _SQ_smoothstep (   -0.1,    0.05, t_FLOAT2);
GATE = t_FLOAT3;
}
{
Float t_FLOAT0;
Color t_COLOR0;

t_FLOAT0 = TSUM * GATE;
stf_mix (t_COLOR0, CT, u_veincolor, t_FLOAT0);
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
stf_specular (t_COLOR6, NF, IR, u_roughness);
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
