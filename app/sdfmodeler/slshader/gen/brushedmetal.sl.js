// 自動生成: dr_sbcl/interface/glsl.lisp — brushedmetal.lisp から。手で編集しない。
export default {
  name: "brushedmetal",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 1.0 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.1 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.9 },
    { name: "uroughness", uniform: "u_uroughness", type: "float", default: 0.15 },
    { name: "vroughness", uniform: "u_vroughness", type: "float", default: 0.5 },
    { name: "brush-dir", uniform: "u_brush_dir", type: "point", default: [0.0, 0.0, 0.0] },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_uroughness;
uniform float u_vroughness;
uniform vec3 u_brush_dir;
void sl_surface()
{
{
Color SPEC;
Float J;
Float NL;
Float G;
Float RHO;
Float HN;
Float YH;
Float XH;
Float CTI;
Float CTR;
Point H;
Point LN;
Point Y;
Point X;
Point XD;
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

t_POINT0[0] =     1.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     0.0;
XD[0] = t_POINT0[0];
XD[1] = t_POINT0[1];
XD[2] = t_POINT0[2];
}
{
Point t_POINT0;

t_POINT0[0] =     1.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     0.0;
X[0] = t_POINT0[0];
X[1] = t_POINT0[1];
X[2] = t_POINT0[2];
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     1.0;
t_POINT0[2] =     0.0;
Y[0] = t_POINT0[0];
Y[1] = t_POINT0[1];
Y[2] = t_POINT0[2];
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     1.0;
LN[0] = t_POINT0[0];
LN[1] = t_POINT0[1];
LN[2] = t_POINT0[2];
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

CTR =     0.0;
}
{

CTI =     0.0;
}
{

XH =     0.0;
}
{

YH =     0.0;
}
{

HN =     0.0;
}
{

RHO =     0.0;
}
{

G =     0.0;
}
{

NL =     0.0;
}
{

J =     0.0;
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

stf_normalize (t_POINT0, sgv_.dPdu);
XD[0] = t_POINT0[0];
XD[1] = t_POINT0[1];
XD[2] = t_POINT0[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_length (u_brush_dir);
if ((true && (t_FLOAT0 >  0.0001))) {
{
Float t_FLOAT0;
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;

t_FLOAT0 = _SQ_dot (NF, u_brush_dir);
t_POINT0[0] = NF[0] * t_FLOAT0;
t_POINT0[1] = NF[1] * t_FLOAT0;
t_POINT0[2] = NF[2] * t_FLOAT0;
t_POINT1[0] = u_brush_dir[0] - t_POINT0[0];
t_POINT1[1] = u_brush_dir[1] - t_POINT0[1];
t_POINT1[2] = u_brush_dir[2] - t_POINT0[2];
stf_normalize (t_POINT2, t_POINT1);
XD[0] = t_POINT2[0];
XD[1] = t_POINT2[1];
XD[2] = t_POINT2[2];
}
}
}
{
Float t_FLOAT0;
Point t_POINT0;

t_FLOAT0 = stf_max (u_uroughness,  0.0001);
t_POINT0[0] = XD[0] / t_FLOAT0;
t_POINT0[1] = XD[1] / t_FLOAT0;
t_POINT0[2] = XD[2] / t_FLOAT0;
X[0] = t_POINT0[0];
X[1] = t_POINT0[1];
X[2] = t_POINT0[2];
}
{
Float t_FLOAT0;
Point t_POINT0;
Point t_POINT1;

stf_cross (t_POINT0, NF, XD);
t_FLOAT0 = stf_max (u_vroughness,  0.0001);
t_POINT1[0] = t_POINT0[0] / t_FLOAT0;
t_POINT1[1] = t_POINT0[1] / t_FLOAT0;
t_POINT1[2] = t_POINT0[2] / t_FLOAT0;
Y[0] = t_POINT1[0];
Y[1] = t_POINT1[1];
Y[2] = t_POINT1[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_dot (NF, VD);
t_FLOAT1 = _SQ_clamp (t_FLOAT0,  0.0001,     1.0);
CTR = t_FLOAT1;
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

stf_normalize (t_POINT0, sgv_.L);
LN[0] = t_POINT0[0];
LN[1] = t_POINT0[1];
LN[2] = t_POINT0[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_dot (LN, NF);
CTI = t_FLOAT0;
}
{
Point t_POINT0;
Point t_POINT1;

t_POINT0[0] = VD[0] + LN[0];
t_POINT0[1] = VD[1] + LN[1];
t_POINT0[2] = VD[2] + LN[2];
stf_normalize (t_POINT1, t_POINT0);
H[0] = t_POINT1[0];
H[1] = t_POINT1[1];
H[2] = t_POINT1[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_dot (X, H);
XH = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_dot (Y, H);
YH = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 = _SQ_dot (H, NF);
t_FLOAT1 =     1.0 + t_FLOAT0;
t_FLOAT2 = stf_max (t_FLOAT1,  0.0001);
HN = t_FLOAT2;
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
Float t_FLOAT9;

t_FLOAT0 = XH * XH;
t_FLOAT1 = YH * YH;
t_FLOAT2 = t_FLOAT0 + t_FLOAT1;
t_FLOAT3 =    -2.0 * t_FLOAT2;
t_FLOAT4 = t_FLOAT3 / HN;
t_FLOAT5 = exp (t_FLOAT4);
t_FLOAT6 = CTI * CTR;
t_FLOAT7 = stf_max (t_FLOAT6, .000001);
t_FLOAT8 = _SQ_sqrt (t_FLOAT7);
t_FLOAT9 = t_FLOAT5 / t_FLOAT8;
RHO = t_FLOAT9;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Color t_COLOR0;
Color t_COLOR1;

t_FLOAT0 = _SQ_step (    0.0, CTI);
t_FLOAT1 = CTI * RHO;
t_FLOAT2 = t_FLOAT0 * t_FLOAT1;
t_COLOR0[0] = sgv_.Cl[0] * t_FLOAT2;
t_COLOR0[1] = sgv_.Cl[1] * t_FLOAT2;
t_COLOR0[2] = sgv_.Cl[2] * t_FLOAT2;
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
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Color t_COLOR0;

t_FLOAT0 = stf_max (u_uroughness,  0.0001);
t_FLOAT1 = stf_max (u_vroughness,  0.0001);
t_FLOAT2 = t_FLOAT0 * t_FLOAT1;
t_FLOAT3 =     4.0 * t_FLOAT2;
t_COLOR0[0] = SPEC[0] / t_FLOAT3;
t_COLOR0[1] = SPEC[1] / t_FLOAT3;
t_COLOR0[2] = SPEC[2] / t_FLOAT3;
SPEC[0] = t_COLOR0[0];
SPEC[1] = t_COLOR0[1];
SPEC[2] = t_COLOR0[2];
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

stf_ambient (t_COLOR0);
t_COLOR1[0] = u_ka * t_COLOR0[0];
t_COLOR1[1] = u_ka * t_COLOR0[1];
t_COLOR1[2] = u_ka * t_COLOR0[2];
stf_diffuse (t_COLOR2, NF);
t_COLOR3[0] = u_kd * t_COLOR2[0];
t_COLOR3[1] = u_kd * t_COLOR2[1];
t_COLOR3[2] = u_kd * t_COLOR2[2];
t_COLOR4[0] = u_ks * SPEC[0];
t_COLOR4[1] = u_ks * SPEC[1];
t_COLOR4[2] = u_ks * SPEC[2];
t_COLOR5[0] = t_COLOR1[0] + t_COLOR3[0] + t_COLOR4[0];
t_COLOR5[1] = t_COLOR1[1] + t_COLOR3[1] + t_COLOR4[1];
t_COLOR5[2] = t_COLOR1[2] + t_COLOR3[2] + t_COLOR4[2];
t_COLOR6[0] = sgv_.Cs[0] * t_COLOR5[0];
t_COLOR6[1] = sgv_.Cs[1] * t_COLOR5[1];
t_COLOR6[2] = sgv_.Cs[2] * t_COLOR5[2];
t_COLOR7[0] = sgv_.Oi[0] * t_COLOR6[0];
t_COLOR7[1] = sgv_.Oi[1] * t_COLOR6[1];
t_COLOR7[2] = sgv_.Oi[2] * t_COLOR6[2];
sgv_.Ci[0] = t_COLOR7[0];
sgv_.Ci[1] = t_COLOR7[1];
sgv_.Ci[2] = t_COLOR7[2];
}
}
}
`
};
