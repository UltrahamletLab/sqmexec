#!/usr/bin/env bash
# doctor.sh — sqm 実行環境の診断 (mac/Linux)。何が足りないかと対処を出す。
. "$(dirname "$0")/lib/common.sh"

problems=(); warnings=()

echo ""
echo "sqm 実行環境の診断"
echo "workspace: $WS"
echo ""

# 同梱バイナリで動く配布先 (sqm/dr_sbcl のソース無し) かどうか。
# 配布先ではソースもコンパイラ類も不要 (shader.core の作り直しに gcc だけ要る)
BUNDLED=0
[ "$SQM_BINARY_SOURCE" = bundled ] && [ -f "$SQM_BIN_PATH" ] && BUNDLED=1
need_src=1; [ "$BUNDLED" = 1 ] && need_src=0
[ "$BUNDLED" = 1 ] && echo "モード: 同梱バイナリ ($SQM_PLATFORM)" && echo ""

echo "[1] リポジトリ"
for spec in "sqm:$SQM_REPO:$need_src" "dr_sbcl:$DRSBCL_REPO:$need_src" "vclay:$VCLAY_REPO:0"; do
  n="${spec%%:*}"; rest="${spec#*:}"; p="${rest%:*}"; need="${rest##*:}"
  if [ -d "$p" ]; then
    ok "$n  [$(git -C "$p" rev-parse --abbrev-ref HEAD 2>/dev/null)] $(git -C "$p" log --oneline -1 2>/dev/null)"
  elif [ "$need" = "1" ]; then
    bad "$n が無い"; problems+=("git clone https://github.com/ultrahamlet/$n.git \"$p\"")
  elif [ "$n" = vclay ]; then
    warn "$n が無い (blob エディタ ssq_edit 用。sqm のビルドには不要)"
  else
    ok "$n なし — 同梱バイナリで動かすので不要"
  fi
done

if [ "$BUNDLED" = 1 ]; then
echo ""
echo "[2] 実行環境 (同梱バイナリ)"
if [ "$(uname -s)" = Linux ]; then
  # 同梱 linux-x64 の sqm は -march=x86-64-v3 (AVX2 必須)。非対応 CPU では
  # Illegal instruction で落ちる (原因を指さないので先に検査する)
  if grep -qw avx2 /proc/cpuinfo 2>/dev/null; then ok "CPU が AVX2 対応 (同梱 sqm の要件)"
  else bad "CPU が AVX2 非対応 — 同梱 sqm は Illegal instruction で落ちる"; problems+=("sqm をソースからビルドする (./build.sh sqm)"); fi
  if missing=$(ldd "$SQM_BIN_PATH" 2>&1 | grep "not found"); [ -z "$missing" ]; then ok "共有ライブラリ OK"
  else bad "共有ライブラリが足りない: $missing"; problems+=("sudo apt install zlib1g"); fi
fi
if command -v gcc >/dev/null 2>&1; then ok "gcc あり (自作シェーダーで ./build.sh core するときに使う)"
else warn "gcc が無い (レンダーだけなら不要。自作シェーダーの組み込みに要る)"; warnings+=("sudo apt install build-essential"); fi
if [ -x "$BUNDLE_DIR/dslc" ]; then ok "dslc (シェーダーコンパイラ) あり"
else warn "dslc が無い — このプラットフォームでは自作シェーダーを組み込めない"; fi
else
echo ""
echo "[2] ツールチェイン"
# 対処コマンドは OS で変える (mac: Homebrew / Linux: apt)
if [ "$(uname -s)" = Darwin ]; then
  FIX_CXX="xcode-select --install"; FIX_SBCL="brew install sbcl"
else
  FIX_CXX="sudo apt install build-essential"; FIX_SBCL="sudo apt install sbcl"
fi
if command -v c++ >/dev/null 2>&1; then ok "c++  $(c++ --version | head -1)"
else bad "C++ コンパイラが無い"; problems+=("$FIX_CXX"); fi
if [ "$(uname -s)" = Darwin ]; then
  # macOS: Apple clang は OpenMP を持たないので Homebrew libomp が要る
  if [ -d /opt/homebrew/opt/libomp ] || [ -d /usr/local/opt/libomp ]; then ok "libomp あり"
  else bad "libomp が無い (OpenMP 並列に必要)"; problems+=("brew install libomp"); fi
