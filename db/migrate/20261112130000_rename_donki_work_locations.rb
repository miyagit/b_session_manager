class RenameDonkiWorkLocations < ActiveRecord::Migration[8.1]
  # Store names as they appear on the report form ("現場:ドン・キホーテ大宮東口"). Cinemas and event venues keep theirs.
  RENAMES = {
    "溝の口" => "ドン・キホーテ溝の口",
    "後楽園" => "ドン・キホーテ後楽園",
    "大宮東口" => "ドン・キホーテ大宮東口",
    "町田駅前" => "ドン・キホーテ町田駅前",
    "高田馬場" => "ドン・キホーテ高田馬場",
    "吉祥寺" => "ドン・キホーテ吉祥寺",
    "下北沢" => "ドン・キホーテ下北沢",
    "新宿" => "ドン・キホーテ新宿",
    "成増" => "ドン・キホーテ成増",
    "ピカソ目黒駅前" => "ドン・キホーテピカソ目黒駅前",
    "MEGA板橋志村" => "MEGAドン・キホーテ板橋志村",
    "蒲田" => "ドン・キホーテ蒲田"
  }.freeze

  def up
    RENAMES.each { |from, to| rename_location(from, to) }
  end

  def down
    RENAMES.each { |from, to| rename_location(to, from) }
  end

  private
    def rename_location(from, to)
      update "UPDATE work_locations SET name = #{quote(to)}, updated_at = CURRENT_TIMESTAMP WHERE name = #{quote(from)}"
    end
end
