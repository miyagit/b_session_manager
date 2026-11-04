# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Work locations. Booth budgets aren't decided yet, so budget_count stays nil.
{
  donki: %w[ 溝の口 後楽園 大宮東口 町田駅前 高田馬場 吉祥寺 ],
  cinema: %w[ UCみなとみらい UC幕張 109湘南 新宿ピカデリー UC豊洲 MOVIX橋本 ]
}.each do |category, names|
  names.each do |name|
    WorkLocation.find_or_create_by!(name: name) { |work_location| work_location.category = category }
  end
end

# Admin account for local development. Create production admins from the console instead.
if Rails.env.development?
  AdminUser.find_or_create_by!(email: "admin@example.com") do |admin_user|
    admin_user.password = "password"
  end
end

# Demo data for local development: staff, schedules, reports and LINE deliveries from Oct 1 to tomorrow.
# Runs only once (skipped when any work session exists); reset with `bin/rails db:seed:replant`.
if Rails.env.development? && WorkSession.none?
  random = Random.new(20261103)
  today = Date.current

  staff = %w[ 橋本 後藤 佐藤 鈴木 高橋 田中 伊藤 渡辺 山本 中村 ].each_with_index.map do |name, index|
    User.create!(name: name, role: index.zero? ? :admin : :staff, line_uid: format("U%032x", index + 1))
  end
  User.create!(name: "小林") # Added as a friend but not linked to a LINE account yet
  User.create!(name: "加藤", line_uid: format("U%032x", 99), is_active: false)

  work_locations = WorkLocation.order(:id).to_a
  slot_progress = { 13 => 0.3, 16 => 0.55, 19 => 0.8, 22 => 1.0 }
  failures = [ "対象グループに公式アカウントが参加していません", "LINE APIの月間送信上限に達しました" ]

  (Date.new(2026, 10, 1)..today.tomorrow).each_with_index do |date, day_index|
    day_work_locations = work_locations.rotate(day_index * 4).first(4)
    teams = day_work_locations.map { |work_location| [ work_location, nil ] }
    teams << [ day_work_locations.first, "Bチーム" ] if date.saturday? || date.sunday? # A second team at a busy weekend booth
    teams[0][1] = "Aチーム" if teams.size > 4

    members = staff.rotate(day_index).each_slice(2).to_a
    teams.each_with_index do |(work_location, team_name), team_index|
      work_session = WorkSession.create!(
        work_location: work_location, work_date: date, team_name: team_name, budget_count: 50 + random.rand(7) * 5,
        line_group_id: format("C%032x", work_location.id),
        work_assignments_attributes: members[team_index % members.size].map { |user| { user_id: user.id, target_count: 20 + random.rand(5) * 5 } }
      )
      next if date > today

      work_session.work_assignments.each do |work_assignment|
        work_assignment.update!(status: :confirmed, confirmed_at: date.in_time_zone.change(hour: 9, min: random.rand(40))) unless date == today && random.rand(4).zero?
      end

      finals = work_session.work_assignments.to_h { |work_assignment| [ work_assignment, (work_assignment.target_count * (0.7 + random.rand * 0.5)).round ] }
      slots = if date == today then [ 13, 16 ]
      elsif random.rand(12).zero? then [ 13, 16, 19 ] # Final report not submitted yet: counted as provisional
      else slot_progress.keys
      end

      slots.each do |slot|
        final = slot == 22
        report = work_session.reports.create!(
          submitted_by: work_session.work_assignments.first.user, report_type: final ? :final : :interim, report_slot: slot,
          reported_at: date.in_time_zone.change(hour: slot, min: random.rand(1..15)),
          report_results_attributes: finals.map do |work_assignment, total|
            acquired = (total * slot_progress[slot]).round
            { work_assignment: work_assignment, acquired_count: acquired,
              approach_count: (final ? acquired * 3 + random.rand(20) : nil), card_count: (final ? (acquired * (0.3 + random.rand * 0.2)).round : nil) }
          end
        )

        if date == today && slot == 16
          report.create_line_message_delivery!(status: :pending)
        elsif random.rand(25).zero?
          report.create_line_message_delivery!(status: :failed, error_message: failures.sample(random: random))
        else
          report.create_line_message_delivery!(status: :sent, sent_at: report.reported_at + 5.seconds, message_id: format("%018d", report.id))
        end
      end
    end
  end
end
