// 自動生成: dr_sbcl/interface/glsl.lisp — celldots.lisp から。手で編集しない。
export default {
  name: "celldots",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 0.2 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.8 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.4 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.1 },
    { name: "freq", uniform: "u_freq", type: "float", default: 6.0 },
    { name: "dot-radius", uniform: "u_dot_radius", type: "float", default: 0.32 },
    { name: "blur", uniform: "u_blur", type: "float", default: 0.06 },
    { name: "base-color", uniform: "u_base_color", type: "color", default: [0.92, 0.88, 0.8] },
    { name: "dot-color", uniform: "u_dot_color", type: "color", default: [0.75, 0.15, 0.12] },
    { name: "dot-color2", uniform: "u_dot_color2", type: "color", default: [0.15, 0.3, 0.65] },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_roughness;
uniform float u_freq;
uniform float u_dot_radius;
uniform float u_blur;
uniform vec3 u_base_color;
uniform vec3 u_dot_color;
uniform vec3 u_dot_color2;
void sl_surface()
{
{
Color SURF;
Color TINT;
Float DSEL;
Float DD;
Point CELLC;
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
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     0.0;
PP[0] = t_POINT0[0];
PP[1] = t_POINT0[1];
PP[2] = t_POINT0[2];
}
{
Point t_POINT0;

t_POINT0[0] =     0.0;
t_POINT0[1] =     0.0;
t_POINT0[2] =     0.0;
CELLC[0] = t_POINT0[0];
CELLC[1] = t_POINT0[1];
CELLC[2] = t_POINT0[2];
}
{

DD =     0.0;
}
{

DSEL =     0.0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
TINT[0] = t_COLOR0[0];
TINT[1] = t_COLOR0[1];
TINT[2] = t_COLOR0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
SURF[0] = t_COLOR0[0];
SURF[1] = t_COLOR0[1];
SURF[2] = t_COLOR0[2];
}
{
Point t_POINT0;

t_POINT0[0] = u_freq * sgv_.Pg[0];
t_POINT0[1] = u_freq * sgv_.Pg[1];
t_POINT0[2] = u_freq * sgv_.Pg[2];
PP[0] = t_POINT0[0];
PP[1] = t_POINT0[1];
PP[2] = t_POINT0[2];
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

t_FLOAT0 = _SQ_xcomp (PP);
t_FLOAT1 = floor (t_FLOAT0);
t_FLOAT2 = t_FLOAT1 +     0.5;
t_FLOAT3 = _SQ_ycomp (PP);
t_FLOAT4 = floor (t_FLOAT3);
t_FLOAT5 = t_FLOAT4 +     0.5;
t_FLOAT6 = _SQ_zcomp (PP);
t_FLOAT7 = floor (t_FLOAT6);
t_FLOAT8 = t_FLOAT7 +     0.5;
t_POINT0[0] = t_FLOAT2;
t_POINT0[1] = t_FLOAT5;
t_POINT0[2] = t_FLOAT8;
CELLC[0] = t_POINT0[0];
CELLC[1] = t_POINT0[1];
CELLC[2] = t_POINT0[2];
}
{
Float t_FLOAT0;
Point t_POINT0;

t_POINT0[0] = PP[0] - CELLC[0];
t_POINT0[1] = PP[1] - CELLC[1];
t_POINT0[2] = PP[2] - CELLC[2];
t_FLOAT0 = _SQ_length (t_POINT0);
DD = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 = u_dot_radius - u_blur;
t_FLOAT1 = _SQ_smoothstep (t_FLOAT0, u_dot_radius, DD);
t_FLOAT2 =     1.0 - t_FLOAT1;
DSEL = t_FLOAT2;
}
{
Float t_FLOAT0;
Color t_COLOR0;

t_FLOAT0 = stf_vnoise (CELLC);
stf_mix (t_COLOR0, u_dot_color, u_dot_color2, t_FLOAT0);
TINT[0] = t_COLOR0[0];
TINT[1] = t_COLOR0[1];
TINT[2] = t_COLOR0[2];
}
{
Color t_COLOR0;

stf_mix (t_COLOR0, u_base_color, TINT, DSEL);
SURF[0] = t_COLOR0[0];
SURF[1] = t_COLOR0[1];
SURF[2] = t_COLOR0[2];
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
t_COLOR5[0] = SURF[0] * t_COLOR4[0];
t_COLOR5[1] = SURF[1] * t_COLOR4[1];
t_COLOR5[2] = SURF[2] * t_COLOR4[2];
stf_specular (t_COLOR6, NF, IR, u_roughness);
t_COLOR7[0] = u_ks * t_COLOR6[0];
t_COLOR7[1] = u_ks * t_COLOR6[1];
t_COLOR7[2] = u_ks * t_COLOR6[2];
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
