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
  cinema: %w[ みなとみらい UC幕張 109湘南 新宿ピカデリー UC豊洲 MOVIX橋本 ]
}.each do |category, names|
  names.each do |name|
    WorkLocation.find_or_create_by!(name: name) { |location| location.category = category }
  end
end

# Admin account for local development. Create production admins from the console instead.
if Rails.env.development?
  AdminUser.find_or_create_by!(email: "admin@example.com") do |admin_user|
    admin_user.password = "password"
  end
end
