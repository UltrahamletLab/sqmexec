// 自動生成: dr_sbcl/interface/glsl.lisp — superplank.lisp から。手で編集しない。
export default {
  name: "superplank",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 0.7 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.75 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.35 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.12 },
    { name: "specularcolor", uniform: "u_specularcolor", type: "color", default: [1.0, 1.0, 1.0] },
    { name: "kr", uniform: "u_kr", type: "float", default: 0.12 },
    { name: "txtscale", uniform: "u_txtscale", type: "float", default: 1.0 },
    { name: "km", uniform: "u_km", type: "float", default: 0.08 },
    { name: "lightwood", uniform: "u_lightwood", type: "color", default: [0.52, 0.24, 0.07] },
    { name: "plankpattern", uniform: "u_plankpattern", type: "float", default: 0.0 },
    { name: "plankspertile", uniform: "u_plankspertile", type: "float", default: 4.0 },
    { name: "plankwidth", uniform: "u_plankwidth", type: "float", default: 0.25 },
    { name: "planklength", uniform: "u_planklength", type: "float", default: 1.6 },
    { name: "groovewidth", uniform: "u_groovewidth", type: "float", default: 0.018 },
    { name: "groovedepth", uniform: "u_groovedepth", type: "float", default: 0.08 },
    { name: "groovecolor", uniform: "u_groovecolor", type: "color", default: [0.035, 0.018, 0.008] },
    { name: "plankstagger", uniform: "u_plankstagger", type: "float", default: 0.5 },
    { name: "plankvary", uniform: "u_plankvary", type: "float", default: 0.22 },
    { name: "ringscale", uniform: "u_ringscale", type: "float", default: 9.0 },
    { name: "ringwidth", uniform: "u_ringwidth", type: "float", default: 0.18 },
    { name: "wavy", uniform: "u_wavy", type: "float", default: 0.18 },
    { name: "grainy", uniform: "u_grainy", type: "float", default: 0.35 },
    { name: "grainscale", uniform: "u_grainscale", type: "float", default: 28.0 },
    { name: "graindepth", uniform: "u_graindepth", type: "float", default: 0.04 },
    { name: "mapping", uniform: "u_mapping", type: "float", default: 1.0 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_roughness;
uniform vec3 u_specularcolor;
uniform float u_kr;
uniform float u_txtscale;
uniform float u_km;
uniform vec3 u_lightwood;
uniform float u_plankpattern;
uniform float u_plankspertile;
uniform float u_plankwidth;
uniform float u_planklength;
uniform float u_groovewidth;
uniform float u_groovedepth;
uniform vec3 u_groovecolor;
uniform float u_plankstagger;
uniform float u_plankvary;
uniform float u_ringscale;
uniform float u_ringwidth;
uniform float u_wavy;
uniform float u_grainy;
uniform float u_grainscale;
uniform float u_graindepth;
uniform float u_mapping;
void sl_surface()
{
{
Float TMP2;
Float CSWP;
Float CELLW;
Float FRES;
Color HITC;
Point R;
Color WOOD;
Float GRAIN;
Float RING;
Float CELL;
Float GROOVE;
Float EDGEV;
Float EDGEU;
Float FV;
Float FU;
Float COL;
Float ROW;
Point PP;
Float ANZ;
Float ANY;
Float ANX;
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
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_xcomp (NF);
t_FLOAT1 = _SQ_abs (t_FLOAT0);
ANX = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_ycomp (NF);
t_FLOAT1 = _SQ_abs (t_FLOAT0);
ANY = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_zcomp (NF);
t_FLOAT1 = _SQ_abs (t_FLOAT0);
ANZ = t_FLOAT1;
}
{

PP[0] = sgv_.Po[0];
PP[1] = sgv_.Po[1];
PP[2] = sgv_.Po[2];
}
{

ROW =     0.0;
}
{

COL =     0.0;
}
{

FU =     0.0;
}
{

FV =     0.0;
}
{

EDGEU =     0.0;
}
{

EDGEV =     0.0;
}
{

GROOVE =     0.0;
}
{

CELL =     0.0;
}
{

RING =     0.0;
}
{

GRAIN =     0.0;
}
{

WOOD[0] = u_lightwood[0];
WOOD[1] = u_lightwood[1];
WOOD[2] = u_lightwood[2];
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

CELLW =     0.0;
}
{

CSWP =     0.0;
}
{

TMP2 =     0.0;
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

if ((true && (u_mapping <     0.5))) {
{
Float t_FLOAT0;

t_FLOAT0 = sgv_.s * u_txtscale;
SS = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = sgv_.t * u_txtscale;
TT = t_FLOAT0;
}
} else {
{
Float t_FLOAT0;

t_FLOAT0 = stf_max (ANX, ANZ);
if ((true && (ANY > t_FLOAT0))) {
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_xcomp (PP);
t_FLOAT1 = t_FLOAT0 * u_txtscale;
SS = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_zcomp (PP);
t_FLOAT1 = t_FLOAT0 * u_txtscale;
TT = t_FLOAT1;
}
} else {
{

if ((true && (ANX > ANZ))) {
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_zcomp (PP);
t_FLOAT1 = t_FLOAT0 * u_txtscale;
SS = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_ycomp (PP);
t_FLOAT1 = t_FLOAT0 * u_txtscale;
TT = t_FLOAT1;
}
} else {
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_xcomp (PP);
t_FLOAT1 = t_FLOAT0 * u_txtscale;
SS = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_ycomp (PP);
t_FLOAT1 = t_FLOAT0 * u_txtscale;
TT = t_FLOAT1;
}
}
}
}
}
}
}
{

if ((true && (u_plankpattern >     1.5))) {
{
Float t_FLOAT0;

t_FLOAT0 = u_plankwidth * u_plankspertile;
CELLW = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;

t_FLOAT0 = SS / CELLW;
t_FLOAT1 = floor (t_FLOAT0);
t_FLOAT2 = TT / CELLW;
t_FLOAT3 = floor (t_FLOAT2);
t_FLOAT4 = t_FLOAT1 + t_FLOAT3;
CSWP = t_FLOAT4;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = CSWP /     2.0;
t_FLOAT1 = floor (t_FLOAT0);
t_FLOAT2 =     2.0 * t_FLOAT1;
t_FLOAT3 = CSWP - t_FLOAT2;
CSWP = t_FLOAT3;
}
{

if ((true && (CSWP >     0.5))) {
{

TMP2 = SS;
}
{

SS = TT;
}
{

TT = TMP2;
}
}
}
}
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

t_FLOAT0 = u_plankstagger * ROW;
t_FLOAT1 = SS + t_FLOAT0;
SS = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = SS / u_planklength;
t_FLOAT1 = floor (t_FLOAT0);
COL = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = SS / u_planklength;
t_FLOAT1 = SS / u_planklength;
t_FLOAT2 = floor (t_FLOAT1);
t_FLOAT3 = t_FLOAT0 - t_FLOAT2;
FU = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = TT / u_plankwidth;
t_FLOAT1 = TT / u_plankwidth;
t_FLOAT2 = floor (t_FLOAT1);
t_FLOAT3 = t_FLOAT0 - t_FLOAT2;
FV = t_FLOAT3;
}
{

if ((true && (true && (u_plankpattern >     0.5)) && (true && (u_plankpattern <     1.5)))) {
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = TT / u_planklength;
t_FLOAT1 = TT / u_planklength;
t_FLOAT2 = floor (t_FLOAT1);
t_FLOAT3 = t_FLOAT0 - t_FLOAT2;
FU = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = SS / u_plankwidth;
t_FLOAT1 = SS / u_plankwidth;
t_FLOAT2 = floor (t_FLOAT1);
t_FLOAT3 = t_FLOAT0 - t_FLOAT2;
FV = t_FLOAT3;
}
}
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 =     1.0 - FU;
t_FLOAT1 = stf_min (FU, t_FLOAT0);
EDGEU = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 =     1.0 - FV;
t_FLOAT1 = stf_min (FV, t_FLOAT0);
EDGEV = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = _SQ_smoothstep (    0.0, u_groovewidth, EDGEU);
t_FLOAT1 = _SQ_smoothstep (    0.0, u_groovewidth, EDGEV);
t_FLOAT2 = t_FLOAT0 * t_FLOAT1;
t_FLOAT3 =     1.0 - t_FLOAT2;
GROOVE = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Point t_POINT0;

