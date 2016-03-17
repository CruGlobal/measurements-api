class MeasurementListUpdater
  def initialize(json_array)
    @json_array = json_array
  end

  def commit
    return unless valid?
    # might be nice to do this threaded as-well
    @json_array.each(&method(:push_measurement))
    @json_array.each(&method(:update_totals))
  end

  def valid?
    @json_array.all?(&method(:valid_measurement?))
  end

  attr_reader :error

  private

  def valid_measurement?(measurement)
    return false unless validate_measurement_mcc(measurement)

    measurement[:measurement] = Measurement.find_by('person_id = ? OR local_id = ?',
                                                    measurement[:measurement_type_id],
                                                    measurement[:measurement_type_id])
    if measurement[:measurement].blank?
      @error = 'You can only post measurements for local and person_assignment measuremenets. '\
                 "measurement_type_id: #{measurement[:measurement_type_id]} is not permitted"
      return false
    end

    if measurement[:measurement_type_id] == measurement[:measurement].local_id
      return false unless validate_local_measurement(measurement)
    else
      return false unless validate_person_measurement(measurement)
    end
    true
  end

  def validate_measurement_mcc(measurement)
    if measurement[:source].blank? && !measurement[:mcc].include?('_')
      @error = "No source provided and invalid MCC. Your must suffix your mcc with '_' "\
                 'and the name of your application. e.g. slm_gcmapp'
      return false
    end
    true
  end

  def validate_local_measurement(measurement)
    measurement[:related_entity_id] = measurement.delete(:ministry_id) if measurement[:ministry_id]
    if Power.current
      role = Power.current.user.inherited_assignment_for_ministry(measurement[:related_entity_id]).try(:role)
      unless Assignment::LEADER_ROLES.include? role
        @error = 'INSUFFICIENT_RIGHTS - You must be a member of one of the following roles: ' +
                 Assignment::LEADER_ROLES.join(', ')
        return false
      end
    end
    true
  end

  def validate_person_measurement(measurement)
    measurement[:related_entity_id] = measurement.delete(:assignment_id) if measurement[:assignment_id]
    if Power.current && Power.current.direct_assignments.where(gr_id: measurement[:related_entity_id]).none?
      @error = 'You can only post personal measurements for yourself.'
      return false
    end
    true
  end

  def push_measurement(measurement)
    gr_params = measurement.slice(:period, :value, :related_entity_id, :measurement_type_id)
    gr_params[:dimension] = measurement[:mcc]
    gr_params[:dimension] += "_#{measurement[:source]}" if measurement[:source].present?

    GlobalRegistryClient.client(:measurement).post(measurement: gr_params)
  end

  def update_totals(measurement)
    mcc = measurement[:mcc]
    mcc = mcc[0..mcc.index('_') - 1] if mcc.include?('_')

    related_id = measurement[:related_entity_id]
    if measurement[:measurement_type_id] == measurement[:measurement].person_id
      related_id = Assignment.find_by(gr_id: measurement[:related_entity_id]).ministry.gr_id
    end
    update_ministry(related_id, measurement[:period], measurement[:measurement], mcc)
  end

  def update_ministry(ministry_gr_id, period, measurement, mcc)
    Measurement::MeasurementRollup.new.run(measurement, ministry_gr_id, period, mcc)
  end
end
