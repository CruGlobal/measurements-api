# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MeasurementListReader, type: :model do
  let(:user) { FactoryGirl.create(:person) }
  let(:ministry) { FactoryGirl.create(:ministry, lmi_hide: ['hidden'], lmi_show: ['shown']) }

  describe '#new' do
    let(:list) { MeasurementListReader.new }

    it 'has default values' do
      expect(list.period).to eq Time.zone.today.strftime('%Y-%m')
      expect(list.source).to eq 'gma-app'
    end
  end

  describe '#load' do
    def measurement_json(related_entity_id = nil)
      {
        measurement_type: {
          perm_link: 'LMI',
          measurements: [
            {
              id: SecureRandom.uuid, period: (Time.zone.today - 4.months).strftime('%Y-%m'),
              value: '3.0', related_entity_id: related_entity_id
            },
            {
              id: SecureRandom.uuid, period: (Time.zone.today - 5.months).strftime('%Y-%m'),
              value: '1.0', related_entity_id: related_entity_id
            }
          ]
        }
      }
    end

    def stub_measurement_gr_calls(measurement = nil)
      measurement ||= meas

      stub_measurement_type_gr(measurement.total_id, ministry.gr_id)
      stub_measurement_type_gr(measurement.local_id, ministry.gr_id)
      stub_measurement_type_gr(measurement.person_id, user.gr_id)
    end

    def stub_measurement_type_gr(type_id, related_entity_id)
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}/measurement_types/#{type_id}?")
             .with(query: hash_including)
             .to_return(body: measurement_json(related_entity_id).to_json)
    end

    before do
      stub_measurement_gr_calls
    end

    let(:meas) { FactoryGirl.create(:measurement, perm_link: 'lmi_total_custom_shown', mcc_filter: nil) }
    let(:list) { MeasurementListReader.new(ministry_id: ministry.gr_id, mcc: 'DS') }

    it 'returns Measurements' do
      expect(list.load.first).to be_a Measurement
    end

    it 'loads the GR measurement values' do
      meas = list.load.first
      expect(meas.total).to eq 4
    end

    it 'filters by mcc_filter' do
      FactoryGirl.create(:measurement, mcc_filter: 'SLM')

      expect(list.load.count).to be 1

      meas.update(mcc_filter: 'DS')

      expect(list.load.count).to be 1
    end

    it 'filters by ministry hide_values and show_values' do
      meas2 = FactoryGirl.create(:measurement, perm_link: 'lmi_total_hidden')
      FactoryGirl.create(:measurement, perm_link: 'lmi_total_custom_not_shown')

      expect(list.load.count).to be 1

      meas.update(perm_link: 'lmi_total_not_hidden')
      meas2.update(perm_link: 'lmi_total_custom_asdf')

      expect(list.load.count).to be 1
    end

    describe 'info based on assignment' do
      it 'shows total to approved' do
        FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :admin)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.total).to_not be_nil
      end
      it 'hides total from self-assigned' do
        FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.total).to be_nil
      end

      it 'shows local to leaders' do
        parent_ministry = FactoryGirl.create(:ministry)
        ministry.update(parent: parent_ministry)
        FactoryGirl.create(:assignment, person: user, ministry: parent_ministry, role: :leader)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.local).to_not be_nil
      end
      it 'hides local from members' do
        FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :member)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.local).to be_nil
      end

      it 'shows personal to local' do
        FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :self_assigned)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.person).to_not be_nil
      end
      it 'hides personal from inherited' do
        parent_ministry = FactoryGirl.create(:ministry)
        ministry.update(parent: parent_ministry)
        FactoryGirl.create(:assignment, person: user, ministry: parent_ministry, role: :leader)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.person).to be_nil
      end

      it 'hides everything if blocked' do
        FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :blocked)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.person).to be_nil
        expect(@res.first.local).to be_nil
        expect(@res.first.total).to be_nil
      end
    end

    it 'loads historical data' do
      list.historical = true
      expect(list.load.first.total).to be_a Hash
      expect(list.load.first.total.count).to be 12
    end

    it 'folds children in parents' do
      child_meas = FactoryGirl.create(:measurement, parent: meas, perm_link: 'lmi_total_asdf')
      stub_measurement_gr_calls(child_meas)

      resp = list.load

      expect(resp.count).to be 1
      expect(resp.first.loaded_children.count).to be 1
      expect(resp.first.loaded_children.first.person).to eq 4
    end
  end
end
