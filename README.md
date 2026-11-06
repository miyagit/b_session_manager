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
