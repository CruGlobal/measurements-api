require 'rails_helper'

RSpec.describe MeasurementListUpdater, type: :model do
  let(:user) { FactoryGirl.create(:person) }
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:measurement_type) { FactoryGirl.create(:measurement) }
  let(:assignment_id) { SecureRandom.uuid }
  let(:measurements_json) do
    [
      {
        'measurement_type_id': measurement_type.local_id,
        'related_entity_id': ministry.gr_id,
        'period': '2014-11',
        'mcc': 'slm',
        'source': 'gma-app',
        'value': 123
      },
      {
        'measurement_type_id': measurement_type.local_id,
        'ministry_id': ministry.gr_id,
        'period': '2014-10',
        'mcc': 'slm',
        'source': 'gma-app',
        'value': 123
      },
      {
        'measurement_type_id': measurement_type.person_id,
        'assignment_id': assignment_id,
        'period': '2014-10',
        'mcc': 'slm',
        'source': 'gma-app',
        'value': 12
      }
    ]
  end

  let(:list) { MeasurementListUpdater.new(measurements_json) }
  describe '#valid?' do
    context 'as leader' do
      it 'is valid' do
        FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :leader, gr_id: assignment_id)

        Power.with_power(Power.new(user, ministry)) do
          expect(list).to be_valid
        end
      end
    end
    context 'without assignment' do
      it 'is not valid' do
        Power.with_power(Power.new(user, ministry)) do
          expect(list).to_not be_valid
        end
      end
    end

    it 'requires source' do
      json = [{ 'measurement_type_id': measurement_type.local_id, 'related_entity_id': ministry.gr_id,
                'period': '2014-11', 'mcc': 'slm' }]
      expect(MeasurementListUpdater.new(json)).to_not be_valid

      json = [{ 'measurement_type_id': measurement_type.local_id, 'related_entity_id': ministry.gr_id,
                'period': '2014-11', 'mcc': 'slm_churches' }]
      expect(MeasurementListUpdater.new(json)).to be_valid
    end

    it 'requires valid measurement_id' do
      json = [{ 'measurement_type_id': measurement_type.total_id, 'related_entity_id': ministry.gr_id,
                'period': '2014-11', 'mcc': 'slm_churches' }]
      expect(MeasurementListUpdater.new(json)).to_not be_valid
    end
  end

  describe '#commit' do
  end
end
