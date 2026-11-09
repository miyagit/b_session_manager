// LINE ミニアプリのおみくじ画面
// - LIFF を初期化し、ログインできていれば「結果をトークに送る」を表示する
// - 「おみくじを引く」で POST /api/omikuji を呼び、結果を表示する
// - 「結果をトークに送る」で ID トークンを添えて POST /api/omikuji/share を呼び、
//   サーバーが公式アカウントからユーザーのトークにプッシュ送信する
(() => {
  const app = document.getElementById("omikuji-app");
  if (!app) return;

  const $ = (id) => document.getElementById(id);
  const box = $("omikuji-box");
  const status = $("omikuji-status");
  const result = $("omikuji-result");
  const resultName = $("omikuji-result-name");
  const resultMessage = $("omikuji-result-message");
  const drawButton = $("omikuji-draw");
  const sendButton = $("omikuji-send");
  const closeButton = $("omikuji-close");
  const note = $("omikuji-note");

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  let liffReady = false;
  let lastResult = null;
  let lastToken = null;

  // ---- LIFF ----
  async function initLiff() {
    const liffId = app.dataset.liffId;

    if (!liffId) {
      note.textContent = "LIFF_ID が未設定のため、LINE 連携は無効です";
      return;
    }
    if (typeof liff === "undefined") {
      note.textContent = "LIFF SDK を読み込めませんでした";
      return;
    }

    try {
      // 外部ブラウザで開いたときは LINE ログインを自動で行う（ID トークンを取るため）
      await liff.init({ liffId, withLoginOnExternalBrowser: true });
      liffReady = true;
    } catch (error) {
      console.error("liff.init failed", error);
      note.textContent = "LINE との接続に失敗しました（おみくじは引けます）";
    }
  }

  // トークへの送信には LINE ログイン（ID トークン）が必要
  function canSendToChat() {
    return liffReady && liff.isLoggedIn();
  }

  // ---- API ----
  async function postJson(url, body) {
    return fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        Accept: "application/json"
      },
      body: body ? JSON.stringify(body) : undefined
    });
  }

  // ---- おみくじ ----
  async function fetchResult() {
    const response = await postJson(app.dataset.drawUrl);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  }

  function showResult(data) {
    lastResult = data;
    lastToken = data.token; // この結果を表す署名付きトークン。送信時はこれをサーバーに返す
    resultName.textContent = data.name;
    resultMessage.textContent = data.message;
    status.textContent = "";

    result.classList.remove("hidden", "animate-omikuji-pop");
    void result.offsetWidth; // アニメーションを毎回やり直すためのリフロー
    result.classList.add("animate-omikuji-pop");

    drawButton.textContent = "もう一度引く";
    sendButton.textContent = "結果をトークに送る";
    sendButton.disabled = false;
    sendButton.classList.toggle("hidden", !canSendToChat());
  }

  async function draw() {
    drawButton.disabled = true;
    sendButton.classList.add("hidden");
    closeButton.classList.add("hidden");
    result.classList.add("hidden");
    status.textContent = "おみくじを引いています…";
    box.classList.add("animate-omikuji-shake");

    try {
      const [data] = await Promise.all([fetchResult(), wait(900)]);
      showResult(data);
    } catch (error) {
      console.error("draw failed", error);
      status.textContent = "おみくじを引けませんでした。もう一度お試しください。";
    } finally {
      box.classList.remove("animate-omikuji-shake");
      drawButton.disabled = false;
    }
  }

  // ---- トークに送る ----
  async function sendToChat() {
    if (!lastResult || !canSendToChat()) return;

    const idToken = liff.getIDToken();
    if (!idToken) {
      note.textContent = "ログイン情報を取得できませんでした。ミニアプリを開き直してください。";
      return;
    }

    sendButton.disabled = true;
    note.textContent = "送信しています…";

    try {
      // 画面に表示した結果そのもの（lastToken）をサーバーに送る。サーバーはこのトークンから結果を復元して送信する
      const response = await postJson(app.dataset.shareUrl, { id_token: idToken, token: lastToken });
      if (response.status === 401) {
        note.textContent = "ログインの有効期限が切れました。ミニアプリを開き直してください。";
        sendButton.disabled = false;
        return;
      }
      if (!response.ok) throw new Error(`HTTP ${response.status}`);

      note.textContent = "公式アカウントから結果をトークに送りました 🎉";
      sendButton.textContent = "送信しました";
      if (liff.isInClient()) closeButton.classList.remove("hidden");
    } catch (error) {
      console.error("share failed", error);
      note.textContent = "トークに送れませんでした。公式アカウントを友だち追加しているか確認してください。";
      sendButton.disabled = false;
    }
  }

  drawButton.addEventListener("click", draw);
  sendButton.addEventListener("click", sendToChat);
  closeButton.addEventListener("click", () => liff.closeWindow());

  initLiff();
})();
