// 自動生成: dr_sbcl/interface/glsl.lisp — velvet.lisp から。手で編集しない。
export default {
  name: "velvet",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 0.2 },
    { name: "kd", uniform: "u_kd", type: "float", default: 0.38 },
    { name: "ks", uniform: "u_ks", type: "float", default: 0.15 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.3 },
    { name: "sheen-color", uniform: "u_sheen_color", type: "color", default: [0.85, 0.55, 0.65] },
    { name: "edge-power", uniform: "u_edge_power", type: "float", default: 2.8 },
    { name: "sheen", uniform: "u_sheen", type: "float", default: 2.4 },
    { name: "backscatter", uniform: "u_backscatter", type: "float", default: 0.2 },
    { name: "nap", uniform: "u_nap", type: "float", default: 0.35 },
    { name: "nap-scale", uniform: "u_nap_scale", type: "float", default: 8.0 },
    { name: "body-dark", uniform: "u_body_dark", type: "float", default: 0.5 },
    { name: "sheen-lit", uniform: "u_sheen_lit", type: "float", default: 0.5 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_kd;
uniform float u_ks;
uniform float u_roughness;
uniform vec3 u_sheen_color;
uniform float u_edge_power;
uniform float u_sheen;
uniform float u_backscatter;
uniform float u_nap;
uniform float u_nap_scale;
uniform float u_body_dark;
uniform float u_sheen_lit;
void sl_surface()
{
{
Color SOFT;
Color SHEENC;
Color BACK;
Color BODY;
Color LITRIM;
Color LD;
Float NAPF;
Float NZ;
Float RIM;
Float FRES;
Float FACING;
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

FACING =     0.0;
}
{

FRES =     0.0;
}
{

RIM =     0.0;
}
{

NZ =     0.0;
}
{

NAPF =     1.0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
LD[0] = t_COLOR0[0];
LD[1] = t_COLOR0[1];
LD[2] = t_COLOR0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
LITRIM[0] = t_COLOR0[0];
LITRIM[1] = t_COLOR0[1];
LITRIM[2] = t_COLOR0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
BODY[0] = t_COLOR0[0];
BODY[1] = t_COLOR0[1];
BODY[2] = t_COLOR0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
BACK[0] = t_COLOR0[0];
BACK[1] = t_COLOR0[1];
BACK[2] = t_COLOR0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
SHEENC[0] = t_COLOR0[0];
SHEENC[1] = t_COLOR0[1];
SHEENC[2] = t_COLOR0[2];
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
SOFT[0] = t_COLOR0[0];
SOFT[1] = t_COLOR0[1];
SOFT[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;

t_FLOAT0 = _SQ_dot (NF, IR);
t_FLOAT1 = _SQ_clamp (t_FLOAT0,     0.0,     1.0);
FACING = t_FLOAT1;
}
{
Float t_FLOAT0;

t_FLOAT0 =     1.0 - FACING;
FRES = t_FLOAT0;
}
{
Float t_FLOAT0;

t_FLOAT0 = pow (FRES, u_edge_power);
RIM = t_FLOAT0;
}
{
Float t_FLOAT0;
Point t_POINT0;

t_POINT0[0] = u_nap_scale * sgv_.Pg[0];
t_POINT0[1] = u_nap_scale * sgv_.Pg[1];
t_POINT0[2] = u_nap_scale * sgv_.Pg[2];
t_FLOAT0 = stf_fnoisep (t_POINT0);
NZ = t_FLOAT0;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;

t_FLOAT0 = NZ -     0.5;
t_FLOAT1 = u_nap * t_FLOAT0;
t_FLOAT2 =     1.0 + t_FLOAT1;
NAPF = t_FLOAT2;
}
{
Color t_COLOR0;

stf_diffuse (t_COLOR0, NF);
LD[0] = t_COLOR0[0];
LD[1] = t_COLOR0[1];
LD[2] = t_COLOR0[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Color t_COLOR0;
Color t_COLOR1;
Color t_COLOR2;
Color t_COLOR3;
Color t_COLOR4;

stf_ambient (t_COLOR0);
t_COLOR1[0] = u_ka * t_COLOR0[0];
t_COLOR1[1] = u_ka * t_COLOR0[1];
t_COLOR1[2] = u_ka * t_COLOR0[2];
t_FLOAT0 = u_body_dark * FACING;
t_FLOAT1 =     1.0 - t_FLOAT0;
t_COLOR2[0] = u_kd * LD[0] * NAPF * t_FLOAT1;
t_COLOR2[1] = u_kd * LD[1] * NAPF * t_FLOAT1;
t_COLOR2[2] = u_kd * LD[2] * NAPF * t_FLOAT1;
t_COLOR3[0] = t_COLOR1[0] + t_COLOR2[0];
t_COLOR3[1] = t_COLOR1[1] + t_COLOR2[1];
t_COLOR3[2] = t_COLOR1[2] + t_COLOR2[2];
t_COLOR4[0] = sgv_.Cs[0] * t_COLOR3[0];
t_COLOR4[1] = sgv_.Cs[1] * t_COLOR3[1];
t_COLOR4[2] = sgv_.Cs[2] * t_COLOR3[2];
BODY[0] = t_COLOR4[0];
BODY[1] = t_COLOR4[1];
BODY[2] = t_COLOR4[2];
}
{
Point t_POINT0;
Color t_COLOR0;
Color t_COLOR1;

t_POINT0[0] =  - NF[0];
t_POINT0[1] =  - NF[1];
t_POINT0[2] =  - NF[2];
stf_diffuse (t_COLOR0, t_POINT0);
t_COLOR1[0] = u_backscatter * sgv_.Cs[0] * t_COLOR0[0];
t_COLOR1[1] = u_backscatter * sgv_.Cs[1] * t_COLOR0[1];
t_COLOR1[2] = u_backscatter * sgv_.Cs[2] * t_COLOR0[2];
BACK[0] = t_COLOR1[0];
BACK[1] = t_COLOR1[1];
BACK[2] = t_COLOR1[2];
}
{
Float t_FLOAT0;
Color t_COLOR0;
Color t_COLOR1;
Color t_COLOR2;
Color t_COLOR3;

t_COLOR0[0] = u_sheen_lit * LD[0];
t_COLOR0[1] = u_sheen_lit * LD[1];
t_COLOR0[2] = u_sheen_lit * LD[2];
t_FLOAT0 =     1.0 - u_sheen_lit;
stf_ambient (t_COLOR1);
t_COLOR2[0] = t_FLOAT0 * t_COLOR1[0];
t_COLOR2[1] = t_FLOAT0 * t_COLOR1[1];
t_COLOR2[2] = t_FLOAT0 * t_COLOR1[2];
t_COLOR3[0] = t_COLOR0[0] + t_COLOR2[0];
t_COLOR3[1] = t_COLOR0[1] + t_COLOR2[1];
t_COLOR3[2] = t_COLOR0[2] + t_COLOR2[2];
LITRIM[0] = t_COLOR3[0];
LITRIM[1] = t_COLOR3[1];
LITRIM[2] = t_COLOR3[2];
}
{
Color t_COLOR0;

t_COLOR0[0] = u_sheen_color[0] * u_sheen * RIM * NAPF * LITRIM[0];
t_COLOR0[1] = u_sheen_color[1] * u_sheen * RIM * NAPF * LITRIM[1];
t_COLOR0[2] = u_sheen_color[2] * u_sheen * RIM * NAPF * LITRIM[2];
SHEENC[0] = t_COLOR0[0];
SHEENC[1] = t_COLOR0[1];
SHEENC[2] = t_COLOR0[2];
}
{
Color t_COLOR0;
Color t_COLOR1;

stf_specular (t_COLOR0, NF, IR, u_roughness);
t_COLOR1[0] = u_ks * u_sheen_color[0] * t_COLOR0[0];
t_COLOR1[1] = u_ks * u_sheen_color[1] * t_COLOR0[1];
t_COLOR1[2] = u_ks * u_sheen_color[2] * t_COLOR0[2];
SOFT[0] = t_COLOR1[0];
SOFT[1] = t_COLOR1[1];
SOFT[2] = t_COLOR1[2];
}
{

sgv_.Oi[0] = sgv_.Os[0];
sgv_.Oi[1] = sgv_.Os[1];
sgv_.Oi[2] = sgv_.Os[2];
}
{
Color t_COLOR0;
Color t_COLOR1;

t_COLOR0[0] = BODY[0] + BACK[0] + SHEENC[0] + SOFT[0];
t_COLOR0[1] = BODY[1] + BACK[1] + SHEENC[1] + SOFT[1];
t_COLOR0[2] = BODY[2] + BACK[2] + SHEENC[2] + SOFT[2];
t_COLOR1[0] = sgv_.Oi[0] * t_COLOR0[0];
t_COLOR1[1] = sgv_.Oi[1] * t_COLOR0[1];
t_COLOR1[2] = sgv_.Oi[2] * t_COLOR0[2];
sgv_.Ci[0] = t_COLOR1[0];
sgv_.Ci[1] = t_COLOR1[1];
sgv_.Ci[2] = t_COLOR1[2];
}
}
}
`
};
