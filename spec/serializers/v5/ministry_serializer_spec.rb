require 'rails_helper'

RSpec.describe V5::MinistrySerializer do
  describe 'a ministry' do
    let(:parent) { FactoryGirl.create(:ministry) }
    let(:ministry) { FactoryGirl.create(:ministry, parent: parent) }
    let!(:sub_ministries) do
      [FactoryGirl.create(:ministry, parent: ministry),
       FactoryGirl.create(:ministry, parent: ministry),
       FactoryGirl.create(:ministry, parent: ministry)]
    end
    let!(:assignments) do
      [FactoryGirl.create(:assignment, ministry: ministry, person: FactoryGirl.create(:person)),
       FactoryGirl.create(:assignment, ministry: ministry, person: FactoryGirl.create(:person)),
       FactoryGirl.create(:assignment, ministry: ministry, person: FactoryGirl.create(:person))]
    end
    let!(:content_locales) do
      assignments.each do |assignment|
        FactoryGirl.create(:user_content_locale, ministry: ministry, person: assignment.person)
      end
    end
    let(:serializer) { V5::MinistrySerializer.new(ministry) }
    let(:serialization) { ActiveModel::Serializer::Adapter.create(serializer) }
    let(:json) { serialization.as_json }

    it 'have attributes' do
      expect(json[:ministry_id]).to be_uuid
      expect(json[:name]).to_not be_nil
      expect(json[:min_code]).to_not be_nil
      expect(json[:location]).to be_a Hash
      expect(json[:location][:latitude]).to be_a Float
      expect(json[:location][:longitude]).to be_a Float
      expect(json[:location_zoom]).to be_an Integer
      expect(json[:lmi_show]).to be_an Array
      expect(json[:lmi_hide]).to be_an Array
      expect(json[:mccs]).to be_an Array
      expect(json[:parent_id]).to be_uuid
      expect(json[:hide_reports_tab]).to_not be_nil
      expect(json[:team_members]).to be_an Array
      expect(json[:sub_ministries]).to be_an Array
      expect(json[:content_locales]).to be_an Array
      expect(json).to include(:default_mcc, :ministry_scope)
    end

    it 'have correct attribute values' do
      expect(json[:ministry_id]).to be ministry.gr_id
      expect(json[:parent_id]).to be parent.gr_id
      expect(json[:name]).to be ministry.name
      expect(json[:min_code]).to be ministry.min_code
      expect(json[:ministry_id]).to be ministry.gr_id
      expect(json[:location_zoom]).to be ministry.location_zoom
      expect(json[:hide_reports_tab]).to be ministry.hide_reports_tab
      expect(json[:lmi_show]).to match_array(ministry.lmi_show)
      expect(json[:lmi_hide]).to match_array(ministry.lmi_hide)
      expect(json[:mccs]).to match_array(ministry.mccs)
      expect(json[:content_locales]).to match_array(ministry.user_content_locales.pluck(:locale).uniq)
      expect(json[:team_members].length).to be ministry.assignments.length
      expect(json[:sub_ministries].length).to be ministry.children.length
    end
  end
end