else
  # Linux: gcc の -fopenmp (libgomp) を使う。実際にリンクできるかで判定
  if command -v c++ >/dev/null 2>&1 && \
     echo 'int main(){return 0;}' | c++ -fopenmp -x c++ - -o /dev/null >/dev/null 2>&1; then
    ok "OpenMP (gcc -fopenmp / libgomp) あり"
  else bad "OpenMP が使えない (c++ -fopenmp が通らない)"; problems+=("sudo apt install build-essential"); fi
fi
if command -v sbcl >/dev/null 2>&1; then ok "sbcl $(sbcl --version)"
else bad "SBCL が無い (shader.core のビルドに必要)"; problems+=("$FIX_SBCL"); fi
if command -v python3 >/dev/null 2>&1; then
  ok "python3 $(python3 --version 2>&1)"
  if python3 -c "import numpy, skimage" 2>/dev/null; then ok "numpy / scikit-image あり"
  else warn "numpy / scikit-image が無い (sdfmodeler のメッシュ表示だけ不可)"; warnings+=("pip3 install numpy scikit-image"); fi
else warn "python3 が無い (sdfmodeler を使わないなら不要)"; fi
fi

echo ""
echo "[3] ビルド成果物"
if [ -f "$SQM_BIN_PATH" ]; then ok "sqm  $(du -k "$SQM_BIN_PATH" | cut -f1) KB"
else bad "sqm が未ビルド"; problems+=("./build.sh sqm"); fi
if [ -f "$SHADER_CORE" ]; then ok "shader.core  $(du -k "$SHADER_CORE" | cut -f1) KB"
else bad "shader.core が未ビルド — .lisp 材質が全部ネイティブ材質に化ける"; problems+=("./build.sh core   (先に sqm のビルドが要る)"); fi

echo ""
echo "[4] 実地テスト"
if [ -f "$SQM_BIN_PATH" ] && [ -f "$SHADER_CORE" ]; then
  sqm_setup_env
  scene="$SQM_REPO/scenes/bear_blob.ssq"
  [ -f "$scene" ] || scene=$(ls "$SQM_REPO"/scenes/*.ssq 2>/dev/null | head -1 || true)
  # 配布先は sqm リポジトリが無いので同梱のサンプルで試す
  [ -n "$scene" ] || scene="$SQMEXEC_DIR/scenes/bear_blob.ssq"
  [ -f "$scene" ] || scene="$SQMEXEC_DIR/scenes/smoke.ssq"
  if [ -n "$scene" ]; then
    out="${TMPDIR:-/tmp}/sqmexec_doctor.png"
    log=$("$SQM_BIN_PATH" -i "$scene" -o "$out" -x 120 -y 90 -A 1 2>&1 || true)
    if echo "$log" | grep -q '\[DR\] shader bridge ready'; then
      ok "レンダー成功 + DR シェーダーブリッジ有効"
    elif [ -f "$out" ]; then
      bad "レンダーは通ったが DR ブリッジが無効 — .lisp 材質がネイティブに化ける"
      problems+=("./build.sh core")
    else
      bad "レンダーが失敗した"; echo "$log" | head -5
    fi
    rm -f "$out"
  else warn "テスト用シーンが見つからない"; fi
else warn "ビルドが揃っていないので実地テストは省略"; fi

echo ""
if [ ${#problems[@]} -eq 0 ]; then
  printf '\033[32m==> 実行できます。\033[0m\n'
  echo "    レンダー   : ./render.sh <scene.ssq> <out.png>"
  echo "    エディタ   : ./serve.sh   (http://localhost:8642)"
  [ ${#warnings[@]} -gt 0 ] && { echo ""; echo "任意の追加:"; printf '    %s\n' "${warnings[@]}"; }
  exit 0
else
  printf '\033[33m==> 対処が必要です (上から順に):\033[0m\n'
  printf '    %s\n' "${problems[@]}"
  [ ${#warnings[@]} -gt 0 ] && { echo ""; echo "任意の追加:"; printf '    %s\n' "${warnings[@]}"; }
  exit 1
fi
