# frozen_string_literal: true
require 'rails_helper'

describe Church, type: :model do
  describe 'created_by relationship' do
    let(:person) { Person.new(gr_id: SecureRandom.uuid) }
    let(:church) { FactoryGirl.build_stubbed(:church, created_by: person) }

    it 'has creator' do
      expect(church.created_by).to eq person
    end
  end
end
