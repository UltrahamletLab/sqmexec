// 自動生成: dr_sbcl/interface/glsl.lisp — oak.lisp から。手で編集しない。
export default {
  name: "oak",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 1.0 },
    { name: "kd", uniform: "u_kd", type: "float", default: 1.0 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.25 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.2 },
    { name: "ringfreq", uniform: "u_ringfreq", type: "float", default: 8.0 },
    { name: "ringunevenness", uniform: "u_ringunevenness", type: "float", default: 0.5 },
    { name: "grainfreq", uniform: "u_grainfreq", type: "float", default: 25.0 },
    { name: "ringnoise", uniform: "u_ringnoise", type: "float", default: 0.02 },
    { name: "ringnoisefreq", uniform: "u_ringnoisefreq", type: "float", default: 1.0 },
    { name: "trunkwobble", uniform: "u_trunkwobble", type: "float", default: 0.15 },
    { name: "trunkwobblefreq", uniform: "u_trunkwobblefreq", type: "float", default: 0.025 },
    { name: "angularwobble", uniform: "u_angularwobble", type: "float", default: 1.0 },
    { name: "angularwobblefreq", uniform: "u_angularwobblefreq", type: "float", default: 1.5 },
    { name: "divotdepth", uniform: "u_divotdepth", type: "float", default: 0.05 },
    { name: "clightwood", uniform: "u_clightwood", type: "color", default: [0.5, 0.2, 0.067] },
    { name: "cdarkwood", uniform: "u_cdarkwood", type: "color", default: [0.15, 0.077, 0.028] },
    { name: "ringy", uniform: "u_ringy", type: "float", default: 1.0 },
    { name: "grainy", uniform: "u_grainy", type: "float", default: 1.0 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_roughness;
uniform float u_ringfreq;
uniform float u_ringunevenness;
uniform float u_grainfreq;
uniform float u_ringnoise;
uniform float u_ringnoisefreq;
uniform float u_trunkwobble;
uniform float u_trunkwobblefreq;
uniform float u_angularwobble;
uniform float u_angularwobblefreq;
uniform float u_divotdepth;
uniform vec3 u_clightwood;
uniform vec3 u_cdarkwood;
uniform float u_ringy;
uniform float u_grainy;
void sl_surface()
{
{
Color CWOOD;
Point NW;
Float WY;
Float WX;
Float EPS;
Float WOOD;
Float G2;
Float G1;
Float GRAIN;
Float BAND;
Float PHASE;
Float RAD;
Float TW;
Float OFF;
Point GP;
Point PR;
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

PP[0] = sgv_.Pg[0];
PP[1] = sgv_.Pg[1];
PP[2] = sgv_.Pg[2];
}
{

PR[0] = sgv_.Pg[0];
PR[1] = sgv_.Pg[1];
PR[2] = sgv_.Pg[2];
}
{

GP[0] = sgv_.Pg[0];
GP[1] = sgv_.Pg[1];
GP[2] = sgv_.Pg[2];
}
{

OFF =     0.0;
}
{

TW =     0.0;
}
{

RAD =     0.0;
}
{

PHASE =     0.0;
}
{

BAND =     0.0;
}
{

GRAIN =     0.0;
}
{

G1 =     0.0;
}
{

G2 =     0.0;
}
{

WOOD =     0.0;
}
{

EPS =   0.035;
}
{

WX =     0.0;
}
{

WY =     0.0;
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     1.0;
NW[0] = t_POINT0[0];
NW[1] = t_POINT0[1];
NW[2] = t_POINT0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
CWOOD[0] = t_COLOR0[0];
CWOOD[1] = t_COLOR0[1];
CWOOD[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Point t_POINT0;

t_POINT0[0] = PP[0] * u_ringnoisefreq;
t_POINT0[1] = PP[1] * u_ringnoisefreq;
t_POINT0[2] = PP[2] * u_ringnoisefreq;
t_FLOAT0 = stf_turbulence (t_POINT0,     4.0);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 = u_ringnoise * t_FLOAT2;
OFF = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;

t_FLOAT0 = _SQ_zcomp (PP);
t_FLOAT1 = t_FLOAT0 * u_trunkwobblefreq;
t_FLOAT2 = stf_fnoisef (t_FLOAT1);
t_FLOAT3 =     2.0 * t_FLOAT2;
t_FLOAT4 = t_FLOAT3 -     1.0;
t_FLOAT5 = u_trunkwobble * t_FLOAT4;
TW = t_FLOAT5;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Point t_POINT0;
Point t_POINT1;

t_FLOAT0 = OFF + TW;
t_FLOAT1 = OFF + TW;
t_POINT0[0] = t_FLOAT0;
t_POINT0[1] = t_FLOAT1;
t_POINT0[2] =     0.0;
t_POINT1[0] = PP[0] + t_POINT0[0];
t_POINT1[1] = PP[1] + t_POINT0[1];
t_POINT1[2] = PP[2] + t_POINT0[2];
PR[0] = t_POINT1[0];
PR[1] = t_POINT1[1];
PR[2] = t_POINT1[2];
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

t_FLOAT0 = _SQ_xcomp (PR);
t_FLOAT1 = _SQ_xcomp (PR);
t_FLOAT2 = t_FLOAT0 * t_FLOAT1;
t_FLOAT3 = _SQ_ycomp (PR);
t_FLOAT4 = _SQ_ycomp (PR);
t_FLOAT5 = t_FLOAT3 * t_FLOAT4;
t_FLOAT6 = t_FLOAT2 + t_FLOAT5;
t_FLOAT7 = _SQ_sqrt (t_FLOAT6);
t_FLOAT8 = u_ringfreq * t_FLOAT7;
RAD = t_FLOAT8;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Point t_POINT0;
Point t_POINT1;

t_FLOAT0 = _SQ_smoothstep (    0.0,     5.0, RAD);
t_POINT0[0] =     1.0;
t_POINT0[1] =     1.0;
t_POINT0[2] =     0.1;
t_POINT1[0] = PR[0] * u_angularwobblefreq * t_POINT0[0];
t_POINT1[1] = PR[1] * u_angularwobblefreq * t_POINT0[1];
t_POINT1[2] = PR[2] * u_angularwobblefreq * t_POINT0[2];
t_FLOAT1 = stf_fnoisep (t_POINT1);
t_FLOAT2 =     2.0 * t_FLOAT1;
t_FLOAT3 = t_FLOAT2 -     1.0;
t_FLOAT4 = u_angularwobble * t_FLOAT0 * t_FLOAT3;
t_FLOAT5 = RAD + t_FLOAT4;
RAD = t_FLOAT5;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Point t_POINT0;

t_FLOAT0 = RAD *    0.35;
t_POINT0[0] = t_FLOAT0;
t_POINT0[1] =     7.1;
t_POINT0[2] =     2.3;
t_FLOAT1 = stf_fnoisep (t_POINT0);
t_FLOAT2 =     2.0 * t_FLOAT1;
t_FLOAT3 = t_FLOAT2 -     1.0;
t_FLOAT4 = u_ringunevenness * t_FLOAT3;
t_FLOAT5 = RAD + t_FLOAT4;
RAD = t_FLOAT5;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = floor (RAD);
t_FLOAT1 = RAD - t_FLOAT0;
PHASE = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = _SQ_smoothstep (   0.08,    0.28, PHASE);
t_FLOAT1 = _SQ_smoothstep (   0.58,    0.82, PHASE);
t_FLOAT2 = t_FLOAT0 - t_FLOAT1;
t_FLOAT3 = t_FLOAT2 * u_ringy;
BAND = t_FLOAT3;
}
{
Point t_POINT0;
Point t_POINT1;

t_POINT0[0] =     1.0;
t_POINT0[1] =     1.0;
t_POINT0[2] =    0.05;
t_POINT1[0] = PP[0] * u_grainfreq * t_POINT0[0];
t_POINT1[1] = PP[1] * u_grainfreq * t_POINT0[1];
t_POINT1[2] = PP[2] * u_grainfreq * t_POINT0[2];
GP[0] = t_POINT1[0];
GP[1] = t_POINT1[1];
GP[2] = t_POINT1[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;

t_FLOAT0 = stf_fnoisep (GP);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 =     0.8 - t_FLOAT2;
t_FLOAT4 = _SQ_clamp (t_FLOAT3,     0.0,     1.0);
t_FLOAT5 = pow (t_FLOAT4,     2.0);
G1 = t_FLOAT5;
}
{
Point t_POINT0;

t_POINT0[0] = GP[0] *     2.0;
t_POINT0[1] = GP[1] *     2.0;
t_POINT0[2] = GP[2] *     2.0;
GP[0] = t_POINT0[0];
GP[1] = t_POINT0[1];
GP[2] = t_POINT0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Float t_FLOAT6;

t_FLOAT0 = stf_fnoisep (GP);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 =     0.5 * t_FLOAT2;
t_FLOAT4 =     0.8 - t_FLOAT3;
t_FLOAT5 = _SQ_clamp (t_FLOAT4,     0.0,     1.0);
t_FLOAT6 = pow (t_FLOAT5,     2.0);
G2 = t_FLOAT6;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = _SQ_smoothstep (    0.5,     0.9, G1);
t_FLOAT1 = _SQ_smoothstep (   0.58,    0.94, G2);
t_FLOAT2 = stf_max (t_FLOAT0, t_FLOAT1);
t_FLOAT3 = u_grainy * t_FLOAT2;
GRAIN = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 =     0.7 * BAND;
t_FLOAT1 =     0.3 + t_FLOAT0;
t_FLOAT2 = GRAIN * t_FLOAT1;
GRAIN = t_FLOAT2;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = stf_max (BAND, GRAIN);
t_FLOAT1 = _SQ_clamp (t_FLOAT0,     0.0,     1.0);
WOOD = t_FLOAT1;
}
{
Color t_COLOR0;

stf_mix (t_COLOR0, u_clightwood, u_cdarkwood, WOOD);
CWOOD[0] = t_COLOR0[0];
CWOOD[1] = t_COLOR0[1];
CWOOD[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;
Point t_POINT3;
Point t_POINT4;
Point t_POINT5;

t_POINT0[0] = PP[0] * u_grainfreq;
t_POINT0[1] = PP[1] * u_grainfreq;
t_POINT0[2] = PP[2] * u_grainfreq;
t_POINT1[0] = EPS;
t_POINT1[1] =     0.0;
t_POINT1[2] =     0.0;
t_POINT2[0] = t_POINT0[0] + t_POINT1[0];
t_POINT2[1] = t_POINT0[1] + t_POINT1[1];
t_POINT2[2] = t_POINT0[2] + t_POINT1[2];
t_FLOAT0 = stf_fnoisep (t_POINT2);
t_POINT3[0] = PP[0] * u_grainfreq;
t_POINT3[1] = PP[1] * u_grainfreq;
t_POINT3[2] = PP[2] * u_grainfreq;
t_POINT4[0] = EPS;
t_POINT4[1] =     0.0;
t_POINT4[2] =     0.0;
t_POINT5[0] = t_POINT3[0] - t_POINT4[0];
t_POINT5[1] = t_POINT3[1] - t_POINT4[1];
t_POINT5[2] = t_POINT3[2] - t_POINT4[2];
t_FLOAT1 = stf_fnoisep (t_POINT5);
t_FLOAT2 = t_FLOAT0 - t_FLOAT1;
WX = t_FLOAT2;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;
Point t_POINT3;
Point t_POINT4;
Point t_POINT5;

t_POINT0[0] = PP[0] * u_grainfreq;
t_POINT0[1] = PP[1] * u_grainfreq;
t_POINT0[2] = PP[2] * u_grainfreq;
t_POINT1[0] =     0.0;
t_POINT1[1] = EPS;
t_POINT1[2] =     0.0;
t_POINT2[0] = t_POINT0[0] + t_POINT1[0];
t_POINT2[1] = t_POINT0[1] + t_POINT1[1];
t_POINT2[2] = t_POINT0[2] + t_POINT1[2];
t_FLOAT0 = stf_fnoisep (t_POINT2);
t_POINT3[0] = PP[0] * u_grainfreq;
t_POINT3[1] = PP[1] * u_grainfreq;
t_POINT3[2] = PP[2] * u_grainfreq;
t_POINT4[0] =     0.0;
t_POINT4[1] = EPS;
t_POINT4[2] =     0.0;
t_POINT5[0] = t_POINT3[0] - t_POINT4[0];
t_POINT5[1] = t_POINT3[1] - t_POINT4[1];
t_POINT5[2] = t_POINT3[2] - t_POINT4[2];
t_FLOAT1 = stf_fnoisep (t_POINT5);
t_FLOAT2 = t_FLOAT0 - t_FLOAT1;
WY = t_FLOAT2;
}
{
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;
Point t_POINT3;

t_POINT0[0] = WX;
t_POINT0[1] = WY;
t_POINT0[2] =     0.0;
t_POINT1[0] = u_divotdepth * t_POINT0[0];
t_POINT1[1] = u_divotdepth * t_POINT0[1];
t_POINT1[2] = u_divotdepth * t_POINT0[2];
t_POINT2[0] = NF[0] - t_POINT1[0];
t_POINT2[1] = NF[1] - t_POINT1[1];
t_POINT2[2] = NF[2] - t_POINT1[2];
stf_normalize (t_POINT3, t_POINT2);
NW[0] = t_POINT3[0];
NW[1] = t_POINT3[1];
NW[2] = t_POINT3[2];
}
{

sgv_.Oi[0] = sgv_.Os[0];
sgv_.Oi[1] = sgv_.Os[1];
sgv_.Oi[2] = sgv_.Os[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
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
stf_diffuse (t_COLOR2, NW);
t_COLOR3[0] = u_kd * t_COLOR2[0];
t_COLOR3[1] = u_kd * t_COLOR2[1];
t_COLOR3[2] = u_kd * t_COLOR2[2];
t_COLOR4[0] = t_COLOR1[0] + t_COLOR3[0];
t_COLOR4[1] = t_COLOR1[1] + t_COLOR3[1];
t_COLOR4[2] = t_COLOR1[2] + t_COLOR3[2];
t_COLOR5[0] = CWOOD[0] * t_COLOR4[0];
t_COLOR5[1] = CWOOD[1] * t_COLOR4[1];
t_COLOR5[2] = CWOOD[2] * t_COLOR4[2];
t_FLOAT0 =     0.5 * WOOD;
t_FLOAT1 =     1.0 - t_FLOAT0;
stf_specular (t_COLOR6, NW, IR, u_roughness);
t_COLOR7[0] = t_FLOAT1 * u_ks * t_COLOR6[0];
t_COLOR7[1] = t_FLOAT1 * u_ks * t_COLOR6[1];
t_COLOR7[2] = t_FLOAT1 * u_ks * t_COLOR6[2];
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
