# Shared by the admin and LIFF report forms: default report type, per-type parameter handling, target confirmation
# on the start report, hours actually worked on the final report, and saving everything together.
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
        attributes.except(:report_slot, :report_results_attributes, :audience_count)
      when "interim"
        rows = attributes[:report_results_attributes]
        attributes[:report_results_attributes] = rows.transform_values { |row| row.except(:card_count) } if rows
        attributes.except(:audience_count)
      else
        attributes.except(:report_slot)
      end
    end

    # The start report declares the targets (and a full-day flex start time): the values are applied to the shifts
    # and saved with the report.
    def assign_targets(work_session)
      params.fetch(:shifts, {}).each do |shift_id, attributes|
        shift = work_session.shifts.find { |candidate| candidate.id.to_s == shift_id }
        shift&.assign_attributes(attributes.permit(:target_acquired_count, :target_approach_count, :started_at))
      end
    end

    # The final report records the hours actually worked (work_records[<shift id>]) for shifts that aren't fixed.
    def assign_work_records(work_session)
      params.fetch(:work_records, {}).each do |shift_id, attributes|
        shift = work_session.shifts.find { |candidate| candidate.id.to_s == shift_id }
        next if shift.nil? || !shift.records_hours?

        (shift.work_record || shift.build_work_record).assign_attributes(attributes.permit(:started_at, :ended_at))
      end
    end

    # Work records required by a final report: one per reported staff member whose shift records hours.
    def required_work_records(report, work_session)
      report.report_results.filter_map { |result| work_session.shift_for(result.user_id) }
        .select(&:records_hours?).map { |shift| shift.work_record || shift.build_work_record }
    end

    # The start report saves the targets on the shifts (every staff member on the booth needs both); the final
    # report saves the hours actually worked.
    def save_report(report, work_session)
      shifts_valid = !report.start? || work_session.shifts.map { |shift| shift.valid?(:start_report) }.all?
      work_records = report.final? ? required_work_records(report, work_session) : []
      records_valid = work_records.map(&:valid?).all?
      return false unless report.valid? && shifts_valid && records_valid

      Report.transaction do
        work_session.shifts.each { |shift| shift.save!(context: :start_report) } if report.start?
        report.save!
        work_records.each(&:save!)
      end
      LineReportDeliveryJob.perform_later(report) if LineBot.report_group_id
      true
    end

    # One row per staff member on the booth, with first_user_id (the reporter) on top; cinema booths get the fixed 他社 row last.
    def build_result_rows(report, work_session, first_user_id: nil)
      shifts = work_session.shifts.sort_by { |shift| [ shift.user_id == first_user_id ? 0 : 1, shift.id ] }
      users = shifts.map(&:user)
      users << User.other_company if work_session.work_location.cinema?
      report.result_rows_for(users)
    end

    def report_params
      params.expect(report: [ :work_session_id, :report_type, :report_slot, :submitted_by_id, :audience_count,
                              report_results_attributes: [ [ :user_id, :acquired_count, :approach_count, :card_count ] ] ])
    end
end
