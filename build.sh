#!/usr/bin/env bash
# build.sh — sqm 本体と shader.core をビルドする (mac/Linux)
#   ./build.sh          全部 (sqm → shader.core の順。依存があるので順序は固定)
#   ./build.sh sqm      レンダラーだけ
#   ./build.sh core     shader.core だけ (要 sqm 先行ビルド)
. "$(dirname "$0")/lib/common.sh"

TARGET="${1:-all}"
JOBS="$( (command -v nproc >/dev/null && nproc) || sysctl -n hw.ncpu 2>/dev/null || echo 4 )"

[ -d "$SQM_REPO" ] || { echo "sqm リポジトリが無い: $SQM_REPO — ./doctor.sh を実行"; exit 1; }
sqm_setup_env

if [ "$TARGET" = "all" ] || [ "$TARGET" = "sqm" ]; then
  echo "[sqm] make -j$JOBS"
  ( cd "$SQM_REPO/dist" && make -j"$JOBS" )
  # ⚠ SQM_BIN_PATH は common.sh を読んだ時点 (ビルド前) に決まるので、初回ビルドでは
  #   同梱バイナリのパスを指している。ビルド成果物そのものを見る。
  BUILT_SQM="$SQM_REPO/dist/sqm"
  [ -f "$BUILT_SQM" ] && ok "sqm  $(du -k "$BUILT_SQM" | cut -f1) KB" || { echo "make は通ったが sqm が出来ていない"; exit 1; }
fi

# ⚠ shader.core は sqm のリンク成果物 (import lib) に依存するので必ず後。
#   1シェーダーだけ直しても core 全体が lib/*.o から再リンクされる。
if [ "$TARGET" = "all" ] || [ "$TARGET" = "core" ]; then
  [ -d "$DRSBCL_REPO" ] || { echo "dr_sbcl が無い: $DRSBCL_REPO"; exit 1; }
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
