# frozen_string_literal: true
class MeasurementListUpdater
  def initialize(json_array)
    @json_array = json_array
  end

  def commit
    return unless valid?
    batch = Sidekiq::Batch.new
    batch.on(:success, Callback::MeasurementListUpdaterCallback,
             json: @json_array, gr_client_params: GlobalRegistryClient.parameters)
    batch.jobs do
      @json_array.each do |measurement|
        GrSync::WithGrWorker.queue_call(GlobalRegistryClient.parameters,
                                        GrSync::MeasurementPush, :push_to_gr, measurement)
      end
    end
  end

  def valid?
    @json_array.all?(&method(:valid_measurement?))
  end

  attr_reader :error

  private

  def valid_measurement?(measurement)
    return false unless validate_measurement_mcc(measurement)
    return false unless validate_measurement_type(measurement)
    true
  end

  def validate_measurement_type(measurement)
    current_measurement = Measurement.find_by('person_id = ? OR local_id = ?',
                                              measurement[:measurement_type_id],
                                              measurement[:measurement_type_id])
    if current_measurement.blank?
      @error = 'You can only post measurements for local and person_assignment measurements. '\
                 "measurement_type_id: #{measurement[:measurement_type_id]} is not permitted"
      return false
    end
    measurement[:measurement_id] = current_measurement.id
    if measurement[:measurement_type_id] == current_measurement.local_id
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
end