t_POINT0[0] = ROW;
t_POINT0[1] = COL;
t_POINT0[2] =    13.7;
t_FLOAT0 = stf_fnoisep (t_POINT0);
t_FLOAT1 =     2.0 * t_FLOAT0;
t_FLOAT2 = t_FLOAT1 -     1.0;
CELL = t_FLOAT2;
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

t_FLOAT0 = u_ringscale * FU;
t_POINT0[0] = sgv_.Pg[0] *     2.0;
t_POINT0[1] = sgv_.Pg[1] *     2.0;
t_POINT0[2] = sgv_.Pg[2] *     2.0;
t_FLOAT1 = stf_fnoisep (t_POINT0);
t_FLOAT2 = u_wavy * t_FLOAT1;
t_FLOAT3 = t_FLOAT0 + t_FLOAT2;
t_FLOAT4 = sin (t_FLOAT3);
t_FLOAT5 = _SQ_abs (t_FLOAT4);
t_FLOAT6 =     1.0 - t_FLOAT5;
t_FLOAT7 = _SQ_clamp (t_FLOAT6,     0.0,     1.0);
t_FLOAT8 = stf_max (u_ringwidth,    0.02);
t_FLOAT9 =     1.0 / t_FLOAT8;
t_FLOAT10 = pow (t_FLOAT7, t_FLOAT9);
RING = t_FLOAT10;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Point t_POINT0;
Point t_POINT1;

