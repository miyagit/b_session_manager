# A group of staff for one quarter (1Q = 1〜3月 … 4Q = 10〜12月). Each member gets an acquisition budget per month,
# and the team screen follows those budgets against the registered donki shifts and the reports (TeamProgress).
class Team < ApplicationRecord
  QUARTER_MONTHS = 3

  has_many :team_memberships, -> { order(:id) }, dependent: :destroy, inverse_of: :team
  has_many :users, through: :team_memberships

  accepts_nested_attributes_for :team_memberships, allow_destroy: true, reject_if: ->(attributes) { attributes[:user_id].blank? }

  validates :name, presence: true, uniqueness: { scope: :starts_on, message: "は同じ四半期にすでにあります" }
  validates :starts_on, presence: true
  validate :starts_on_is_quarter_start
  validate :members_listed_once

  # The first day of the quarter a date falls in.
  def self.quarter_start(date) = Date.new(date.year, (date.month - 1) / QUARTER_MONTHS * QUARTER_MONTHS + 1, 1)

  # "2026年4Q（10〜12月）"
  def self.quarter_label(starts_on)
    "#{starts_on.year}年#{(starts_on.month - 1) / QUARTER_MONTHS + 1}Q（#{starts_on.month}〜#{starts_on.month + QUARTER_MONTHS - 1}月）"
  end

  def quarter_label = self.class.quarter_label(starts_on)

  # The first days of the quarter's months.
  def months = (0...QUARTER_MONTHS).map { |offset| starts_on >> offset }
  def covers?(month) = months.include?(month)

  private
    def starts_on_is_quarter_start
      return if starts_on.nil? || starts_on == self.class.quarter_start(starts_on)

      errors.add(:starts_on, "は四半期の初日（1月・4月・7月・10月の1日）にしてください")
    end

    def members_listed_once
      user_ids = team_memberships.reject(&:marked_for_destruction?).map(&:user_id).compact
      errors.add(:team_memberships, "に同じスタッフが2回入っています") if user_ids.uniq.size != user_ids.size
    end
end
