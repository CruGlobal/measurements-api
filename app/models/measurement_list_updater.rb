class MeasurementListUpdater
  def initialize(json_array)
    @json_array = json_array
  end

  def commit
    return unless valid?
    # might be nice to do this threaded as-well
    @json_array.each do |measurement|
      push_to_gr(measurement)
    end
  end

  def valid?
    @json_array.all?(&method(:valid_measurement?))
  end

  def error
    @error
  end

  private

  def valid_measurement?(measurement)
    if measurement[:source].blank? && !measurement[:mcc].include?('_')
      @error = "No source provided and invalid MCC. Your must suffix your mcc with '_' "\
                 'and the name of your application. e.g. slm_gcmapp'
      return false
    end
    measurement[:measurement] = Measurement.find_by('person_id = ? OR local_id = ?',
                                                    measurement[:measurement_type_id],
                                                    measurement[:measurement_type_id])
    if measurement[:measurement].blank?
      @error = 'You can only post measurements for local and person_assignment measuremenets. '\
                 "measurement_type_id: #{measurement[:measurement_type_id]} is not permitted"
      return false
    end
    if measurement[:measurement_type_id] == measurement[:measurement].local_id
      measurement[:related_entity_id] = measurement.delete(:ministry_id) if measurement[:ministry_id]
      if Power.current
        role = Power.current.user.inherited_assignment_for_ministry(measurement[:related_entity_id]).try(:role)
        unless Assignment::LEADER_ROLES.include? role
          @error = 'INSUFFICIENT_RIGHTS - You must be a member of one of the following roles: ' +
                   Assignment::LEADER_ROLES.join(', ')
          return false
        end
      end
    else
      measurement[:related_entity_id] = measurement.delete(:assignment_id) if measurement[:assignment_id]
      if Power.current && Power.current.direct_assignments.where(id: measurement[:related_entity_id]).none?
        @error = 'You can only post personal measurements for yourself.'
        return false
      end
    end
    true
  end

  def push_to_gr(_measurement)

  end
end