t_POINT0[0] =     1.0;
t_POINT0[1] =    0.08;
t_POINT0[2] =     1.0;
t_POINT1[0] = sgv_.Pg[0] * u_grainscale * t_POINT0[0];
t_POINT1[1] = sgv_.Pg[1] * u_grainscale * t_POINT0[1];
t_POINT1[2] = sgv_.Pg[2] * u_grainscale * t_POINT0[2];
t_FLOAT0 = stf_fnoisep (t_POINT1);
t_FLOAT1 = _SQ_clamp (t_FLOAT0,     0.0,     1.0);
t_FLOAT2 = pow (t_FLOAT1,     5.0);
t_FLOAT3 = u_grainy * t_FLOAT2;
GRAIN = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Color t_COLOR0;

t_FLOAT0 = u_plankvary * CELL;
t_FLOAT1 =     1.0 + t_FLOAT0;
t_COLOR0[0] = u_lightwood[0] * t_FLOAT1;
t_COLOR0[1] = u_lightwood[1] * t_FLOAT1;
t_COLOR0[2] = u_lightwood[2] * t_FLOAT1;
WOOD[0] = t_COLOR0[0];
WOOD[1] = t_COLOR0[1];
WOOD[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Color t_COLOR0;

t_FLOAT0 = stf_max (RING, GRAIN);
t_FLOAT1 =     0.5 * t_FLOAT0;
t_FLOAT2 =     1.0 - t_FLOAT1;
t_COLOR0[0] = WOOD[0] * t_FLOAT2;
t_COLOR0[1] = WOOD[1] * t_FLOAT2;
t_COLOR0[2] = WOOD[2] * t_FLOAT2;
WOOD[0] = t_COLOR0[0];
WOOD[1] = t_COLOR0[1];
WOOD[2] = t_COLOR0[2];
}
{
Color t_COLOR0;

stf_mix (t_COLOR0, WOOD, u_groovecolor, GROOVE);
WOOD[0] = t_COLOR0[0];
WOOD[1] = t_COLOR0[1];
WOOD[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;
Point t_POINT3;

t_FLOAT0 = u_km * u_groovedepth * GROOVE;
t_FLOAT1 = u_graindepth * GRAIN;
t_FLOAT2 = t_FLOAT0 + t_FLOAT1;
t_FLOAT3 = FU -     0.5;
t_FLOAT4 = FV -     0.5;
t_POINT0[0] = t_FLOAT3;
t_POINT0[1] =     0.0;
t_POINT0[2] = t_FLOAT4;
t_POINT1[0] = t_FLOAT2 * t_POINT0[0];
t_POINT1[1] = t_FLOAT2 * t_POINT0[1];
t_POINT1[2] = t_FLOAT2 * t_POINT0[2];
t_POINT2[0] = NF[0] - t_POINT1[0];
t_POINT2[1] = NF[1] - t_POINT1[1];
t_POINT2[2] = NF[2] - t_POINT1[2];
stf_normalize (t_POINT3, t_POINT2);
NW[0] = t_POINT3[0];
NW[1] = t_POINT3[1];
NW[2] = t_POINT3[2];
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
t_COLOR7[0] = u_specularcolor[0] * u_ks * t_COLOR6[0];
t_COLOR7[1] = u_specularcolor[1] * u_ks * t_COLOR6[1];
t_COLOR7[2] = u_specularcolor[2] * u_ks * t_COLOR6[2];
t_COLOR8[0] = HITC[0] * u_kr * FRES;
t_COLOR8[1] = HITC[1] * u_kr * FRES;
t_COLOR8[2] = HITC[2] * u_kr * FRES;
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
