# frozen_string_literal: true

require "rails_helper"

RSpec.describe Measurement, type: :model do
  describe "#translation_for" do
    let(:top_level_ministry) { FactoryBot.create(:ministry) }
    let(:parent_ministry) { FactoryBot.create(:ministry, parent: top_level_ministry) }
    let(:ministry) { FactoryBot.create(:ministry, parent: parent_ministry) }

    let(:measurement) { FactoryBot.create(:measurement) }

    context "with translation at local level" do
      it "uses local instead of top_level" do
        FactoryBot.create(:measurement_translation, measurement: measurement,
                                                     ministry: top_level_ministry, language: "fr")
        local_trans = FactoryBot.create(:measurement_translation, measurement: measurement,
                                                                   ministry: ministry, language: "fr")

        expect(measurement.translation_for("fr", ministry)).to eq local_trans
      end
    end

    context "without translation at local level" do
      it "uses closed" do
        FactoryBot.create(:measurement_translation, measurement: measurement,
                                                     ministry: top_level_ministry, language: "fr")
        parent_trans = FactoryBot.create(:measurement_translation, measurement: measurement,
                                                                    ministry: parent_ministry, language: "fr")

        expect(measurement.translation_for("fr", ministry)).to eq parent_trans
      end
    end
  end
end
