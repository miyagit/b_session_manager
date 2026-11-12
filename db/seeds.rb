# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Staff, by full name (surname only where the reports give no more). Every name in db/seeds/line_reports.yml
# must be one of these, apart from the 他社 entries.
STAFF = %w[
  松尾元勢 梅村晏生 渡辺了太 古賀桜太郎 田中凌 石原圭祐 平野湧真 舩田優輝 松久保凱也 古泉桃子
  小澤領 小笹遥仁 伊藤勇悟 橋爪元 岩元大佳 野元陽輝 吉田楓 橋本瑠美 島田晃佑 斉藤侑樹
  河崎智進 青木隆洋 今村天星 矢野新大 天野りの 後藤崇佑 中川大晟 大久保大智 宮嶋勇弥 永井優陽
  長沢空知 ベラスコアキラ 橋本佳祐 勝呂颯汰 梅澤和矢 八坂亜希菜 栗田康平 松本三四郎 三宅康平 菊池優絆
  須坂勇斗 中島ひな子 川岸悠太 見目光凛 迫麻理南 酒巻結 市村志銀 大西珠花 秦菜々美 小林健成
  永田拓夢 小田凌平 杉浦怜
  大林賢世 熊澤正輝 小松崎翔太 張 工藤 岩崎
].freeze
ADMINS = %w[ 宮嶋勇弥 ].freeze

STAFF.each do |name|
  User.find_or_create_by!(name: name) { |user| user.role = ADMINS.include?(name) ? :admin : :staff }
end
other_company = User.other_company

# Work locations and the report history from the LINE group 「【U-NEXT】営業成績報告」 (2026-09-13 to 2026-11-12),
# tidied up booth day by booth day in db/seeds/line_reports.yml.
line_reports = YAML.load_file(Rails.root.join("db/seeds/line_reports.yml"))

line_reports.fetch("locations").each do |name, attributes|
  WorkLocation.find_or_create_by!(name: name) do |work_location|
    work_location.assign_attributes(category: attributes.fetch("category"), budget_count: attributes["budget"])
  end
end

# Admin account for local development. Create production admins from the console instead.
if Rails.env.development?
  AdminUser.find_or_create_by!(email: "admin@example.com") do |admin_user|
    admin_user.password = "password"
  end
end

# Work sessions, shifts and reports, loaded once into an empty database (start over with bin/rails db:seed:replant).
# The 他社 entries (他社, 他社A, 他社さん1, ...) are summed into the 他社 row of the cinema reports. Every report was
# already shared in the LINE group, so it is marked as posted.
if WorkSession.none?
  staff_by_name = User.people.where(name: STAFF).index_by(&:name)
  work_locations = WorkLocation.all.index_by(&:name)

  ActiveRecord::Base.transaction do
    line_reports.fetch("sessions").each do |booth_day|
      work_location = work_locations.fetch(booth_day["location"])
      staff_member = lambda do |name|
        staff_by_name.fetch(name) { raise "line_reports.yml: 「#{name}」（#{booth_day["date"]} #{booth_day["location"]}）が STAFF にありません" }
      end
      staff = booth_day["staff"].map { |name, attributes| [ staff_member.(name), attributes ] }

      date = Date.parse(booth_day["date"])
      # "HH:MM" on the booth day; reports sent after midnight belong to the day before.
      time_of = lambda do |hhmm|
        hour, min = hhmm.split(":").map(&:to_i)
        date.in_time_zone.change(hour: hour, min: min) + (hour < 5 ? 1.day : 0)
      end
      work_session = WorkSession.create!(
        work_location: work_location, work_date: date, budget_count: booth_day["budget"],
        shifts_attributes: staff.map do |user, attributes|
          { user_id: user.id, shift_type: attributes.fetch("shift", "cinema"), started_at: attributes["started_at"],
            target_acquired_count: attributes["target"], target_approach_count: attributes["target_approach"] }
        end
      )
      reporter = ->(name) { staff_by_name[name] || staff.first.first }

      # { "名前" => [獲得, アプローチ, カード] } as result rows. Approaches missing from the early free-form reports
      # count as 0, and so do the 他社 row's unreported approaches and cards.
      result_rows = lambda do |results, final:|
        rows = {}
        results.each do |name, (acquired, approach, cards)|
          user = name.start_with?("他社") ? other_company : staff_member.(name)
          row = rows[user.id] ||= { user_id: user.id, acquired_count: 0, approach_count: 0, card_count: (0 if final) }
          row[:acquired_count] += acquired
          row[:approach_count] += approach.to_i
          row[:card_count] += cards.to_i if final
        end
        rows.values
      end
      file_report = lambda do |attributes|
        report = work_session.reports.create!(attributes)
        report.create_line_message_delivery!(status: :sent, sent_at: report.created_at)
      end

      if (start = booth_day["start"])
        file_report.(report_type: :start, submitted_by: reporter.(start["by"]), created_at: time_of.(start["at"]))
      end
      booth_day.fetch("interim", {}).each do |slot, interim|
        rows = result_rows.(interim["results"], final: false)
        next if rows.empty?

        file_report.(report_type: :interim, report_slot: slot, submitted_by: reporter.(interim["by"]),
                     created_at: time_of.(interim["at"]), report_results_attributes: rows)
      end
      final = booth_day["final"]
      rows = final ? result_rows.(final["results"], final: true) : []
      next if rows.empty?

      file_report.(report_type: :final, submitted_by: reporter.(final["by"]), created_at: time_of.(final["at"]),
                   audience_count: booth_day["audience"], report_results_attributes: rows)
      # Hours actually worked, where the reports tell (early leaves); other shifts keep their planned hours.
      staff.each do |user, attributes|
        next unless attributes["worked"]

        started_at, ended_at = attributes["worked"].split("-")
        work_session.shifts.find { |shift| shift.user_id == user.id }.create_work_record!(started_at: started_at, ended_at: ended_at)
      end
    end
  end
end
