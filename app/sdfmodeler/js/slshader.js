/* .lisp シェーダー (dr_sbcl の GLSL バックエンドが出す <name>.sl.js) を
   sdfmodeler のレイマーチ shade() に組み込む。object の
     (surface ... (shader marble) (param texture-scale 2.5) ...)
   をプレビューにも出すため。sl_runtime.js (Three.js 用) の前置き GLSL を
   serve.py 経由で取り、uniform を const / #define に置き換えて使う。
   影・環境 (trace) は無し (縮退)。ライトは sdfmodeler の uLightPos/uLightCol/uNLights をそのまま使う。 */

const SL_MAX = 4;   /* sdfmodeler のライト上限 (uLightPos[4]) */
const st = { prelude: null, preludeErr: null, mods: new Map() /* name → mod | null(失敗) */, errors: [] };

export function parseSlSurface(text) {
  const m = /\(shader\s+([A-Za-z0-9_\-]+)\s*\)/.exec(text || '');
  if (!m) return null;
  const params = {};
  for (const p of (text.matchAll(/\(param\s+([^\s()]+)((?:\s+[-\d.eE+]+)+)\s*\)/g)))
    params[p[1]] = p[2].trim().split(/\s+/).map(Number);
  const generic = {};
  for (const k of ['ka', 'kd', 'ks']) {
    const g = new RegExp('\\(' + k + '\\s+([-\\d.eE+]+)\\s*\\)').exec(text);
    if (g) generic[k] = +g[1];
  }
  return { shader: m[1], params, generic };
}

/* 未取得のシェーダー名 (取得失敗も null で記録済み → 再試行しない) */
export function slMissing(doc) {
  const names = new Set();
  for (const o of doc.objects || []) {
    const s = o.visible && parseSlSurface(o.surface);
    if (s && !st.mods.has(s.shader)) names.add(s.shader);
  }
  return [...names];
}
export function slAnyUsed(doc) {
  return (doc.objects || []).some(o => o.visible && parseSlSurface(o.surface));
}
export function slErrors() { return st.errors.slice(); }

/* 戻り値: 新しく何かを取り込んだか */
export async function slLoad(doc) {
  const names = slMissing(doc);
  if (!names.length) return false;
  if (!st.prelude && !st.preludeErr) {
    try {
      const r = await fetch('/__slprelude__');
      if (!r.ok) throw new Error((await r.json()).error || r.status);
      st.prelude = transformPrelude(await r.text());
    } catch (e) {
      st.preludeErr = String(e.message || e);
      st.errors.push('シェーダー前置きを取得できません: ' + st.preludeErr);
    }
  }
  await Promise.all(names.map(async n => {
    try {
      if (!st.prelude) throw new Error('prelude なし');
      const r = await fetch('/__slgen__/' + encodeURIComponent(n));
      if (!r.ok) throw new Error((await r.json()).error || r.status);
      const src = await r.text();
      const url = URL.createObjectURL(new Blob([src], { type: 'text/javascript' }));
      try { st.mods.set(n, (await import(url)).default); } finally { URL.revokeObjectURL(url); }
    } catch (e) {
      st.mods.set(n, null);
      st.errors.push(`shader ${n}: ${e.message || e}`);
    }
  }));
  return true;
}

function transformPrelude(raw) {
  let s = raw.replace(/\$\{MAX_LIGHTS\}/g, String(SL_MAX));
  s = s.replace(/^uniform [^\n]*$/gm, '');
  const a = s.indexOf('// ── 影');
  const b = s.indexOf('void stf_trace');
  if (a < 0 || b < a) throw new Error('prelude の形式が想定外 (影セクションが見つからない)');
  s = s.slice(0, a) + 'float sl_vis(int i){ return 1.0; }\n' + s.slice(b);
  s = s.replace(/texture\(sl_env, dir\)\.rgb \* sl_envGain/g, 'sl_envColor');
  const head = `
#define sl_nLights uNLights
#define sl_lightPos uLightPos
#define sl_lightCol uLightCol
const vec3 sl_ambient = vec3(0.15);
const float sl_diffClamp = 1.0;
const bool sl_hasEnv = false;
const vec3 sl_envColor = vec3(0.0);
const mat3 sl_ssR = mat3(1.0);
const vec3 sl_ssO = vec3(0.0);
`;
  return head + s;
}

