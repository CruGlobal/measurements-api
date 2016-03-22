# frozen_string_literal: true
require 'rails_helper'

describe V5::MeasurementTypeSerializer do
  describe 'single training' do
    let(:ministry) { FactoryGirl.build(:ministry) }
    let(:resource) do
      m = FactoryGirl.create(:measurement, perm_link: 'lmi_total_build_holyspirit', sort_order: 11,
                                           english: 'Presenting the Holy Spirit', section: 'build',
                                           column: 'faith', description: 'Number of people',
                                           person_id: '72157726-b13e-11e4-98a2-12c37bb2d521',
                                           local_id: 'b65aaf6e-b13e-11e4-98a3-12c37bb2d521',
                                           total_id: '5a5cdcde-d55a-11e3-b358-12725f8f377c')
      FactoryGirl.create(:measurement_translation, measurement: m, ministry: ministry,
                                                   language: 'fr', name: 'Présenter le Saint-Esprit',
                                                   description: 'Nombre de personnes')
      MeasurementType.new(measurement: m, ministry_id: ministry.id, locale: 'fr')
    end
    let(:serializer) do
      V5::MeasurementTypeSerializer.new(resource)
    end
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it 'has attributes' do
      expect(hash).to include_json json_expectation
    end
  end

  def json_expectation
    json_text = File.new(Rails.root.join('spec/fixtures/measurement_type_v5_expectation.json')).read
    JSON.parse(json_text).symbolize_keys.except(:id)
  end
end
