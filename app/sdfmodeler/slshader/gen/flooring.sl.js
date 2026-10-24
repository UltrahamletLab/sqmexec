// 自動生成: dr_sbcl/interface/glsl.lisp — flooring.lisp から。手で編集しない。
export default {
  name: "flooring",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 0.4 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.75 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.35 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.012 },
    { name: "kr", uniform: "u_kr", type: "float", default: 0.1 },
    { name: "plankwidth", uniform: "u_plankwidth", type: "float", default: 0.13 },
    { name: "planklength", uniform: "u_planklength", type: "float", default: 1.8 },
    { name: "groovewidth", uniform: "u_groovewidth", type: "float", default: 0.0012 },
    { name: "groovecolor", uniform: "u_groovecolor", type: "color", default: [0.03, 0.012, 0.004] },
    { name: "cearly", uniform: "u_cearly", type: "color", default: [0.3, 0.14, 0.045] },
    { name: "clate", uniform: "u_clate", type: "color", default: [0.11, 0.04, 0.012] },
    { name: "ringspacing", uniform: "u_ringspacing", type: "float", default: 0.0065 },
    { name: "ringcontrast", uniform: "u_ringcontrast", type: "float", default: 0.6 },
    { name: "ringwarp", uniform: "u_ringwarp", type: "float", default: 0.6 },
    { name: "tilt", uniform: "u_tilt", type: "float", default: 0.035 },
    { name: "streaks", uniform: "u_streaks", type: "float", default: 0.22 },
    { name: "pores", uniform: "u_pores", type: "float", default: 0.3 },
    { name: "plankvary", uniform: "u_plankvary", type: "float", default: 0.16 },
    { name: "graindepth", uniform: "u_graindepth", type: "float", default: 0.06 },
    { name: "detailfade", uniform: "u_detailfade", type: "float", default: 1.0 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_roughness;
uniform float u_kr;
uniform float u_plankwidth;
uniform float u_planklength;
uniform float u_groovewidth;
uniform vec3 u_groovecolor;
uniform vec3 u_cearly;
uniform vec3 u_clate;
uniform float u_ringspacing;
uniform float u_ringcontrast;
uniform float u_ringwarp;
uniform float u_tilt;
uniform float u_streaks;
uniform float u_pores;
uniform float u_plankvary;
uniform float u_graindepth;
uniform float u_detailfade;
void sl_surface()
{
{
Float FARR;
Float FARP;
Float DIST;
Float GLOSS;
Float FRES;
Color HITC;
Point R;
Color WOOD;
Float SEAM;
Float EV;
Float EU;
Float TONE;
Float PORE;
Float STREAK;
Float LATE;
Float FR;
Float PH;
Float RAD;
Float DV;
Float PDEP;
Float CY;
Float H4;
Float H3;
Float H2;
Float H1;
Float SU;
Float PV;
Float PU;
Float COL;
Float ROW;
Float TT;
Float SS;
Point VDIR;
Point NW;
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

NW[0] = NF[0];
NW[1] = NF[1];
NW[2] = NF[2];
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

SS =     0.0;
}
{

TT =     0.0;
}
{

ROW =     0.0;
}
{

COL =     0.0;
}
{

PU =     0.0;
}
{

PV =     0.0;
}
{

SU =     0.0;
}
{

H1 =     0.0;
}
{

H2 =     0.0;
}
{

H3 =     0.0;
}
{

H4 =     0.0;
}
{

CY =     0.0;
}
{

PDEP =     0.0;
}
{

DV =     0.0;
}
{

RAD =     0.0;
}
{

PH =     0.0;
}
{

FR =     0.0;
}
{

LATE =     0.0;
}
{

STREAK =     0.0;
}
{

PORE =     0.0;
}
{

TONE =     0.0;
}
{

EU =     0.0;
}
{

EV =     0.0;
}
{

SEAM =     0.0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
WOOD[0] = t_COLOR0[0];
WOOD[1] = t_COLOR0[1];
WOOD[2] = t_COLOR0[2];
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     0.0;
R[0] = t_POINT0[0];
R[1] = t_POINT0[1];
R[2] = t_POINT0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
HITC[0] = t_COLOR0[0];
HITC[1] = t_COLOR0[1];
HITC[2] = t_COLOR0[2];
}
{

FRES =     0.0;
}
{

GLOSS =     0.0;
}
{

DIST =     0.0;
}
{

FARP =     0.0;
}
{

FARR =     0.0;
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_xcomp (sgv_.Pg);
SS = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_zcomp (sgv_.Pg);
TT = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = TT / u_plankwidth;
t_FLOAT1 = floor (t_FLOAT0);
ROW = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = ROW * u_plankwidth;
t_FLOAT1 = TT - t_FLOAT0;
PV = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Point t_POINT0;

t_FLOAT0 = ROW *   0.731;
t_FLOAT1 = t_FLOAT0 +    0.17;
t_POINT0[0] = t_FLOAT1;
t_POINT0[1] =     4.3;
t_POINT0[2] =     9.1;
t_FLOAT2 = stf_fnoisep (t_POINT0);
t_FLOAT3 = u_planklength *     6.0 * t_FLOAT2;
t_FLOAT4 = SS + t_FLOAT3;
SU = t_FLOAT4;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = SU / u_planklength;
t_FLOAT1 = floor (t_FLOAT0);
COL = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = COL * u_planklength;
t_FLOAT1 = SU - t_FLOAT0;
PU = t_FLOAT1;
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

t_FLOAT0 = ROW *    1.37;
t_FLOAT1 = t_FLOAT0 +    0.31;
t_FLOAT2 = COL *    1.91;
t_FLOAT3 = t_FLOAT2 +    0.53;
t_POINT0[0] = t_FLOAT1;
t_POINT0[1] = t_FLOAT3;
t_POINT0[2] =     2.7;
t_FLOAT4 = stf_fnoisep (t_POINT0);
t_FLOAT5 = t_FLOAT4 -     0.5;
t_FLOAT6 =     2.5 * t_FLOAT5;
t_FLOAT7 =     0.5 + t_FLOAT6;
t_FLOAT8 = _SQ_clamp (t_FLOAT7,     0.0,     1.0);
H1 = t_FLOAT8;
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

t_FLOAT0 = ROW *    0.83;
t_FLOAT1 = t_FLOAT0 +     5.1;
t_FLOAT2 = COL *    1.17;
t_FLOAT3 = t_FLOAT2 +     3.3;
t_POINT0[0] = t_FLOAT1;
t_POINT0[1] = t_FLOAT3;
t_POINT0[2] =     7.9;
t_FLOAT4 = stf_fnoisep (t_POINT0);
t_FLOAT5 = t_FLOAT4 -     0.5;
t_FLOAT6 =     2.5 * t_FLOAT5;
t_FLOAT7 =     0.5 + t_FLOAT6;
t_FLOAT8 = _SQ_clamp (t_FLOAT7,     0.0,     1.0);
H2 = t_FLOAT8;
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

t_FLOAT0 = ROW *    2.11;
t_FLOAT1 = t_FLOAT0 +     1.7;
t_FLOAT2 = COL *    0.67;
t_FLOAT3 = t_FLOAT2 +     8.2;
t_POINT0[0] = t_FLOAT1;
t_POINT0[1] = t_FLOAT3;
t_POINT0[2] =     4.4;
t_FLOAT4 = stf_fnoisep (t_POINT0);
t_FLOAT5 = t_FLOAT4 -     0.5;
t_FLOAT6 =     2.5 * t_FLOAT5;
t_FLOAT7 =     0.5 + t_FLOAT6;
t_FLOAT8 = _SQ_clamp (t_FLOAT7,     0.0,     1.0);
H3 = t_FLOAT8;
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

t_FLOAT0 = ROW *    0.59;
t_FLOAT1 = t_FLOAT0 +     9.7;
t_FLOAT2 = COL *    2.43;
t_FLOAT3 = t_FLOAT2 +     6.1;
t_POINT0[0] = t_FLOAT1;
t_POINT0[1] = t_FLOAT3;
t_POINT0[2] =     1.9;
t_FLOAT4 = stf_fnoisep (t_POINT0);
t_FLOAT5 = t_FLOAT4 -     0.5;
t_FLOAT6 =     2.5 * t_FLOAT5;
t_FLOAT7 =     0.5 + t_FLOAT6;
t_FLOAT8 = _SQ_clamp (t_FLOAT7,     0.0,     1.0);
H4 = t_FLOAT8;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = H1 -     0.5;
t_FLOAT1 = t_FLOAT0 *     2.4 * u_plankwidth;
CY = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Float t_FLOAT6;

t_FLOAT0 =    0.09 * H2;
t_FLOAT1 =     2.0 * H3;
t_FLOAT2 = t_FLOAT1 -     1.0;
t_FLOAT3 =     0.5 * u_planklength;
t_FLOAT4 = PU - t_FLOAT3;
t_FLOAT5 = u_tilt * t_FLOAT2 * t_FLOAT4;
t_FLOAT6 =   0.015 + t_FLOAT0 + t_FLOAT5;
PDEP = t_FLOAT6;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 =     0.5 * u_plankwidth;
t_FLOAT1 = PV - t_FLOAT0 - CY;
DV = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = DV * DV;
t_FLOAT1 = PDEP * PDEP;
t_FLOAT2 = t_FLOAT0 + t_FLOAT1;
t_FLOAT3 = _SQ_sqrt (t_FLOAT2);
RAD = t_FLOAT3;
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
Point t_POINT0;

t_FLOAT0 = PU *     1.3;
t_FLOAT1 = PV *     9.0;
t_FLOAT2 = H4 *    20.0;
t_POINT0[0] = t_FLOAT0;
t_POINT0[1] = t_FLOAT1;
t_POINT0[2] = t_FLOAT2;
t_FLOAT3 = stf_fnoisep (t_POINT0);
t_FLOAT4 =     2.0 * t_FLOAT3;
t_FLOAT5 = t_FLOAT4 -     1.0;
t_FLOAT6 = u_ringwarp * u_ringspacing * t_FLOAT5;
t_FLOAT7 = RAD + t_FLOAT6;
RAD = t_FLOAT7;
}
{
Float t_FLOAT0;

t_FLOAT0 = RAD / u_ringspacing;
PH = t_FLOAT0;
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
Point t_POINT0;
Point t_POINT1;

t_FLOAT0 = PH *    0.11;
t_FLOAT1 = H1 *     5.0;
t_POINT0[0] = t_FLOAT0;
t_POINT0[1] = t_FLOAT1;
t_POINT0[2] =     1.7;
t_FLOAT2 = stf_fnoisep (t_POINT0);
t_FLOAT3 =     1.2 * t_FLOAT2;
t_FLOAT4 = RAD *    40.0;
t_POINT1[0] = t_FLOAT4;
t_POINT1[1] = H1;
t_POINT1[2] =     3.3;
t_FLOAT5 = stf_fnoisep (t_POINT1);
t_FLOAT6 =    0.25 * t_FLOAT5;
t_FLOAT7 = PH + t_FLOAT3 + t_FLOAT6;
PH = t_FLOAT7;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = floor (PH);
t_FLOAT1 = PH - t_FLOAT0;
FR = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = _SQ_smoothstep (   0.45,    0.88, FR);
t_FLOAT1 = _SQ_smoothstep (   0.92,     1.0, FR);
t_FLOAT2 = t_FLOAT0 - t_FLOAT1;
t_FLOAT3 = u_ringcontrast * t_FLOAT2;
LATE = t_FLOAT3;
}
{
Float t_FLOAT0;

t_FLOAT0 = stf_distance (sgv_.P, sgv_.E);
DIST = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 =     2.0 * u_detailfade;
t_FLOAT1 =     7.0 * u_detailfade;
t_FLOAT2 = _SQ_smoothstep (t_FLOAT0, t_FLOAT1, DIST);
FARP = t_FLOAT2;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 =     3.5 * u_detailfade;
t_FLOAT1 =    11.0 * u_detailfade;
t_FLOAT2 = _SQ_smoothstep (t_FLOAT0, t_FLOAT1, DIST);
FARR = t_FLOAT2;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 =     0.3 * u_ringcontrast;
t_FLOAT1 = t_FLOAT0 - LATE;
t_FLOAT2 = FARR * t_FLOAT1;
t_FLOAT3 = LATE + t_FLOAT2;
LATE = t_FLOAT3;
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
Point t_POINT0;

t_FLOAT0 =     0.7 * FARP;
t_FLOAT1 =     1.0 - t_FLOAT0;
t_FLOAT2 = PU *     5.0;
t_FLOAT3 = PV *   260.0;
t_FLOAT4 = H1 *     7.0;
t_POINT0[0] = t_FLOAT2;
t_POINT0[1] = t_FLOAT3;
t_POINT0[2] = t_FLOAT4;
t_FLOAT5 = stf_fnoisep (t_POINT0);
t_FLOAT6 = _SQ_smoothstep (   0.45,     0.8, t_FLOAT5);
t_FLOAT7 = u_streaks * t_FLOAT1 * t_FLOAT6;
STREAK = t_FLOAT7;
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

t_FLOAT0 =     1.0 - FARP;
t_FLOAT1 = PU *    60.0;
t_FLOAT2 = PV *   520.0;
t_FLOAT3 = H2 *     5.0;
t_POINT0[0] = t_FLOAT1;
t_POINT0[1] = t_FLOAT2;
t_POINT0[2] = t_FLOAT3;
t_FLOAT4 = stf_fnoisep (t_POINT0);
t_FLOAT5 = _SQ_smoothstep (    0.6,    0.85, t_FLOAT4);
t_FLOAT6 =     0.6 * LATE;
t_FLOAT7 =     0.4 + t_FLOAT6;
t_FLOAT8 = u_pores * t_FLOAT0 * t_FLOAT5 * t_FLOAT7;
PORE = t_FLOAT8;
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
Float t_FLOAT10;
Point t_POINT0;

t_FLOAT0 =     2.0 * H4;
t_FLOAT1 = t_FLOAT0 -     1.0;
t_FLOAT2 = u_plankvary * t_FLOAT1;
t_FLOAT3 =     1.0 + t_FLOAT2;
t_FLOAT4 = PU *     0.7;
t_FLOAT5 = PV *    14.0;
t_FLOAT6 = H2 *     9.0;
t_POINT0[0] = t_FLOAT4;
t_POINT0[1] = t_FLOAT5;
t_POINT0[2] = t_FLOAT6;
t_FLOAT7 = stf_fnoisep (t_POINT0);
t_FLOAT8 =     0.2 * t_FLOAT7;
t_FLOAT9 =     0.9 + t_FLOAT8;
t_FLOAT10 = t_FLOAT3 * t_FLOAT9;
TONE = t_FLOAT10;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Color t_COLOR0;
Color t_COLOR1;

stf_mix (t_COLOR0, u_cearly, u_clate, LATE);
t_FLOAT0 =     1.0 - STREAK;
t_FLOAT1 =     1.0 - PORE;
t_COLOR1[0] = t_COLOR0[0] * TONE * t_FLOAT0 * t_FLOAT1;
t_COLOR1[1] = t_COLOR0[1] * TONE * t_FLOAT0 * t_FLOAT1;
t_COLOR1[2] = t_COLOR0[2] * TONE * t_FLOAT0 * t_FLOAT1;
WOOD[0] = t_COLOR1[0];
WOOD[1] = t_COLOR1[1];
WOOD[2] = t_COLOR1[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = u_planklength - PU;
t_FLOAT1 = stf_min (PU, t_FLOAT0);
EU = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = u_plankwidth - PV;
t_FLOAT1 = stf_min (PV, t_FLOAT0);
EV = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = _SQ_smoothstep (    0.0, u_groovewidth, EU);
t_FLOAT1 = _SQ_smoothstep (    0.0, u_groovewidth, EV);
t_FLOAT2 = t_FLOAT0 * t_FLOAT1;
t_FLOAT3 =     1.0 - t_FLOAT2;
SEAM = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 =     0.6 * FARR;
t_FLOAT1 =     1.0 - t_FLOAT0;
t_FLOAT2 = SEAM * t_FLOAT1;
SEAM = t_FLOAT2;
}
{
Color t_COLOR0;

stf_mix (t_COLOR0, WOOD, u_groovecolor, SEAM);
WOOD[0] = t_COLOR0[0];
WOOD[1] = t_COLOR0[1];
WOOD[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;
Point t_POINT3;

t_FLOAT0 =     0.5 * u_streaks;
t_FLOAT1 = STREAK - t_FLOAT0;
t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] = t_FLOAT1;
t_POINT1[0] = u_graindepth * t_POINT0[0];
t_POINT1[1] = u_graindepth * t_POINT0[1];
t_POINT1[2] = u_graindepth * t_POINT0[2];
t_POINT2[0] = NF[0] + t_POINT1[0];
t_POINT2[1] = NF[1] + t_POINT1[1];
t_POINT2[2] = NF[2] + t_POINT1[2];
stf_normalize (t_POINT3, t_POINT2);
NW[0] = t_POINT3[0];
NW[1] = t_POINT3[1];
NW[2] = t_POINT3[2];
}
{
Float t_FLOAT0;

t_FLOAT0 =     1.0 - SEAM;
GLOSS = t_FLOAT0;
}
{
Point t_POINT0;

stf_reflect (t_POINT0, sgv_.I, NW);
R[0] = t_POINT0[0];
R[1] = t_POINT0[1];
R[2] = t_POINT0[2];
}
{
Float t_FLOAT0;
Color t_COLOR0;

stf_trace (t_COLOR0, sgv_.P, R, t_FLOAT0);
HITC[0] = t_COLOR0[0];
HITC[1] = t_COLOR0[1];
HITC[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;

t_FLOAT0 = _SQ_dot (NW, VDIR);
t_FLOAT1 = _SQ_clamp (t_FLOAT0,     0.0,     1.0);
t_FLOAT2 =     1.0 - t_FLOAT1;
t_FLOAT3 = pow (t_FLOAT2,     5.0);
t_FLOAT4 =    0.96 * t_FLOAT3;
t_FLOAT5 =    0.04 + t_FLOAT4;
FRES = t_FLOAT5;
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
Color t_COLOR10;

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
t_COLOR5[0] = WOOD[0] * t_COLOR4[0];
t_COLOR5[1] = WOOD[1] * t_COLOR4[1];
t_COLOR5[2] = WOOD[2] * t_COLOR4[2];
stf_specular (t_COLOR6, NW, VDIR, u_roughness);
t_COLOR7[0] = GLOSS * u_ks * t_COLOR6[0];
t_COLOR7[1] = GLOSS * u_ks * t_COLOR6[1];
t_COLOR7[2] = GLOSS * u_ks * t_COLOR6[2];
t_COLOR8[0] = GLOSS * u_kr * FRES * HITC[0];
t_COLOR8[1] = GLOSS * u_kr * FRES * HITC[1];
t_COLOR8[2] = GLOSS * u_kr * FRES * HITC[2];
t_COLOR9[0] = t_COLOR5[0] + t_COLOR7[0] + t_COLOR8[0];
t_COLOR9[1] = t_COLOR5[1] + t_COLOR7[1] + t_COLOR8[1];
t_COLOR9[2] = t_COLOR5[2] + t_COLOR7[2] + t_COLOR8[2];
t_COLOR10[0] = sgv_.Oi[0] * t_COLOR9[0];
t_COLOR10[1] = sgv_.Oi[1] * t_COLOR9[1];
t_COLOR10[2] = sgv_.Oi[2] * t_COLOR9[2];
sgv_.Ci[0] = t_COLOR10[0];
sgv_.Ci[1] = t_COLOR10[1];
sgv_.Ci[2] = t_COLOR10[2];
}
}
}
`
};
