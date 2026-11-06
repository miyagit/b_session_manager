# おみくじを引くためのクラス（DB は使わない）
class Omikuji
  Result = Data.define(:name, :weight, :message)

  RESULTS = [
    Result.new(name: "大吉", weight: 10, message: "最高の一日になりそう！思い切ってチャレンジしよう✨"),
    Result.new(name: "中吉", weight: 20, message: "良いことが起こりそう。周りの人に感謝を伝えると吉😊"),
    Result.new(name: "小吉", weight: 25, message: "小さな幸せが見つかる日。身近なことを大切に🍀"),
    Result.new(name: "吉",   weight: 20, message: "穏やかな一日。コツコツ続けると実を結ぶ🌱"),
    Result.new(name: "末吉", weight: 15, message: "焦らずマイペースで。後半に運気が上がる🌤"),
    Result.new(name: "凶",   weight: 8,  message: "慎重に行動しよう。無理せず早めに休むのが吉😌"),
    Result.new(name: "大凶", weight: 2,  message: "今日は守りの日。深呼吸して明日に備えよう🍵")
  ].freeze

  # 重み付きランダムで結果をひとつ返す
  def self.draw(random: Random.new)
    total = RESULTS.sum(&:weight)
    pick = random.rand(total)

    RESULTS.each do |result|
      return result if pick < result.weight
      pick -= result.weight
    end

    RESULTS.last
  end

  # LINE に返信する文面を組み立てる
  def self.fortune_text(random: Random.new)
    result = draw(random: random)
    "🎋 おみくじの結果 🎋\n\n【#{result.name}】\n\n#{result.message}"
  end
end
