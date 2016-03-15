require 'import_util'

class ImportMappings
  # Array of mappings for how to import from CSV dumps of the old measurements
  # api data.
  MAPPINGS = [
    # Template:
    # [
    #  Model, :csv_dump_file, { old_csv_field: new_model_field },
    #  labmda do |model_object, row|
    #    model_object.some_field = custom_method(row[:field])
    #  end,
    #  lambda do |rows|
    #    rows.sort
    #  end
    # ]
    [
      Ministry, :ministries,
      {
        min_id: :gr_id,
        min_scope: :ministry_scope,
        parent_min_id: :parent_gr_id,
        lat: :latitude,
        long: :longitude,
        zoom: :location_zoom,
        currency_sybmol: :currency_symbol
      },
      lambda do |ministry, row|
        ministry.min_code = nil if ministry.min_code.blank?
        ministry.mccs << Ministry::MCC_SLM if row[:slm]
        ministry.mccs << Ministry::MCC_LLM if row[:llm]
        ministry.mccs << Ministry::MCC_GCM if row[:gcm]
        ministry.mccs << Ministry::MCC_DS if row[:ds]
      end,
      lambda do |rows|
        TreeOrder.new(rows, :id, :parent_id).ordered_parents_first
      end
    ],
    [Person, :person, { person_id: :gr_id }],
    [
      Audit, :audit, { timestamp: :created_at },
      lambda do |audit, row|
        if row[:type].present?
          audit.audit_type = Audit.audit_types.invert[row[:type].to_i]
        end
        audit.person_id = ImportUtil.person_id_by_gr_id(row[:person_id])
        audit.ministry_id = ImportUtil.ministry_id_by_gr_id(row[:ministry_id])
      end
    ],
    [
      Church, :gcm_churches, { last_updated: :updated_at },
      lambda do |church, row|
        church.created_by_id = ImportUtil.person_id_by_gr_id(row[:created_by]) if row[:created_by].present?
        church.ministry_id =
          if row[:target_area_id].present?
            ImportUtil.ministry_id_by_gr_id(row[:target_area_id])
          elsif row[:target_area].present?
            ImportUtil.find_ministry_id(row[:target_area])
          end
      end,
      lambda do |rows|
        TreeOrder.new(rows, :id, :parent_id).ordered_parents_first
      end
    ],
    [
      ChurchValue, :church_value, {},
      lambda do |_church_value, row|
        church = Church.find_by(id: row[:church_id])
        unless church
          Rails.logger.info "Can't find church for id #{row[:church_id]}"
          raise Import::SkipRecord
        end
      end
    ],
    [Measurement, :measurements, {}],
    [
      MeasurementTranslation, :measurements_trans, {},
      lambda do |measurement_trans, row|
        measurement_trans.ministry_id = ImportUtil.ministry_id_by_gr_id(row[:ministry_id])
      end
    ],
    [
      Training, :gcm_training, {},
      lambda do |training, row|
        training.created_by_id = ImportUtil.person_id_by_gr_id(row[:created_by]) if row[:created_by].present?
        training.ministry_id = ImportUtil.ministry_id_by_gr_id(row[:ministry_id])
      end
    ],
    [
      TrainingCompletion, :gcm_training_completion,
      { last_updated: :updated_at }
    ],
    [
      UserMeasurementState, :default_measurement_states, {},
      lambda do |state, row|
        state.person_id = ImportUtil.person_id_by_gr_id(row[:person_id])
        raise Import::SkipRecord unless state.person_id.present?
      end
    ],
    [
      UserMapView, :default_map_views, {},
      lambda do |view, row|
        view.person_id = ImportUtil.person_id_by_gr_id(row[:person_id])
        raise Import::SkipRecord unless view.person_id.present?
        view.ministry_id = ImportUtil.ministry_id_by_gr_id(row[:min_id])
        raise Import::SkipRecord unless view.ministry_id.present?
      end
    ],
    [
      UserContentLocale, :user_pref_content_locale, {},
      lambda do |user_locale, row|
        user_locale.person_id = ImportUtil.person_id_by_gr_id(row[:person_id])
        raise Import::SkipRecord unless user_locale.person_id.present?
        user_locale.ministry_id = ImportUtil.ministry_id_by_gr_id(row[:ministry_id])
        raise Import::SkipRecord unless user_locale.ministry_id.present?
      end
    ],
    [
      UserPreference, :user_preferences, {},
      lambda do |user_pref, row|
        user_pref.person_id = ImportUtil.person_id_by_gr_id(row[:person_id])
        raise Import::SkipRecord unless user_pref.person_id.present?
      end
    ],
    [
      Assignment, :assignment, { assignment_id: :gr_id },
      lambda do |assignment, row|
        role = row[:team_role]
        raise Import::SkipRecord if role.blank? || role.start_with?('inherited')
        assignment.person_id = ImportUtil.person_id_by_gr_id(row[:person_id])
        raise Import::SkipRecord if assignment.person_id.blank?
        assignment.ministry_id = ImportUtil.ministry_id_by_gr_id(row[:ministry_id])
        raise Import::SkipRecord if assignment.ministry.blank?
        assignment.role = Assignment.roles[role]
        raise "Unexpected role: #{row[:team_role]}" unless assignment.role
      end
    ]
  ].freeze
end
