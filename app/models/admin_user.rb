class AdminUser < ApplicationRecord
  # :registerable is left out on purpose so nobody can sign up as an admin from the browser.
  # Others available are: :recoverable, :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :validatable
end
