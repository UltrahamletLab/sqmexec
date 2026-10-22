#!/usr/bin/env bash
# build.sh — sqm 本体と shader.core をビルドする (mac/Linux)
#   ./build.sh          全部 (sqm → shader.core の順。依存があるので順序は固定)
#   ./build.sh sqm      レンダラーだけ
#   ./build.sh core     shader.core だけ (要 sqm 先行ビルド)
#
# shader.core の作り方は 2 通り (自動で選ぶ):
#   ① dr_sbcl リポジトリがある   → dr_sbcl/build-all.lisp (SBCL + DSL コンパイラのソース)
#   ② dr_sbcl が無い (配布先)     → 同梱の bin/<platform>/dslc (コンパイラ実行ファイル) で
#                                   sqmexec/shader/*.lisp から作る。出力は build/<platform>/shader.core
#   SQM_CORE_SOURCE=dslc で ① の環境でも ② を強制できる (自作シェーダーの確認用)
. "$(dirname "$0")/lib/common.sh"

TARGET="${1:-all}"
JOBS="$( (command -v nproc >/dev/null && nproc) || sysctl -n hw.ncpu 2>/dev/null || echo 4 )"

sqm_setup_env

if [ "$TARGET" = "all" ] || [ "$TARGET" = "sqm" ]; then
  [ -d "$SQM_REPO" ] || { echo "sqm リポジトリが無い: $SQM_REPO — レンダラーのビルドには sqm のソースが要る (同梱バイナリを使うなら ./build.sh core だけで良い)"; exit 1; }
  echo "[sqm] make -j$JOBS"
  ( cd "$SQM_REPO/dist" && make -j"$JOBS" )
  # ⚠ SQM_BIN_PATH は common.sh を読んだ時点 (ビルド前) に決まるので、初回ビルドでは
  #   同梱バイナリのパスを指している。ビルド成果物そのものを見る。
  BUILT_SQM="$SQM_REPO/dist/sqm"
  [ -f "$BUILT_SQM" ] && ok "sqm  $(du -k "$BUILT_SQM" | cut -f1) KB" || { echo "make は通ったが sqm が出来ていない"; exit 1; }
fi

# ⚠ shader.core は sqm のリンク成果物 (import lib) に依存するので必ず後。
#   1シェーダーだけ直しても core 全体が lib/*.o から再リンクされる。
if { [ "$TARGET" = "all" ] || [ "$TARGET" = "core" ]; } && \
   { [ ! -d "$DRSBCL_REPO" ] || [ "${SQM_CORE_SOURCE:-}" = dslc ]; }; then
  # ② 同梱 dslc で sqmexec/shader から作る (コンパイラのソースは不要。C コンパイラは要る)
  DSLC="$BUNDLE_DIR/dslc"
  [ -x "$DSLC" ] || { echo "dslc が無い: $DSLC — このプラットフォーム ($SQM_PLATFORM) 用は未配布"; exit 1; }
  command -v gcc >/dev/null || { echo "gcc が無い (dslc はシェーダーを C 経由でコンパイルする)"; exit 1; }
  OUT_DIR="$SQMEXEC_DIR/build/$SQM_PLATFORM"
  echo "[core] dslc shader/ → $OUT_DIR  (一覧: shader/BUILD_LIST)"
  "$DSLC" "$SQMEXEC_DIR/shader" "$OUT_DIR" "$SQMEXEC_DIR/shader/BUILD_LIST" \
    | grep -E "^=== dslc done|eval error|missing:|error" || true
  [ -f "$OUT_DIR/shader.core" ] && ok "shader.core  $(du -k "$OUT_DIR/shader.core" | cut -f1) KB  ($OUT_DIR)" \
    || { echo "dslc は終わったが shader.core が出来ていない"; exit 1; }
  echo "    render.sh / doctor.sh は同梱 sqm を使うとき build/ の shader.core を優先して読む"
elif [ "$TARGET" = "all" ] || [ "$TARGET" = "core" ]; then
  # ① dr_sbcl のソースから作る
  if [ "$(uname -s)" = Darwin ]; then FIX_SBCL="brew install sbcl"; else FIX_SBCL="sudo apt install sbcl"; fi
  command -v sbcl >/dev/null || { echo "SBCL が無い — $FIX_SBCL"; exit 1; }
  # lib/ は .gitignore 対象なので clone 直後には無い。無いと C 生成も ld も失敗する
  mkdir -p "$DRSBCL_REPO/lib"
  script=build-all.lisp
  echo "[core] sbcl --script $script"
  ( cd "$DRSBCL_REPO" && sbcl --script "$script" )
  BUILT_CORE="$DRSBCL_REPO/lib/shader.core"   # SHADER_CORE も同じ理由でビルド前の値
  [ -f "$BUILT_CORE" ] && ok "shader.core  $(du -k "$BUILT_CORE" | cut -f1) KB" || { echo "ビルドは通ったが shader.core が出来ていない"; exit 1; }
fi

echo ""
printf '\033[32m==> 完了。./doctor.sh で実地テストできます。\033[0m\n'
