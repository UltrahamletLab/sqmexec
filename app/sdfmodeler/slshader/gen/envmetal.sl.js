// 自動生成: dr_sbcl/interface/glsl.lisp — envmetal.lisp から。手で編集しない。
export default {
  name: "envmetal",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 1.0 },
    { name: "ks", uniform: "u_ks", type: "float", default: 1.0 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.02 },
    { name: "intensity", uniform: "u_intensity", type: "float", default: 0.5 },
    { name: "angle", uniform: "u_angle", type: "float", default: 0.0 },
    { name: "map-name", uniform: "u_map_name", type: "string", default: "" },
  ],
  glsl: `
uniform float u_ka;
uniform float u_ks;
uniform float u_roughness;
uniform float u_intensity;
uniform float u_angle;
uniform int u_map_name;
void sl_surface()
{
{
Color EV;
Float RAD;
Point NI;
Point NF;
Point DIRECTION;
Point TEMP;
{
Point t_POINT0;
Point t_POINT1;
Point t_POINT2;

stf_normalize (t_POINT0, sgv_.N);
stf_faceforward (t_POINT1, t_POINT0, sgv_.I);
stf_reflect (t_POINT2, sgv_.I, t_POINT1);
DIRECTION[0] = t_POINT2[0];
DIRECTION[1] = t_POINT2[1];
DIRECTION[2] = t_POINT2[2];
}
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

stf_normalize (t_POINT0, sgv_.I);
NI[0] = t_POINT0[0];
NI[1] = t_POINT0[1];
NI[2] = t_POINT0[2];
}
{
Float t_FLOAT0;

t_FLOAT0 = _SQ_radians (u_angle);
RAD = t_FLOAT0;
}
{
Color t_COLOR0;

stf_makecolor (t_COLOR0,     0.0,     0.0,     0.0);
EV[0] = t_COLOR0[0];
EV[1] = t_COLOR0[1];
EV[2] = t_COLOR0[2];
}
{

TEMP[0] = DIRECTION[0];
TEMP[1] = DIRECTION[1];
TEMP[2] = DIRECTION[2];
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Float t_FLOAT6;

t_FLOAT0 = _SQ_xcomp (TEMP);
t_FLOAT1 = cos (RAD);
t_FLOAT2 = t_FLOAT0 * t_FLOAT1;
t_FLOAT3 = _SQ_zcomp (TEMP);
t_FLOAT4 = sin (RAD);
t_FLOAT5 = t_FLOAT3 * t_FLOAT4;
t_FLOAT6 = t_FLOAT2 - t_FLOAT5;
DIRECTION[0] = t_FLOAT6;
}
{
Float t_FLOAT0;
Float t_FLOAT1;
Float t_FLOAT2;
Float t_FLOAT3;
Float t_FLOAT4;
Float t_FLOAT5;
Float t_FLOAT6;

t_FLOAT0 = _SQ_xcomp (TEMP);
t_FLOAT1 = sin (RAD);
t_FLOAT2 = t_FLOAT0 * t_FLOAT1;
t_FLOAT3 = _SQ_zcomp (TEMP);
t_FLOAT4 = cos (RAD);
t_FLOAT5 = t_FLOAT3 * t_FLOAT4;
t_FLOAT6 = t_FLOAT2 + t_FLOAT5;
DIRECTION[2] = t_FLOAT6;
}
{
Color t_COLOR0;

stf_environment (t_COLOR0, u_map_name, DIRECTION);
EV[0] = t_COLOR0[0];
EV[1] = t_COLOR0[1];
EV[2] = t_COLOR0[2];
}
{

sgv_.Oi[0] = sgv_.Os[0];
sgv_.Oi[1] = sgv_.Os[1];
sgv_.Oi[2] = sgv_.Os[2];
}
{
Point t_POINT0;
Color t_COLOR0;
Color t_COLOR1;
Color t_COLOR2;
Color t_COLOR3;
Color t_COLOR4;
Color t_COLOR5;
Color t_COLOR6;
Color t_COLOR7;

stf_ambient (t_COLOR0);
t_COLOR1[0] = u_ka * t_COLOR0[0];
t_COLOR1[1] = u_ka * t_COLOR0[1];
t_COLOR1[2] = u_ka * t_COLOR0[2];
t_COLOR2[0] = EV[0] * u_intensity;
t_COLOR2[1] = EV[1] * u_intensity;
t_COLOR2[2] = EV[2] * u_intensity;
t_POINT0[0] =  - NI[0];
t_POINT0[1] =  - NI[1];
t_POINT0[2] =  - NI[2];
stf_specular (t_COLOR3, NF, t_POINT0, u_roughness);
t_COLOR4[0] = t_COLOR2[0] + t_COLOR3[0];
t_COLOR4[1] = t_COLOR2[1] + t_COLOR3[1];
t_COLOR4[2] = t_COLOR2[2] + t_COLOR3[2];
t_COLOR5[0] = u_ks * t_COLOR4[0];
t_COLOR5[1] = u_ks * t_COLOR4[1];
t_COLOR5[2] = u_ks * t_COLOR4[2];
t_COLOR6[0] = t_COLOR1[0] + t_COLOR5[0];
t_COLOR6[1] = t_COLOR1[1] + t_COLOR5[1];
t_COLOR6[2] = t_COLOR1[2] + t_COLOR5[2];
t_COLOR7[0] = sgv_.Os[0] * sgv_.Cs[0] * t_COLOR6[0];
t_COLOR7[1] = sgv_.Os[1] * sgv_.Cs[1] * t_COLOR6[1];
t_COLOR7[2] = sgv_.Os[2] * sgv_.Cs[2] * t_COLOR6[2];
sgv_.Ci[0] = t_COLOR7[0];
sgv_.Ci[1] = t_COLOR7[1];
sgv_.Ci[2] = t_COLOR7[2];
}
}
}
`
};
