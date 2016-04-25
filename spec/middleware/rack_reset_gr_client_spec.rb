# frozen_string_literal: true
require 'spec_helper'

describe RackResetGrClient do
  it 'sets GlobalRegistryClient parameters to empty and calls next in chain' do
    app = double(call: nil)
    env = double
    GlobalRegistryClient.parameters = { access_token: 'a' }

    ::RackResetGrClient.new(app).call(env)

    expect(GlobalRegistryClient.parameters).to eq({})
    expect(app).to have_received(:call).with(env)
  end
end
