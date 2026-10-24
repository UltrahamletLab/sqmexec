// 自動生成: dr_sbcl/interface/glsl.lisp — brick.lisp から。手で編集しない。
export default {
  name: "brick",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 1.0 },
    { name: "kd", uniform: "u_kd", type: "float", default: 1.0 },
    { name: "brickcolor", uniform: "u_brickcolor", type: "color", default: [0.6, 0.1, 0.1] },
    { name: "mortarcolor", uniform: "u_mortarcolor", type: "color", default: [0.6, 0.6, 0.6] },
    { name: "raggedamp", uniform: "u_raggedamp", type: "float", default: 0.04 },
    { name: "raggedfreq", uniform: "u_raggedfreq", type: "float", default: 12.0 },
    { name: "jagged", uniform: "u_jagged", type: "float", default: 0.006 },
    { name: "brickvary", uniform: "u_brickvary", type: "float", default: 0.3 },
    { name: "brickwidth", uniform: "u_brickwidth", type: "float", default: 0.28 },
    { name: "brickheight", uniform: "u_brickheight", type: "float", default: 0.07 },
    { name: "mortarthickness", uniform: "u_mortarthickness", type: "float", default: 0.014 },
    { name: "rowvary", uniform: "u_rowvary", type: "float", default: 0.2 },
    { name: "axis", uniform: "u_axis", type: "float", default: 2.0 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform vec3 u_brickcolor;
uniform vec3 u_mortarcolor;
uniform float u_raggedamp;
uniform float u_raggedfreq;
uniform float u_jagged;
uniform float u_brickvary;
uniform float u_brickwidth;
uniform float u_brickheight;
uniform float u_mortarthickness;
uniform float u_rowvary;
uniform float u_axis;
void sl_surface()
{
{
Color CT;
Color BC;
Float H;
Float W;
Float FZ;
Float WB;
Float TT;
Float SS;
Float TB;
Float SB;
Float JY;
Float JX;
Float Q;
Float ROW;
Float YT;
Float XT;
Float TC0;
Float SC0;
Float TC;
Float SC;
Float MHF;
Float MWF;
Float BMH;
Float BMW;
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
Float t_FLOAT0;

t_FLOAT0 = u_brickwidth + u_mortarthickness;
BMW = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = u_brickheight + u_mortarthickness;
BMH = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 = u_mortarthickness *     0.5;
t_FLOAT1 = u_brickwidth + u_mortarthickness;
t_FLOAT2 = t_FLOAT0 / t_FLOAT1;
MWF = t_FLOAT2;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 = u_mortarthickness *     0.5;
t_FLOAT1 = u_brickheight + u_mortarthickness;
t_FLOAT2 = t_FLOAT0 / t_FLOAT1;
MHF = t_FLOAT2;
}
{

SC =     0.0;
}
{

TC =     0.0;
}
{

SC0 =     0.0;
}
{

TC0 =     0.0;
}
{

XT =     0.0;
}
{

YT =     0.0;
}
{

ROW =     0.0;
}
{

Q =     0.0;
}
{

JX =     0.0;
}
{

JY =     0.0;
}
{

SB =     0.0;
}
{

TB =     0.0;
}
{

SS =     0.0;
}
{

TT =     0.0;
}
{

WB =     0.0;
}
{

FZ =    0.02;
}
{

W =     0.0;
}
{

H =     0.0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
BC[0] = t_COLOR0[0];
BC[1] = t_COLOR0[1];
BC[2] = t_COLOR0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
CT[0] = t_COLOR0[0];
CT[1] = t_COLOR0[1];
CT[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_xcomp (sgv_.Pg);
SC = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_ycomp (sgv_.Pg);
TC = t_FLOAT0;
}
{

if ((true && (u_axis <     0.5))) {
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_zcomp (sgv_.Pg);
SC = t_FLOAT0;
}
}
}
{

if ((true && (true && (u_axis >     0.5)) && (true && (u_axis <     1.5)))) {
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_zcomp (sgv_.Pg);
TC = t_FLOAT0;
}
}
}
{

SC0 = SC;
}
{

TC0 = TC;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Point t_POINT0;

t_FLOAT0 = SC / BMW;
t_FLOAT1 = TC / BMH;
t_POINT0[0] = t_FLOAT0;
t_POINT0[1] = t_FLOAT1;
t_POINT0[2] =     0.0;
t_FLOAT2 = stf_fnoisep (t_POINT0);
JX = t_FLOAT2;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Point t_POINT0;

t_FLOAT0 = SC / BMW;
t_FLOAT1 = t_FLOAT0 +    17.3;
t_FLOAT2 = TC / BMH;
t_POINT0[0] = t_FLOAT1;
t_POINT0[1] = t_FLOAT2;
t_POINT0[2] =     0.0;
t_FLOAT3 = stf_fnoisep (t_POINT0);
JY = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = u_jagged * JX;
t_FLOAT1 = SC + t_FLOAT0;
SC = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = u_jagged * JY;
t_FLOAT1 = TC + t_FLOAT0;
TC = t_FLOAT1;
}
{
Float t_FLOAT0;

t_FLOAT0 = SC / BMW;
XT = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = TC / BMH;
YT = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = floor (YT);
ROW = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 =     0.5 * ROW;
Q = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 = floor (Q);
t_FLOAT1 = Q - t_FLOAT0;
t_FLOAT2 = XT + t_FLOAT1;
XT = t_FLOAT2;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;

t_FLOAT0 = ROW +     0.5;
t_FLOAT1 = stf_fnoisef (t_FLOAT0);
t_FLOAT2 = t_FLOAT1 -     0.5;
t_FLOAT3 = u_rowvary * t_FLOAT2;
t_FLOAT4 = XT + t_FLOAT3;
XT = t_FLOAT4;
}
{
Float t_FLOAT0;

t_FLOAT0 = floor (XT);
SB = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = XT - SB;
SS = t_FLOAT0;
}
{

TB = ROW;
}
{
Float t_FLOAT0;

t_FLOAT0 = YT - ROW;
TT = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 =   103.0 * SB;
t_FLOAT1 = t_FLOAT0 + TB;
WB = t_FLOAT1;
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

t_FLOAT0 = TB *    5.15;
t_FLOAT1 = SC0 + t_FLOAT0;
t_FLOAT2 = t_FLOAT1 * u_raggedfreq;
t_FLOAT3 = SB *    23.8;
t_FLOAT4 = TC0 + t_FLOAT3;
t_FLOAT5 = t_FLOAT4 * u_raggedfreq;
t_POINT0[0] = t_FLOAT2;
t_POINT0[1] = t_FLOAT5;
t_POINT0[2] =     0.0;
t_FLOAT6 = stf_fnoisep (t_POINT0);
t_FLOAT7 =     2.0 * t_FLOAT6;
t_FLOAT8 = t_FLOAT7 -     1.0;
t_FLOAT9 = u_raggedamp * t_FLOAT8;
t_FLOAT10 = SS + t_FLOAT9;
SS = t_FLOAT10;
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

t_FLOAT0 = TB *    11.4;
t_FLOAT1 = SC0 + t_FLOAT0;
t_FLOAT2 = t_FLOAT1 * u_raggedfreq;
t_FLOAT3 = SB *     7.2;
t_FLOAT4 = TC0 + t_FLOAT3;
t_FLOAT5 = t_FLOAT4 * u_raggedfreq;
t_POINT0[0] = t_FLOAT2;
t_POINT0[1] = t_FLOAT5;
t_POINT0[2] =     0.0;
t_FLOAT6 = stf_fnoisep (t_POINT0);
t_FLOAT7 =     2.0 * t_FLOAT6;
t_FLOAT8 = t_FLOAT7 -     1.0;
t_FLOAT9 = u_raggedamp * t_FLOAT8;
t_FLOAT10 = TT + t_FLOAT9;
TT = t_FLOAT10;
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
Float t_FLOAT11;
Float t_FLOAT12;
Float t_FLOAT13;
Point t_POINT0;

t_FLOAT0 = u_raggedamp *     0.5;
t_FLOAT1 = TB *    5.15;
t_FLOAT2 = SC0 + t_FLOAT1;
t_FLOAT3 = u_raggedfreq *     2.0;
t_FLOAT4 = t_FLOAT2 * t_FLOAT3;
t_FLOAT5 = SB *    23.8;
t_FLOAT6 = TC0 + t_FLOAT5;
t_FLOAT7 = u_raggedfreq *     2.0;
t_FLOAT8 = t_FLOAT6 * t_FLOAT7;
t_POINT0[0] = t_FLOAT4;
t_POINT0[1] = t_FLOAT8;
t_POINT0[2] =     0.0;
t_FLOAT9 = stf_fnoisep (t_POINT0);
t_FLOAT10 =     2.0 * t_FLOAT9;
t_FLOAT11 = t_FLOAT10 -     1.0;
t_FLOAT12 = t_FLOAT0 * t_FLOAT11;
t_FLOAT13 = SS + t_FLOAT12;
SS = t_FLOAT13;
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
Float t_FLOAT11;
Float t_FLOAT12;
Float t_FLOAT13;
Point t_POINT0;

t_FLOAT0 = u_raggedamp *     0.5;
t_FLOAT1 = TB *    11.4;
t_FLOAT2 = SC0 + t_FLOAT1;
t_FLOAT3 = u_raggedfreq *     2.0;
t_FLOAT4 = t_FLOAT2 * t_FLOAT3;
t_FLOAT5 = SB *     7.2;
t_FLOAT6 = TC0 + t_FLOAT5;
t_FLOAT7 = u_raggedfreq *     2.0;
t_FLOAT8 = t_FLOAT6 * t_FLOAT7;
t_POINT0[0] = t_FLOAT4;
t_POINT0[1] = t_FLOAT8;
t_POINT0[2] =     0.0;
t_FLOAT9 = stf_fnoisep (t_POINT0);
t_FLOAT10 =     2.0 * t_FLOAT9;
t_FLOAT11 = t_FLOAT10 -     1.0;
t_FLOAT12 = t_FLOAT0 * t_FLOAT11;
t_FLOAT13 = TT + t_FLOAT12;
TT = t_FLOAT13;
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

t_FLOAT0 = MWF - FZ;
t_FLOAT1 = MWF + FZ;
t_FLOAT2 = _SQ_smoothstep (t_FLOAT0, t_FLOAT1, SS);
t_FLOAT3 =     1.0 - MWF;
t_FLOAT4 = t_FLOAT3 - FZ;
t_FLOAT5 =     1.0 - MWF;
t_FLOAT6 = t_FLOAT5 + FZ;
t_FLOAT7 = _SQ_smoothstep (t_FLOAT4, t_FLOAT6, SS);
t_FLOAT8 = t_FLOAT2 - t_FLOAT7;
W = t_FLOAT8;
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

t_FLOAT0 = MHF - FZ;
t_FLOAT1 = MHF + FZ;
t_FLOAT2 = _SQ_smoothstep (t_FLOAT0, t_FLOAT1, TT);
t_FLOAT3 =     1.0 - MHF;
t_FLOAT4 = t_FLOAT3 - FZ;
t_FLOAT5 =     1.0 - MHF;
t_FLOAT6 = t_FLOAT5 + FZ;
t_FLOAT7 = _SQ_smoothstep (t_FLOAT4, t_FLOAT6, TT);
t_FLOAT8 = t_FLOAT2 - t_FLOAT7;
H = t_FLOAT8;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Color t_COLOR0;

t_FLOAT0 = WB +     0.5;
t_FLOAT1 = stf_fnoisef (t_FLOAT0);
t_FLOAT2 =     2.0 * t_FLOAT1;
t_FLOAT3 = t_FLOAT2 -     1.0;
t_FLOAT4 = u_brickvary * t_FLOAT3;
t_FLOAT5 =     1.0 + t_FLOAT4;
t_COLOR0[0] = u_brickcolor[0] * t_FLOAT5;
t_COLOR0[1] = u_brickcolor[1] * t_FLOAT5;
t_COLOR0[2] = u_brickcolor[2] * t_FLOAT5;
BC[0] = t_COLOR0[0];
BC[1] = t_COLOR0[1];
BC[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Color t_COLOR0;

t_FLOAT0 = W * H;
stf_mix (t_COLOR0, u_mortarcolor, BC, t_FLOAT0);
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
t_COLOR5[0] = sgv_.Oi[0] * CT[0] * t_COLOR4[0];
t_COLOR5[1] = sgv_.Oi[1] * CT[1] * t_COLOR4[1];
t_COLOR5[2] = sgv_.Oi[2] * CT[2] * t_COLOR4[2];
sgv_.Ci[0] = t_COLOR5[0];
sgv_.Ci[1] = t_COLOR5[1];
sgv_.Ci[2] = t_COLOR5[2];
}
}
}
`
};
