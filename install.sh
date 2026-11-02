#!/usr/bin/env bash
# この repo の設定を ~/.config/herdr-app へ symlink し、herdr-app-mods の mod を実体としてコピーする。
#
# mod だけコピーにするのは、Herdr のフォルダ監視が symlink の先を追わず、
# symlink にした mod はリンク先を編集してもホットリロードされないため。
# settings.json / keys.json は symlink でも読み込み・書き戻しとも効く。
#
#   ./install.sh          1 回だけ反映する
#   ./install.sh --watch  反映したあと herdr-app-mods を監視し、保存のたびにコピーし直す（要 fswatch）
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
home="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
mods_repo="${HERDR_APP_MODS:-$(dirname "$repo")/herdr-app-mods}"
backup="$HOME/.local/state/herdr-app-config/backup-$(date +%Y%m%d%H%M%S)"

watch=false
case "${1:-}" in
  "") ;;
  --watch) watch=true ;;
  *) echo "usage: $0 [--watch]" >&2; exit 2 ;;
esac

[ -d "$home" ] || { echo "error: $home がありません。Herdr.app を一度起動してください" >&2; exit 1; }
[ -d "$mods_repo" ] || { echo "error: $mods_repo がありません（HERDR_APP_MODS で指定可）" >&2; exit 1; }
if $watch && ! command -v fswatch >/dev/null; then
  echo "error: --watch には fswatch が必要です（brew install fswatch）" >&2; exit 1
fi

# 既存の実体は退避する。退避先を mods/ の中にすると Herdr が別 mod として読み込むため、home の外に置く
stash() {
  mkdir -p "$backup"
  mv "$1" "$backup/"
  echo "backup  $1 -> $backup/"
}

link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then echo "ok      $dst"; return; fi
    rm "$dst"
  elif [ -e "$dst" ]; then
    stash "$dst"
  fi
  ln -s "$src" "$dst"
  echo "link    $dst -> $src"
}

sync_mods() {
  mkdir -p "$home/mods"
  for d in "$mods_repo"/*/; do
    [ -f "$d/main.js" ] || continue
    local name dst
    name="$(basename "$d")"
    dst="$home/mods/$name"
    # 以前の版の install.sh が張った symlink は実体に置き換える
    if [ -L "$dst" ]; then rm "$dst"; fi
    # Herdr が mod フォルダに書く型定義・エディタ設定は repo に無いので、--delete の対象から外す
    rsync -a --delete --exclude '*.d.ts' --exclude 'jsconfig.json' "$d" "$dst/"
    echo "sync    $dst <- $d"
  done
}

for f in settings.json keys.json; do
  if [ -f "$repo/$f" ]; then link "$repo/$f" "$home/$f"; fi
done
mkdir -p "$home/themes"
for f in "$repo"/themes/*.json; do
  link "$f" "$home/themes/$(basename "$f")"
done
sync_mods

if $watch; then
  echo "watching $mods_repo (Ctrl-C で終了)"
  # -o: 変更をまとめて件数だけ流す。--latency で保存直後の連続イベントを 1 回の同期にまとめる
  fswatch -o --latency 0.3 --exclude '/\.git/' "$mods_repo" | while read -r _; do sync_mods; done
fi
