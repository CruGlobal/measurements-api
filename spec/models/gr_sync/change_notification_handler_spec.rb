# frozen_string_literal: true
require 'rails_helper'

describe GrSync::ChangeNotificationHandler do
  it 'creates or updates from entity for create notification' do
    expect_created_or_updated_from_entity(:created_notification)
  end

  it 'creates or updates from entity for update notification' do
    expect_created_or_updated_from_entity(:updated_notification)
  end

  def expect_created_or_updated_from_entity(notification_method)
    entity = {
      'person' => { 'id' => '1f', 'name' => 'Joe' }
    }
    client = double(find: entity)
    allow(GlobalRegistryClient).to receive(:client) { client }
    allow(Person).to receive(:create_or_update_from_entity!)

    GrSync::ChangeNotificationHandler.new('person', '1f')
                                     .public_send(notification_method)

    expect(client).to have_received(:find).with('1f')
    expect(Person).to have_received(:create_or_update_from_entity!).with(entity)
  end

  # it 'deletes a record if deleted in global registry' do
  #   person = create(:person)
  #
  #   expect do
  #     GrSync::ChangeNotificationHandler.new('person', person.gr_id)
  #                                      .deleted_notification
  #   end.to change(Person, :count).by(-1)
  # end

  it 'does not error for delete notification for non-existent record' do
    expect do
      GrSync::ChangeNotificationHandler.new('person', '1').deleted_notification
    end.to_not raise_error
  end
end
