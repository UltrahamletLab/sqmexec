// 自動生成: dr_sbcl/interface/glsl.lisp — clay.lisp から。手で編集しない。
export default {
  name: "clay",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 1.0 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.7 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.1 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_roughness;
void sl_surface()
{
{
Color DSUM;
Float BE;
Float AL;
Float THI;
Float CPD;
Float CTI;
Point LN;
Float G;
Float J;
Float NL;
Point VPERP;
Float THR;
Float VN;
Float OB;
Float OA;
Float SIG2;
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
Float t_FLOAT0;

t_FLOAT0 = u_roughness * u_roughness;
SIG2 = t_FLOAT0;
}
{

OA =     0.0;
}
{

OB =     0.0;
}
{

VN =     0.0;
}
{

THR =     0.0;
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     1.0;
VPERP[0] = t_POINT0[0];
VPERP[1] = t_POINT0[1];
VPERP[2] = t_POINT0[2];
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
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     1.0;
LN[0] = t_POINT0[0];
LN[1] = t_POINT0[1];
LN[2] = t_POINT0[2];
}
{

CTI =     0.0;
}
{

CPD =     0.0;
}
{

THI =     0.0;
}
{

AL =     0.0;
}
{

BE =     0.0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
DSUM[0] = t_COLOR0[0];
DSUM[1] = t_COLOR0[1];
DSUM[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 =     0.5 * SIG2;
t_FLOAT1 = SIG2 +    0.33;
t_FLOAT2 = t_FLOAT0 / t_FLOAT1;
t_FLOAT3 =     1.0 - t_FLOAT2;
OA = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 =    0.45 * SIG2;
t_FLOAT1 = SIG2 +    0.09;
t_FLOAT2 = t_FLOAT0 / t_FLOAT1;
OB = t_FLOAT2;
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_dot (VD, NF);
VN = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_clamp (VN,    -1.0,     1.0);
t_FLOAT1 = acos (t_FLOAT0);
THR = t_FLOAT1;
}
{
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;

t_POINT0[0] = NF[0] * VN;
t_POINT0[1] = NF[1] * VN;
t_POINT0[2] = NF[2] * VN;
t_POINT1[0] = VD[0] - t_POINT0[0];
t_POINT1[1] = VD[1] - t_POINT0[1];
t_POINT1[2] = VD[2] - t_POINT0[2];
stf_normalize (t_POINT2, t_POINT1);
VPERP[0] = t_POINT2[0];
VPERP[1] = t_POINT2[1];
VPERP[2] = t_POINT2[2];
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
Float t_FLOAT0;
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;

t_POINT0[0] = NF[0] * CTI;
t_POINT0[1] = NF[1] * CTI;
t_POINT0[2] = NF[2] * CTI;
t_POINT1[0] = LN[0] - t_POINT0[0];
t_POINT1[1] = LN[1] - t_POINT0[1];
t_POINT1[2] = LN[2] - t_POINT0[2];
stf_normalize (t_POINT2, t_POINT1);
t_FLOAT0 = _SQ_dot (VPERP, t_POINT2);
CPD = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_clamp (CTI,    -1.0,     1.0);
t_FLOAT1 = acos (t_FLOAT0);
THI = t_FLOAT1;
}
{
Float t_FLOAT0;

t_FLOAT0 = stf_max (THI, THR);
AL = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = stf_min (THI, THR);
BE = t_FLOAT0;
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
Color t_COLOR0;
Color t_COLOR1;

t_FLOAT0 = stf_max (CTI,     0.0);
t_FLOAT1 = stf_max (CPD,     0.0);
t_FLOAT2 = sin (AL);
t_FLOAT3 = tan (BE);
t_FLOAT4 = t_FLOAT2 * t_FLOAT3;
t_FLOAT5 = t_FLOAT1 * t_FLOAT4;
t_FLOAT6 = OB * t_FLOAT5;
t_FLOAT7 = OA + t_FLOAT6;
t_FLOAT8 = t_FLOAT0 * t_FLOAT7;
t_COLOR0[0] = sgv_.Cl[0] * t_FLOAT8;
t_COLOR0[1] = sgv_.Cl[1] * t_FLOAT8;
t_COLOR0[2] = sgv_.Cl[2] * t_FLOAT8;
t_COLOR1[0] = DSUM[0] + t_COLOR0[0];
t_COLOR1[1] = DSUM[1] + t_COLOR0[1];
t_COLOR1[2] = DSUM[2] + t_COLOR0[2];
DSUM[0] = t_COLOR1[0];
DSUM[1] = t_COLOR1[1];
DSUM[2] = t_COLOR1[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = J +     1.0;
J = t_FLOAT0;
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
Color t_COLOR1;
Color t_COLOR2;
Color t_COLOR3;
Color t_COLOR4;
Color t_COLOR5;

stf_ambient (t_COLOR0);
t_COLOR1[0] = u_ka * t_COLOR0[0];
t_COLOR1[1] = u_ka * t_COLOR0[1];
t_COLOR1[2] = u_ka * t_COLOR0[2];
t_COLOR2[0] = u_kd * DSUM[0];
t_COLOR2[1] = u_kd * DSUM[1];
t_COLOR2[2] = u_kd * DSUM[2];
t_COLOR3[0] = t_COLOR1[0] + t_COLOR2[0];
t_COLOR3[1] = t_COLOR1[1] + t_COLOR2[1];
t_COLOR3[2] = t_COLOR1[2] + t_COLOR2[2];
t_COLOR4[0] = sgv_.Cs[0] * t_COLOR3[0];
t_COLOR4[1] = sgv_.Cs[1] * t_COLOR3[1];
t_COLOR4[2] = sgv_.Cs[2] * t_COLOR3[2];
t_COLOR5[0] = sgv_.Oi[0] * t_COLOR4[0];
t_COLOR5[1] = sgv_.Oi[1] * t_COLOR4[1];
t_COLOR5[2] = sgv_.Oi[2] * t_COLOR4[2];
sgv_.Ci[0] = t_COLOR5[0];
sgv_.Ci[1] = t_COLOR5[1];
sgv_.Ci[2] = t_COLOR5[2];
}
}
}
`
};
