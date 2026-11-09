# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
# b_session_manager

## LINE おみくじ Bot

LINE で「おみくじを引く」と送ると、おみくじの結果が返信されます。それ以外のメッセージには反応しません。

### 構成

| ファイル | 役割 |
| --- | --- |
| `app/controllers/api/linebot_controller.rb` | `POST /api/linebot/callback` で LINE の Webhook を受け取り、「おみくじを引く」に返信する |
| `app/models/omikuji.rb` | おみくじの抽選ロジック（大吉〜大凶を重み付きランダムで返す） |
| `config/routes.rb` | `namespace :api` 内の `post "linebot/callback", to: "linebot#callback"` |
| `config/environments/development.rb` | localtunnel / ngrok のホストを許可 |

### 環境変数

[LINE Developers](https://developers.line.biz/console/) の Messaging API チャネルから取得した値を、プロジェクト直下の `.env` に設定します（`dotenv-rails` が読み込みます）。

```
LINE_CHANNEL_SECRET=チャネルシークレット
LINE_CHANNEL_TOKEN=チャネルアクセストークン（長期）
```

### ローカルでの動かし方

1. サーバーを起動する

   ```
   bin/rails server -p 3100
   ```

2. ngrok または localtunnel で外部公開する

   ```
   ngrok http 3100
   # または
   npx localtunnel --port 3100
   ```

3. LINE Developers コンソールの「Messaging API 設定」で Webhook URL に `https://<発行されたホスト>/api/linebot/callback` を設定し、「Webhook の利用」を ON にする
4. 「応答メッセージ」を OFF にする（Bot の返信と二重にならないようにするため）
5. Bot を友だち追加して、「おみくじを引く」と送るとおみくじの結果が返ってきます

## LINE ミニアプリ（画面からおみくじを引く）

`/miniapp`（ルート `/` も同じ画面）が LIFF で動くおみくじ画面です。「おみくじを引く」ボタンで `POST /api/omikuji` を呼び、結果を表示します。「結果をトークに送る」を押すと、引いたときにサーバーが発行した署名付きトークンと LIFF の ID トークンを添えて `POST /api/omikuji/share` を呼びます。サーバーは署名付きトークンから「画面に表示した結果そのもの」を復元し、ID トークンを LINE で検証したうえで、公式アカウントからそのユーザーのトークにプッシュ送信します。結果の中身はトークンに閉じ込められているので、画面の表示と送信内容は必ず一致し、クライアントが結果を書き換えることもできません。

| ファイル | 役割 |
| --- | --- |
| `app/controllers/miniapp_controller.rb` | おみくじ画面（`GET /miniapp`） |
| `app/controllers/api/omikuji_controller.rb` | おみくじを引く API（`POST /api/omikuji`）と、結果をトークに送る API（`POST /api/omikuji/share`） |
| `app/models/line_id_token.rb` | LIFF の ID トークンを LINE の verify API で検証し、ユーザー ID を取り出す |
| `app/models/line_messaging.rb` | Messaging API の返信・プッシュ送信（Bot とミニアプリで共用） |
| `app/views/layouts/miniapp.html.erb` / `app/views/miniapp/show.html.erb` | LIFF SDK を読み込むレイアウトと画面 |
| `app/assets/javascripts/miniapp.js` | LIFF の初期化・おみくじの取得・トークへの送信 |
| `public/icon.svg` / `public/icon.png` | おみくじ箱のアイコン |

トークへの送信は公式アカウントからのプッシュ送信なので、ユーザーが公式アカウントを友だち追加している必要があります。また、プッシュ送信は公式アカウントの月間メッセージ数（無料枠あり）にカウントされます。

ブラウザのバージョン制限（`allow_browser`）は LINE アプリ内ブラウザで 406 にならないよう、`ApplicationController` から管理画面側（`Admin::BaseController`, `Admin::SessionsController`）へ移しています。

### 環境変数

`.env` に開発用の LIFF ID と、ミニアプリチャネルのチャネル ID を追加します。LIFF ID が未設定でも画面は動きますが、LINE 連携（トークへの送信）は無効になります。

```
LIFF_ID=開発用の LIFF ID
LIFF_CHANNEL_ID=ミニアプリチャネルの「チャネル基本設定」にあるチャネル ID
```

### 設定手順

1. [LINE Developers](https://developers.line.biz/console/) で、Messaging API チャネルと同じプロバイダーに「LINEミニアプリ」チャネルを作成する（作成直後から未認証ミニアプリとして審査なしで使えます）
2. 「ウェブアプリ設定」タブで、開発用のエンドポイント URL に `https://<ngrok のホスト>/miniapp` を設定する
3. 「基本情報」に表示される開発用の LIFF ID を `.env` の `LIFF_ID` に設定し、サーバーを再起動する
4. 結果をトークに送れるようにするには、「チャネル基本設定」の「リンクされたLINE公式アカウント」で Messaging API の公式アカウントをリンクし、スコープ `openid`（ID トークンの取得に必要）を ON にする。ユーザー側は公式アカウントを友だち追加しておく
5. `https://miniapp.line.me/<開発用の LIFF ID>` を LINE アプリで開く。公式アカウントのリッチメニューにこの URL を設定するとトーク画面から開けます。PC のブラウザで開いた場合は LINE ログインが自動で始まります
