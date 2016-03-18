require 'rails_helper'

describe GrSync::MergeNotificationHandler do
  context '#merge_success_notification' do
    it "raises an exception because it's not implemented yet" do
      expect do
        GrSync::MergeNotificationHandler.new('1', '2').merge_success_notification
      end.to raise_error(/not implemented/)
    end
  end

  context '#merge_conflict_notification' do
    it "raises an exception because it's not implemented yet" do
      expect do
        GrSync::MergeNotificationHandler.new('1', '2').merge_conflict_notification
      end.to raise_error(/not implemented/)
    end
  end
end
