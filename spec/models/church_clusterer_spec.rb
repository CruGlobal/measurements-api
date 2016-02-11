require 'rails_helper'

RSpec.describe ChurchClusterer, type: :model do
  let!(:nearby_church1) { FactoryGirl.build_stubbed(:church, latitude: 0, longitude: 1) }
  let!(:nearby_church2) { FactoryGirl.build_stubbed(:church, latitude: 0, longitude: 2) }
  let!(:distant_church) do
    FactoryGirl.build_stubbed(:church, latitude: 10, longitude: 1,
                                       parent_id: nearby_church2.church_id)
  end
  let(:church_array) do
    [distant_church, nearby_church1, nearby_church2]
  end

  context 'cluster by lat/long' do
    it 'clusters some but not all' do
      filters = { lat_min: 0, lat_max: 20, long_min: 0, long_max: 20 }
      filtered = ChurchClusterer.new(filters).cluster(church_array)

      cluster = filtered.find { |e| e.is_a? Array }
      distant_entry = filtered.find { |e| e.try(:id) == distant_church.id }
      expect(cluster).to be_present
      expect(distant_entry.id).to be distant_church.id
      expect(distant_entry.parent_cluster_id).to be cluster.first.id
    end
  end
end
