# frozen_string_literal: true

class Church < ApplicationRecord
  has_many :children, class_name: "Church", foreign_key: :parent_id
  belongs_to :parent, class_name: "Church", counter_cache: :children_count, optional: true

  belongs_to :created_by, class_name: "Person", optional: true

  has_many :church_values
  has_many :stories, dependent: :nullify

  belongs_to :ministry, optional: true
  authorize_values_for :ministry

  attr_accessor :parent_cluster_id

  before_save :default_values

  after_update :log_church_value

  enum security: {local_private_church: 0, private_church: 1,
                  registered_public_church: 2, global_public_church: 3,}
  authorize_values_for :security
  enum development: {target: 1, group_stage: 2, church: 3, multiplying_church: 5}

  validates :latitude, presence: true, exclusion: {in: [0], message: "can not be %{value}"}
  validates :longitude, presence: true, exclusion: {in: [0], message: "can not be %{value}"}

  def created_by_email
    created_by.try(:cas_username)
  end

  def value_at(period, values)
    return {} unless period && values
    begin
      period_date = Date.parse period
    rescue ArgumentError
      period_date = Date.parse("#{period}-01")
    end
    return {} if period_date.end_of_month < start_date ||
      (end_date.present? && period_date > end_date)
    value = values[id].try(:first).try(:attributes)
    value ||= attributes
    value.with_indifferent_access.slice(:size, :development)
  end

  def default_values
    self.development ||= 1
    self.security ||= :registered_public_church
    self.parent_id = nil if parent_id == -1
  end

  def log_church_value
    return unless saved_change_to_size? || saved_change_to_development?
    period = Time.zone.today.strftime("%Y-%m")
    value = church_values.where(period: period).first_or_initialize
    value.update(size: size, development: self[:development])
  end
end