const f = v => { const t = String(+v); return /[.eE]|Infinity|NaN/.test(t) ? t : t + '.0'; };

function bakeShader(mod, sl, k) {
  const given = sl.params;
  let g = mod.glsl.replace(/^uniform\s+(\w+)\s+(u_\w+)\s*;[ \t]*$/gm, (_m, type, uname) => {
    const p = (mod.params || []).find(q => q.uniform === uname);
    if (!p) throw new Error('未知の uniform ' + uname);
    let v = given[p.name];
    if (v == null) {
      const gk = p.name.toLowerCase();
      if (sl.generic[gk] != null) v = [sl.generic[gk]];
    }
    if (v == null) v = Array.isArray(p.default) ? p.default : [p.default];
    if (type === 'float') return `const float ${uname} = ${f(v[0])};`;
    if (type === 'vec3') {
      if (v.length === 1) v = [v[0], v[0], v[0]];
      return `const vec3 ${uname} = vec3(${v.slice(0, 3).map(f).join(', ')});`;
    }
    throw new Error(`${mod.name}: ${type} 型の param (${p.name}) は未対応`);
  });
  g = g.replace(/\bsl_surface\b/g, `sl_surface_${k}`).replace(/\bu_(\w+)/g, `u${k}_$1`);
  return `${g}
vec3 slshade_${k}(vec3 P, vec3 N, vec3 I, vec3 Cs){
  sgv_.P = P; sgv_.Po = P; sgv_.Pg = P; sgv_.N = N; sgv_.Ng = N; sgv_.I = I; sgv_.E = uCamPos;
  sgv_.s = atan(N.z, N.x) / 6.28318530718 + 0.5;
  sgv_.t = acos(clamp(N.y, -1.0, 1.0)) / 3.14159265359;
  sgv_.u = 0.0; sgv_.v = 0.0;
  vec3 aN = abs(N);
  vec3 ax = aN.x < aN.y && aN.x < aN.z ? vec3(1,0,0) : (aN.y < aN.z ? vec3(0,1,0) : vec3(0,0,1));
  sgv_.dPdu = normalize(cross(ax, N)); sgv_.dPdv = cross(N, sgv_.dPdu);
  sgv_.Cs = Cs; sgv_.Os = vec3(1.0);
  sgv_.Ci = vec3(0.0); sgv_.Oi = vec3(1.0);
  sgv_.L = vec3(0.0); sgv_.Cl = vec3(0.0);
  sgv_.pi = 3.14159265358979; sgv_.ncomps = 3.0; sgv_.alpha = 1.0; sgv_.dispOut = 0.0;
  sl_surface_${k}();
  return clamp(sgv_.Ci, 0.0, 1.0);
}
`;
}

/* visObjs: codegen の描画対象 object 配列 (index = shade() の m)。
   戻り値: decl (shade() の前に置く GLSL) / cases (shade() 内で alb 決定後に置く) / warn */
export function slGlsl(visObjs) {
  const out = { decl: '', cases: '', warn: [] };
  if (!st.prelude) return out;
  const copies = new Map();
  let k = 0;
  const parts = [];
  visObjs.forEach((o, i) => {
    const sl = parseSlSurface(o.surface);
    if (!sl) return;
    const mod = st.mods.get(sl.shader);
    if (!mod) { out.warn.push(`shader ${sl.shader}: 使えない`); return; }
    const key = sl.shader + JSON.stringify([sl.params, sl.generic]);
    if (!copies.has(key)) {
      try { parts.push(bakeShader(mod, sl, k)); copies.set(key, k++); }
      catch (e) { out.warn.push(String(e.message || e)); return; }
    }
    out.cases += `  if (uPartOn < 0.5 && m < 97.5 && int(m + 0.5) == ${i}) return slshade_${copies.get(key)}(p, n, rd, uObjCol[${i}]);\n`;
  });
  if (parts.length) out.decl = st.prelude + '\n' + parts.join('\n');
  else out.cases = '';
  return out;
}
