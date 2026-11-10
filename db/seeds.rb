# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

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

# Demo data for local development: staff, budgets, work sessions with shifts, reports and LINE deliveries
# from Oct 1 to tomorrow. Runs only once (skipped when any work session exists); reset with `bin/rails db:seed:replant`.
if Rails.env.development? && WorkSession.none?
  random = Random.new(20261103)
  today = Date.current

  staff = %w[ 橋本 後藤 佐藤 鈴木 高橋 田中 伊藤 渡辺 山本 中村 ].each_with_index.map do |name, index|
    User.find_or_create_by!(name: name) { |user| user.assign_attributes(role: index.zero? ? :admin : :staff, line_uid: format("U%032x", index + 1)) }
  end
  User.find_or_create_by!(name: "小林") # Added as a friend but not linked to a LINE account yet
  User.find_or_create_by!(name: "加藤") { |user| user.assign_attributes(line_uid: format("U%032x", 99), is_active: false) }

  work_locations = WorkLocation.order(:id).to_a
  work_locations.each do |work_location|
    work_location.update!(budget_count: work_location.budget_count || 50 + random.rand(7) * 5)
  end

  slot_progress = { 13 => 0.3, 16 => 0.55, 19 => 0.8 }
  failures = [ "対象グループに公式アカウントが参加していません", "LINE APIの月間送信上限に達しました" ]

  (Date.new(2026, 10, 1)..today.tomorrow).each_with_index do |date, day_index|
    day_work_locations = work_locations.rotate(day_index * 4).first(4)
    members = staff.rotate(day_index).each_slice(2).to_a

    day_work_locations.each_with_index do |work_location, booth_index|
      booth_staff = members[booth_index % members.size]
      work_session = WorkSession.create!(
        work_location: work_location, work_date: date, budget_count: 50 + random.rand(7) * 5,
        shifts_attributes: booth_staff.each_with_index.map do |user, index|
          target = 20 + random.rand(5) * 5
          shift_type = index.zero? ? "full_day" : %w[ first_half second_half ].sample(random: random)
          { user_id: user.id, shift_type: shift_type, target_acquired_count: target, target_approach_count: target * 8,
            started_at: (shift_type == "full_day" ? "10:00" : nil) }
        end
      )
      next if date > today

      finals = work_session.shifts.to_h { |shift| [ shift, (shift.target_acquired_count * (0.7 + random.rand * 0.5)).round ] }
      slots = if date == today then [ 13, 16 ]
      elsif random.rand(12).zero? then [ 13, 16, 19 ] # Final report not submitted yet: counted as provisional
      else [ 13, 16, 19, :final ]
      end
      reporter = booth_staff.first

      work_session.reports.create!(submitted_by: reporter, report_type: :start, created_at: date.in_time_zone.change(hour: 9, min: 30 + random.rand(25)))

      slots.each do |slot|
        final = slot == :final
        report = work_session.reports.create!(
          submitted_by: reporter, report_type: final ? :final : :interim, report_slot: (slot unless final),
          created_at: date.in_time_zone.change(hour: final ? 22 : slot, min: random.rand(1..15)),
          report_results_attributes: finals.map do |shift, total|
            acquired = final ? total : (total * slot_progress[slot]).round
            result = { user: shift.user, acquired_count: acquired, approach_count: acquired * 7 + random.rand(30) }
            result.merge!(card_count: (acquired * (0.3 + random.rand * 0.2)).round, ended_at: (random.rand(4).zero? ? "21:30" : nil)) if final
            result
          end
        )

        if date == today && slot == 16
          report.create_line_message_delivery!(status: :pending)
        elsif random.rand(25).zero?
          report.create_line_message_delivery!(status: :failed, error_message: failures.sample(random: random))
        else
          report.create_line_message_delivery!(status: :sent, sent_at: report.created_at + 5.seconds, message_id: format("%018d", report.id))
        end
      end
    end
  end
end
