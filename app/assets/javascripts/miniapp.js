// LINE ミニアプリのおみくじ画面
// - LIFF を初期化し、LINE アプリ内で開かれたときだけ「結果をトークに送る」を表示する
// - 「おみくじを引く」で POST /api/omikuji を呼び、結果を表示する
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
      await liff.init({ liffId });
      liffReady = true;
      if (!liff.isInClient()) {
        note.textContent = "LINE アプリで開くと、結果をトークに送れます";
      }
    } catch (error) {
      console.error("liff.init failed", error);
      note.textContent = "LINE との接続に失敗しました（おみくじは引けます）";
    }
  }

  // トークへの送信は LINE アプリ内で開いたときだけ使える
  function canSendToChat() {
    return liffReady && liff.isInClient();
  }

  // ---- おみくじ ----
  async function fetchResult() {
    const response = await fetch(app.dataset.drawUrl, {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken, Accept: "application/json" }
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  }

  function showResult(data) {
    lastResult = data;
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

  async function sendToChat() {
    if (!lastResult || !canSendToChat()) return;

    sendButton.disabled = true;
    try {
      await liff.sendMessages([{ type: "text", text: lastResult.text }]);
      note.textContent = "結果をトークに送りました 🎉";
      sendButton.textContent = "送信しました";
      closeButton.classList.remove("hidden");
    } catch (error) {
      console.error("liff.sendMessages failed", error);
      note.textContent = "トークに送れませんでした。トーク画面からミニアプリを開くと送れます。";
      sendButton.disabled = false;
    }
  }

  drawButton.addEventListener("click", draw);
  sendButton.addEventListener("click", sendToChat);
  closeButton.addEventListener("click", () => liff.closeWindow());

  initLiff();
})();
