// 自動生成: dr_sbcl/interface/glsl.lisp — ceramic.lisp から。手で編集しない。
export default {
  name: "ceramic",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 1.0 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.5 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.5 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.1 },
    { name: "specsharpness", uniform: "u_specsharpness", type: "float", default: 0.5 },
    { name: "kr", uniform: "u_kr", type: "float", default: 0.0 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_roughness;
uniform float u_specsharpness;
uniform float u_kr;
void sl_surface()
{
{
Float HITF;
Color REFL;
Point RDIR;
Color SPEC;
Float NH;
Float G;
Float J;
Float NL;
Float EXPO;
Float W;
Point H;
Point VD;
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
VD[0] = t_POINT1[0];
VD[1] = t_POINT1[1];
VD[2] = t_POINT1[2];
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     1.0;
H[0] = t_POINT0[0];
H[1] = t_POINT0[1];
H[2] = t_POINT0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 =     1.0 - u_specsharpness;
t_FLOAT1 =    0.18 * t_FLOAT0;
W = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = stf_max (u_roughness,  0.0001);
t_FLOAT1 =    10.0 / t_FLOAT0;
EXPO = t_FLOAT1;
}
{

NL =     0.0;
}
{

J =     0.0;
}
{

G =     0.0;
}
{

NH =     0.0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
SPEC[0] = t_COLOR0[0];
SPEC[1] = t_COLOR0[1];
SPEC[2] = t_COLOR0[2];
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     1.0;
RDIR[0] = t_POINT0[0];
RDIR[1] = t_POINT0[1];
RDIR[2] = t_POINT0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
REFL[0] = t_COLOR0[0];
REFL[1] = t_COLOR0[1];
REFL[2] = t_COLOR0[2];
}
{

HITF =     0.0;
}
{
Float t_FLOAT0;

t_FLOAT0 = stf_lightcount ();
NL = t_FLOAT0;
}
{

J =     0.0;
}
{
for (;;) {

if (!((true && (J < NL)))) break;
{
Float t_FLOAT0;

t_FLOAT0 = stf_lightsel (J);
G = t_FLOAT0;
}
{
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;

stf_normalize (t_POINT0, sgv_.L);
t_POINT1[0] = t_POINT0[0] + VD[0];
t_POINT1[1] = t_POINT0[1] + VD[1];
t_POINT1[2] = t_POINT0[2] + VD[2];
stf_normalize (t_POINT2, t_POINT1);
H[0] = t_POINT2[0];
H[1] = t_POINT2[1];
H[2] = t_POINT2[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_dot (NF, H);
t_FLOAT1 = stf_max (t_FLOAT0,     0.0);
NH = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Color t_COLOR0;
Color t_COLOR1;

t_FLOAT0 =    0.72 - W;
t_FLOAT1 =    0.72 + W;
t_FLOAT2 = pow (NH, EXPO);
t_FLOAT3 = _SQ_smoothstep (t_FLOAT0, t_FLOAT1, t_FLOAT2);
t_COLOR0[0] = sgv_.Cl[0] * t_FLOAT3;
t_COLOR0[1] = sgv_.Cl[1] * t_FLOAT3;
t_COLOR0[2] = sgv_.Cl[2] * t_FLOAT3;
t_COLOR1[0] = SPEC[0] + t_COLOR0[0];
t_COLOR1[1] = SPEC[1] + t_COLOR0[1];
t_COLOR1[2] = SPEC[2] + t_COLOR0[2];
SPEC[0] = t_COLOR1[0];
SPEC[1] = t_COLOR1[1];
SPEC[2] = t_COLOR1[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = J +     1.0;
J = t_FLOAT0;
}
}
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
t_COLOR5[0] = sgv_.Cs[0] * t_COLOR4[0];
t_COLOR5[1] = sgv_.Cs[1] * t_COLOR4[1];
t_COLOR5[2] = sgv_.Cs[2] * t_COLOR4[2];
t_COLOR6[0] = u_ks * SPEC[0];
t_COLOR6[1] = u_ks * SPEC[1];
t_COLOR6[2] = u_ks * SPEC[2];
t_COLOR7[0] = t_COLOR5[0] + t_COLOR6[0];
t_COLOR7[1] = t_COLOR5[1] + t_COLOR6[1];
t_COLOR7[2] = t_COLOR5[2] + t_COLOR6[2];
sgv_.Ci[0] = t_COLOR7[0];
sgv_.Ci[1] = t_COLOR7[1];
sgv_.Ci[2] = t_COLOR7[2];
}
{

if ((true && (u_kr >     0.0))) {
{
Point t_POINT0;

stf_reflect (t_POINT0, sgv_.I, NF);
RDIR[0] = t_POINT0[0];
RDIR[1] = t_POINT0[1];
RDIR[2] = t_POINT0[2];
}
{
Color t_COLOR0;

stf_trace (t_COLOR0, sgv_.P, RDIR, HITF);
REFL[0] = t_COLOR0[0];
REFL[1] = t_COLOR0[1];
REFL[2] = t_COLOR0[2];
}
{
Color t_COLOR0;
Color t_COLOR1;

t_COLOR0[0] = u_kr * REFL[0];
t_COLOR0[1] = u_kr * REFL[1];
t_COLOR0[2] = u_kr * REFL[2];
t_COLOR1[0] = sgv_.Ci[0] + t_COLOR0[0];
t_COLOR1[1] = sgv_.Ci[1] + t_COLOR0[1];
t_COLOR1[2] = sgv_.Ci[2] + t_COLOR0[2];
sgv_.Ci[0] = t_COLOR1[0];
sgv_.Ci[1] = t_COLOR1[1];
sgv_.Ci[2] = t_COLOR1[2];
}
}
}
{

sgv_.Oi[0] = sgv_.Os[0];
sgv_.Oi[1] = sgv_.Os[1];
sgv_.Oi[2] = sgv_.Os[2];
}
{
Color t_COLOR0;

t_COLOR0[0] = sgv_.Oi[0] * sgv_.Ci[0];
t_COLOR0[1] = sgv_.Oi[1] * sgv_.Ci[1];
t_COLOR0[2] = sgv_.Oi[2] * sgv_.Ci[2];
sgv_.Ci[0] = t_COLOR0[0];
sgv_.Ci[1] = t_COLOR0[1];
sgv_.Ci[2] = t_COLOR0[2];
}
}
}
`
};
