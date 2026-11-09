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

## LIFF（スタッフ向け実績報告）

スタッフは LINE から LIFF アプリを開いて、自分が割り当てられたブースの実績を報告できます（`/liff`）。

### LINE Developers の設定

1. Messaging API チャネルと**同じプロバイダー**に LINE ログインチャネルを作成する（ユーザーIDを一致させるため）。
2. そのチャネルに LIFF アプリを追加する。
   - エンドポイントURL: `https://<公開ホスト>/liff`（開発中は ngrok などのトンネルURL）
   - スコープ: `openid` と `profile`
   - サイズ: Tall または Full
3. LIFF ID と LINE ログインチャネルのチャネルIDを、credentials または環境変数で渡す。

| 設定 | credentials のキー | 環境変数 |
| --- | --- | --- |
| LIFF ID | `line.liff_id` | `LIFF_ID` |
| LINE ログインチャネルのチャネルID | `line.login_channel_id` | `LINE_LOGIN_CHANNEL_ID` |

スタッフの特定は、LIFF の IDトークンを LINE の verify API で検証し、その `sub`（LINEユーザーID）を `users.line_uid` と突き合わせて行います。
`line_uid` は公式アカウントの友だち追加（follow イベント）で登録されるため、スタッフは先に友だち追加が必要です。

### ローカルでの動作確認

development 環境では `/liff` に「開発用ログイン」が表示され、LINE を使わずにスタッフを選んで報告画面を開けます。
