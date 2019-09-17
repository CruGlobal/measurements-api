# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChurchValue, type: :model do
  describe "#values_for" do
    let(:church) { FactoryGirl.create(:church, size: 2, development: 2) }

    it "not to fail if there aren't " do
      expect { ChurchValue.values_for([church.id], "2016-01") }.to_not raise_error
    end

    it "returns array with one value each" do
      FactoryGirl.create(:church_value, church: church, period: "2015-11", size: 4, development: 4)
      FactoryGirl.create(:church_value, church: church, period: "2015-12", size: 3, development: 3)

      values = ChurchValue.values_for([church.id], "2016-01")

      expect(values[church.id].first.size).to eq 3
    end
  end
end
