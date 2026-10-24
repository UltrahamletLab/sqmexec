// 自動生成: dr_sbcl/interface/glsl.lisp — axisramp.lisp から。手で編集しない。
export default {
  name: "axisramp",
  keyword: "displacement",
  fn: "sl_disp_axisramp",
  params: [
    { name: "axis", uniform: "u_axisramp_axis", type: "float", default: 0.0 },
    { name: "a0", uniform: "u_axisramp_a0", type: "float", default: 0.0 },
    { name: "a1", uniform: "u_axisramp_a1", type: "float", default: 1.0 },
    { name: "a-amt", uniform: "u_axisramp_a_amt", type: "float", default: 1.0 },
    { name: "b0", uniform: "u_axisramp_b0", type: "float", default: 0.0 },
    { name: "b1", uniform: "u_axisramp_b1", type: "float", default: 1.0 },
    { name: "b-amt", uniform: "u_axisramp_b_amt", type: "float", default: 0.0 },
  ],
  glsl: `
uniform float u_axisramp_axis;
uniform float u_axisramp_a0;
uniform float u_axisramp_a1;
uniform float u_axisramp_a_amt;
uniform float u_axisramp_b0;
uniform float u_axisramp_b1;
uniform float u_axisramp_b_amt;
float sl_disp_axisramp(vec3 P)
{
vec3 sl_P_ = sgv_.P; sgv_.P = P; sgv_.dispOut = 0.0;

{
Float H;
Float Q;
{

Q =     0.0;
}
{

H =     0.0;
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_xcomp (sgv_.P);
Q = t_FLOAT0;
}
{

if ((true && (u_axisramp_axis >     0.5))) {
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_ycomp (sgv_.P);
Q = t_FLOAT0;
}
}
}
{

if ((true && (u_axisramp_axis >     1.5))) {
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_zcomp (sgv_.P);
Q = t_FLOAT0;
}
}
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;

t_FLOAT0 = _SQ_smoothstep (u_axisramp_a0, u_axisramp_a1, Q);
t_FLOAT1 = u_axisramp_a_amt * t_FLOAT0;
t_FLOAT2 = _SQ_smoothstep (u_axisramp_b0, u_axisramp_b1, Q);
t_FLOAT3 = u_axisramp_b_amt * t_FLOAT2;
t_FLOAT4 = t_FLOAT1 + t_FLOAT3;
H = t_FLOAT4;
}
{

sgv_.dispOut = H;
}
}

float sl_h_ = sgv_.dispOut; sgv_.P = sl_P_; return sl_h_;
}
`
};
