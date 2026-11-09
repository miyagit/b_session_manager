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

スタッフは LINE から LIFF アプリを開き、その日の実績を報告できます（`/liff`）。現場は管理者が登録した稼働予定（稼働場所・稼働日・ブース予算）とシフト（スタッフ・前半/後半/全日・個人目標）から自動で決まるので、現場や予算の入力は不要です。

報告は3種類あります。開始報告（個人目標の確認・修正）、途中報告（13時・16時・19時の累計の獲得件数とアプローチ）、最終報告（確定の獲得件数・アプローチ・カード数と、1分単位の勤務時間）。同じブースのスタッフ全員分を1人がまとめて報告できます。

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
