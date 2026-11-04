# herdr-app-config

[Herdr](https://herdr.dev) の Mac アプリ（`~/.config/herdr-app`）の個人設定。自作の mod は [herdr-app-mods](https://github.com/ishiyu/herdr-app-mods) に分けている。

## 入れ方

```sh
ghq get ishiyu/herdr-app-config ishiyu/herdr-app-mods
~/ghq/github.com/ishiyu/herdr-app-config/install.sh
```

- `themes/*.json`（自作テーマ）は `~/.config/herdr-app/themes/` へファイルごとに symlink する。`settings.json` の `theme` で選ぶ
  - Settings のテーマ選択は `layouts/.state/<layout>.json` に保存され、`settings.json` の `theme` より優先される。`settings.json` の指定が効くのはテーマを一度も選んでいない環境だけ
  - テーマファイルは起動時とテーマを選んだときにしか読まれない。編集したら Settings で選び直すか再起動する
- `layouts/*.json`（同梱の `main` を `layout.clone` で複製した自作 layout）は `~/.config/herdr-app/layouts/` へファイルごとに symlink する
  - `my-layout`: Agents 欄を herdr-app-mods の `my-agents` に差し替えたもの
  - symlink の先を編集してもその場では読み込まれない。`layout.switch` で一度ほかの layout へ切り替えて戻すと反映される
- `settings.json` / `keys.json` は `~/.config/herdr-app` へ symlink する。アプリが設定画面から書き戻すと、この repo のファイルが変わる（キー順や `1` → `1.0` の書式も並べ替わる）
- mod は herdr-app-mods の各フォルダを `~/.config/herdr-app/mods/` へ rsync でコピーする。Herdr のフォルダ監視は symlink の先を追わず、symlink にするとホットリロードが効かないため
- 置き換える前の実体は `~/.local/state/herdr-app-config/backup-<時刻>/` に退避する

## mod を編集するとき

```sh
./install.sh --watch   # 要 fswatch（brew install fswatch）
```

herdr-app-mods を監視し、保存のたびにコピーし直す。アプリ側（`~/.config/herdr-app/mods/`）を直接編集すると、次の同期で上書きされる。
