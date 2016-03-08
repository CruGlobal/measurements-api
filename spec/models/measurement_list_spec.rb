require 'rails_helper'

RSpec.describe MeasurementList, type: :model do
  let(:user) { FactoryGirl.create(:person) }
  let(:ministry) { FactoryGirl.create(:ministry, lmi_hide: ['hidden'], lmi_show: ['shown']) }

  describe '#new' do
    let(:list) { MeasurementList.new }

    it 'has default values' do
      expect(list.period).to eq Time.zone.today.strftime('%Y-%m')
      expect(list.source).to eq 'gma-app'
    end
  end

  describe '#load' do
    def measurement_json(related_entity_id)
      {
        measurement_type: {
          perm_link: 'LMI',
          measurements: [
            {
              id: SecureRandom.uuid,
              period: '2015-04',
              value: '4.0',
              related_entity_id: related_entity_id
            }
          ]
        }
      }
    end

    before do
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{meas.total_id}?")
             .with(query: hash_including)
             .to_return(body: measurement_json(ministry.gr_id).to_json)
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{meas.local_id}")
             .with(query: hash_including)
             .to_return(body: measurement_json(ministry.gr_id).to_json)
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{meas.person_id}")
             .with(query: hash_including)
             .to_return(body: measurement_json(user.gr_id).to_json)
    end

    let(:meas) { FactoryGirl.create(:measurement, perm_link: 'lmi_total_custom_shown', mcc_filter: nil) }
    let(:list) { MeasurementList.new(ministry_id: ministry.gr_id, mcc: 'DS') }

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

    it 'loads historical data'
  end
end
