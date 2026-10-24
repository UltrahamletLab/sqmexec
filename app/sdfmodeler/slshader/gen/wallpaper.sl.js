// 自動生成: dr_sbcl/interface/glsl.lisp — wallpaper.lisp から。手で編集しない。
export default {
  name: "wallpaper",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 0.3 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.8 },
    { name: "base-color", uniform: "u_base_color", type: "color", default: [0.93, 0.89, 0.8] },
    { name: "stripe-color", uniform: "u_stripe_color", type: "color", default: [0.88, 0.76, 0.74] },
    { name: "stripe-width", uniform: "u_stripe_width", type: "float", default: 0.85 },
    { name: "stripe-soft", uniform: "u_stripe_soft", type: "float", default: 0.05 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform vec3 u_base_color;
uniform vec3 u_stripe_color;
uniform float u_stripe_width;
uniform float u_stripe_soft;
void sl_surface()
{
{
Color COL;
Float BAND;
Float FF;
Float UU;
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

UU =     0.0;
}
{

FF =     0.0;
}
{

BAND =     0.0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
COL[0] = t_COLOR0[0];
COL[1] = t_COLOR0[1];
COL[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;

t_FLOAT0 = _SQ_xcomp (sgv_.Pg);
t_FLOAT1 = _SQ_zcomp (sgv_.Pg);
t_FLOAT2 = t_FLOAT0 + t_FLOAT1;
t_FLOAT3 = t_FLOAT2 / u_stripe_width;
UU = t_FLOAT3;
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = floor (UU);
t_FLOAT1 = UU - t_FLOAT0;
FF = t_FLOAT1;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;

t_FLOAT0 =    0.25 - u_stripe_soft;
t_FLOAT1 =    0.25 + u_stripe_soft;
t_FLOAT2 = FF -     0.5;
t_FLOAT3 = _SQ_abs (t_FLOAT2);
t_FLOAT4 = _SQ_smoothstep (t_FLOAT0, t_FLOAT1, t_FLOAT3);
BAND = t_FLOAT4;
}
{
Color t_COLOR0;

stf_mix (t_COLOR0, u_base_color, u_stripe_color, BAND);
COL[0] = t_COLOR0[0];
COL[1] = t_COLOR0[1];
COL[2] = t_COLOR0[2];
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
t_COLOR5[0] = COL[0] * t_COLOR4[0];
t_COLOR5[1] = COL[1] * t_COLOR4[1];
t_COLOR5[2] = COL[2] * t_COLOR4[2];
t_COLOR6[0] = sgv_.Oi[0] * t_COLOR5[0];
t_COLOR6[1] = sgv_.Oi[1] * t_COLOR5[1];
t_COLOR6[2] = sgv_.Oi[2] * t_COLOR5[2];
sgv_.Ci[0] = t_COLOR6[0];
sgv_.Ci[1] = t_COLOR6[1];
sgv_.Ci[2] = t_COLOR6[2];
}
}
}
`
};
