// 自動生成: dr_sbcl/interface/glsl.lisp — constant.lisp から。手で編集しない。
export default {
  name: "constant",
  keyword: "surface",
  params: [
  ],
  glsl: `
void sl_surface()
{
{
{

sgv_.Oi[0] = sgv_.Os[0];
sgv_.Oi[1] = sgv_.Os[1];
sgv_.Oi[2] = sgv_.Os[2];
}
{
Color t_COLOR0;

t_COLOR0[0] = sgv_.Os[0] * sgv_.Cs[0];
t_COLOR0[1] = sgv_.Os[1] * sgv_.Cs[1];
t_COLOR0[2] = sgv_.Os[2] * sgv_.Cs[2];
sgv_.Ci[0] = t_COLOR0[0];
sgv_.Ci[1] = t_COLOR0[1];
sgv_.Ci[2] = t_COLOR0[2];
}
}
}
`
};
