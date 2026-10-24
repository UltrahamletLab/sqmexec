// 自動生成: dr_sbcl/interface/glsl.lisp — metal.lisp から。手で編集しない。
export default {
  name: "metal",
  keyword: "surface",
  params: [
    { name: "ka", uniform: "u_ka", type: "float", default: 1.0 },
    { name: "ks", uniform: "u_ks", type: "float", default: 1.0 },
    { name: "roughness", uniform: "u_roughness", type: "float", default: 0.25 },
  ],
  glsl: `
uniform float u_ka;
uniform float u_ks;
uniform float u_roughness;
void sl_surface()
{
{
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
stf_specular (t_COLOR2, NF, IR, u_roughness);
t_COLOR3[0] = u_ks * t_COLOR2[0];
t_COLOR3[1] = u_ks * t_COLOR2[1];
t_COLOR3[2] = u_ks * t_COLOR2[2];
t_COLOR4[0] = t_COLOR1[0] + t_COLOR3[0];
t_COLOR4[1] = t_COLOR1[1] + t_COLOR3[1];
t_COLOR4[2] = t_COLOR1[2] + t_COLOR3[2];
t_COLOR5[0] = sgv_.Os[0] * sgv_.Cs[0] * t_COLOR4[0];
t_COLOR5[1] = sgv_.Os[1] * sgv_.Cs[1] * t_COLOR4[1];
t_COLOR5[2] = sgv_.Os[2] * sgv_.Cs[2] * t_COLOR4[2];
sgv_.Ci[0] = t_COLOR5[0];
sgv_.Ci[1] = t_COLOR5[1];
sgv_.Ci[2] = t_COLOR5[2];
}
}
}
`
};
