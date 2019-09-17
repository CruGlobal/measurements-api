# frozen_string_literal: true

require "spec_helper"

describe SidekiqResetGrClient do
  it "sets GlobalRegistryClient parameters to empty and yields control" do
    GlobalRegistryClient.parameters = {access_token: "a"}

    expect { |b|
      SidekiqResetGrClient.new.call(double("worker"), double("job"), double("q"), &b)
    }.to yield_control

    expect(GlobalRegistryClient.parameters).to eq({})
  end
end
