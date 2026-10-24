// 自動生成: dr_sbcl/interface/glsl.lisp — ceramictilesdisp.lisp から。手で編集しない。
export default {
  name: "ceramictilesdisp",
  keyword: "displacement",
  fn: "sl_disp_ceramictilesdisp",
  params: [
    { name: "stilespacing", uniform: "u_ceramictilesdisp_stilespacing", type: "float", default: 1.0 },
    { name: "ttilespacing", uniform: "u_ceramictilesdisp_ttilespacing", type: "float", default: 1.0 },
    { name: "axis", uniform: "u_ceramictilesdisp_axis", type: "float", default: 2.0 },
  ],
  glsl: `
uniform float u_ceramictilesdisp_stilespacing;
uniform float u_ceramictilesdisp_ttilespacing;
uniform float u_ceramictilesdisp_axis;
float sl_disp_ceramictilesdisp(vec3 P)
{
vec3 sl_P_ = sgv_.P; sgv_.P = P; sgv_.dispOut = 0.0;

{
Float H;
Float TTL;
Float STL;
Float TV;
Float SU;
{

SU =     0.0;
}
{

TV =     0.0;
}
{

STL =     0.0;
}
{

TTL =     0.0;
}
{

H =     0.0;
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_xcomp (sgv_.P);
SU = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_ycomp (sgv_.P);
TV = t_FLOAT0;
}
{

if ((true && (u_ceramictilesdisp_axis <     0.5))) {
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_zcomp (sgv_.P);
SU = t_FLOAT0;
}
}
}
{

if ((true && (true && (u_ceramictilesdisp_axis >     0.5)) && (true && (u_ceramictilesdisp_axis <     1.5)))) {
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_zcomp (sgv_.P);
TV = t_FLOAT0;
}
}
}
{
Float t_FLOAT0;

t_FLOAT0 = SU / u_ceramictilesdisp_stilespacing;
SU = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = TV / u_ceramictilesdisp_ttilespacing;
TV = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = floor (SU);
t_FLOAT1 = SU - t_FLOAT0;
STL = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = floor (TV);
t_FLOAT1 = TV - t_FLOAT0;
TTL = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Float t_FLOAT6;

t_FLOAT0 = _SQ_smoothstep (    0.0,   0.075, STL);
t_FLOAT1 = _SQ_smoothstep (  0.925,     1.0, STL);
t_FLOAT2 = t_FLOAT0 - t_FLOAT1;
t_FLOAT3 = _SQ_smoothstep (    0.0,   0.075, TTL);
t_FLOAT4 = _SQ_smoothstep (  0.925,     1.0, TTL);
t_FLOAT5 = t_FLOAT3 - t_FLOAT4;
t_FLOAT6 = t_FLOAT2 * t_FLOAT5;
H = t_FLOAT6;
}
{

sgv_.dispOut = H;
}
}

float sl_h_ = sgv_.dispOut; sgv_.P = sl_P_; return sl_h_;
}
`
};
