# One booth's day of reports (a work location on a work date): the unit the dashboard and analytics count.
# Interim counts are cumulative, so each staff member's effective result is the one from the final report,
# otherwise the one from their latest interim report; earlier slots are never added on top.
class BoothDay
  attr_reader :work_location, :work_date, :reports

  # Groups reports (with work_location and report_results preloaded) into booth days, newest date first.
  def self.build(reports)
    reports.group_by { |report| [ report.work_location_id, report.work_date ] }.values
      .map { |booth_reports| new(booth_reports) }
      .sort_by { |booth_day| [ -booth_day.work_date.jd, booth_day.work_location.id ] }
  end

  def initialize(reports)
    @reports = reports.sort_by(&:report_slot)
    @work_location = @reports.first.work_location
    @work_date = @reports.first.work_date
  end

  def display_name = work_location.name
  def budget_count = work_location.budget_count
  def latest_report = reports.last

  # :confirmed once a final report exists, otherwise :provisional.
  def result_status = reports.any?(&:final?) ? :confirmed : :provisional

  def effective_results
    @effective_results ||= reports.flat_map(&:report_results).group_by(&:user_id).values.map do |results|
      results.max_by { |report_result| [ report_result.report.final? ? 1 : 0, report_result.report.report_slot ] }
    end
  end

  def acquired_count = effective_results.sum(&:acquired_count)
  def approach_count = effective_results.sum { |report_result| report_result.approach_count.to_i }
  def card_count = effective_results.sum { |report_result| report_result.card_count.to_i }

  # Percentage, or nil when it can't be calculated (no budget).
  def achievement_rate
    return if budget_count.nil? || budget_count.zero?

    acquired_count * 100.0 / budget_count
  end
end
