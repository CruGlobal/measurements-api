require 'rails_helper'

describe Church, type: :model do
  describe 'created_by relationship' do
    let(:person) { Person.new(person_id: SecureRandom.uuid) }
  end
end
