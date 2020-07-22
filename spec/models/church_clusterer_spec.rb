# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChurchClusterer, type: :model do
  let!(:nearby_church1) { FactoryBot.build_stubbed(:church, latitude: 0, longitude: 1) }
  let!(:nearby_church2) { FactoryBot.build_stubbed(:church, latitude: 0, longitude: 2) }
  let!(:distant_church) do
    FactoryBot.build_stubbed(:church, latitude: 10, longitude: 1,
                                       parent: nearby_church2)
  end
  let!(:distant_orphan_church) do
    FactoryBot.build_stubbed(:church, latitude: 10, longitude: 5)
  end
  let(:church_array) do
    [distant_church, nearby_church1, nearby_church2, distant_orphan_church]
  end

  context "cluster by lat/long" do
    it "clusters some but not all" do
      filters = {lat_min: 0, lat_max: 20, long_min: 0, long_max: 20}
      filtered = ChurchClusterer.new(filters).cluster(church_array)

      cluster = filtered.find { |e| e.is_a? Array }
      distant_entry = filtered.find { |e| e.try(:id) == distant_church.id }
      orphan_entry = filtered.find { |e| e.try(:id) == distant_orphan_church.id }
      expect(cluster).to be_present
      expect(distant_entry.id).to be distant_church.id
      expect(distant_entry.parent_cluster_id).to be cluster.first.id
      expect(orphan_entry.parent_cluster_id).to be nil
    end
  end
end
