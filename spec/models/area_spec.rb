# frozen_string_literal: true
require 'spec_helper'

describe Area do
  context '.for_code' do
    it 'returns nil for nil' do
      expect(Area.for_code(nil)).to be_nil
    end
  end

  context '.for_gr_id' do
    it 'returns nil for nil' do
      expect(Area.for_gr_id(nil)).to be_nil
    end
  end
end
