# frozen_string_literal: true

require "rails_helper"

RSpec.describe V5::MinistrySerializer do
  describe "a ministry" do
    let(:parent) { FactoryGirl.create(:ministry) }
    let(:ministry) do
      FactoryGirl.create(:ministry, parent: parent, default_mcc: Ministry::MCCS.sample,
                                    ministry_scope: Ministry::SCOPES.sample)
    end
    let!(:sub_ministries) do
      [FactoryGirl.create(:ministry, parent: ministry),
       FactoryGirl.create(:ministry, parent: ministry),
       FactoryGirl.create(:ministry, parent: ministry),]
    end
    let!(:assignments) do
      [FactoryGirl.create(:assignment, ministry: ministry, person: FactoryGirl.create(:person)),
       FactoryGirl.create(:assignment, ministry: ministry, person: FactoryGirl.create(:person)),
       FactoryGirl.create(:assignment, ministry: ministry, person: FactoryGirl.create(:person)),]
    end
    let!(:content_locales) do
      assignments.each do |assignment|
        FactoryGirl.create(:user_content_locale, ministry: ministry, person: assignment.person)
      end
    end
    let(:serializer) { V5::MinistrySerializer.new(ministry) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:json) { serialization.as_json }

    it "has attributes" do
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

    it "has correct attribute values" do
      expect(json[:ministry_id]).to eq(ministry.gr_id)
      expect(json[:parent_id]).to eq(parent.gr_id)
      expect(json[:name]).to eq(ministry.name)
      expect(json[:min_code]).to eq(ministry.min_code)
      expect(json[:ministry_id]).to eq(ministry.gr_id)
      expect(json[:location_zoom]).to eq(ministry.location_zoom)
      expect(json[:hide_reports_tab]).to eq(ministry.hide_reports_tab)
      expect(json[:lmi_show]).to match_array(ministry.lmi_show)
      expect(json[:lmi_hide]).to match_array(ministry.lmi_hide)
      expect(json[:mccs]).to match_array(ministry.mccs)
      expect(json[:content_locales]).to match_array(ministry.user_content_locales.pluck(:locale).uniq)
      expect(json[:team_members].length).to eq(ministry.assignments.length)
      expect(json[:sub_ministries].length).to eq(ministry.children.length)
    end
  end
end
