# Shared by the admin and LIFF report forms: default report type, per-type parameter handling,
# target confirmation on the start report, and saving the report together with the shifts.
module ReportFiling
  extend ActiveSupport::Concern

  private
    # start → interim (first free slot) → final, skipping what has already been filed.
    def assign_default_report_type(report, work_session)
      if work_session.start_report.nil?
        report.report_type = :start
      elsif (slot = (Report::INTERIM_SLOTS - work_session.registered_slots).first)
        report.assign_attributes(report_type: :interim, report_slot: slot)
      elsif work_session.final_report.nil?
        report.report_type = :final
      end
    end

    # The form renders the fields of every report type and hides the others with CSS, so drop what doesn't apply.
    def report_attributes_for_type(attributes)
      case attributes[:report_type]
      when "start"
        attributes.except(:report_slot, :report_results_attributes)
      when "interim"
        rows = attributes[:report_results_attributes]
        attributes[:report_results_attributes] = rows.transform_values { |row| row.except(:card_count, :started_at, :ended_at) } if rows
        attributes
      else
        attributes.except(:report_slot)
      end
    end

    # The start report confirms the targets: the submitted values are applied to the shifts and saved with the report.
    def assign_targets(work_session)
      params.fetch(:shifts, {}).each do |shift_id, attributes|
        shift = work_session.shifts.find { |candidate| candidate.id.to_s == shift_id }
        shift&.assign_attributes(attributes.permit(:target_acquired_count, :target_approach_count))
      end
    end

    def save_report(report, work_session)
      shifts_valid = !report.start? || work_session.shifts.map(&:valid?).all?
      return false unless report.valid? && shifts_valid

      Report.transaction do
        work_session.shifts.each(&:save!) if report.start?
        report.save!
      end
      true
    end

    # One row per staff member on the booth, with first_user_id (the reporter) on top.
    def build_result_rows(report, work_session, first_user_id: nil)
      shifts = work_session.shifts.sort_by { |shift| [ shift.user_id == first_user_id ? 0 : 1, shift.id ] }
      report.result_rows_for(shifts.map(&:user))
    end

    def report_params
      params.expect(report: [ :work_session_id, :report_type, :report_slot, :submitted_by_id,
                              report_results_attributes: [ [ :user_id, :acquired_count, :approach_count, :card_count, :started_at, :ended_at ] ] ])
    end
end
