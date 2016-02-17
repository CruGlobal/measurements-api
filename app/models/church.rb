class Church < ActiveRecord::Base
  belongs_to :parent, class_name: 'Church'
  has_many :children, class_name: 'Church', foreign_key: 'parent_id'

  belongs_to :created_by, class_name: 'Person', primary_key: 'person_id'

  has_many :church_values

  belongs_to :target_area, class_name: 'Ministry', primary_key: 'ministry_id'

  attr_accessor :parent_cluster_id

  before_save :default_values

  enum security: { local_private_church: 0, private_church: 1, public_church: 2 }
  authorize_values_for :security
  enum development: { target: 1, group_stage: 2, church: 3, multiplying_church: 5 }

  alias_attribute :ministry_id, :target_area_id
  alias_attribute :gr_id, :church_id

  validates :name, presence: { message: "Could not find required field: 'name'" }
  validates :target_area, presence: { message: "Could not find required field: 'ministry_id'" }
  validates :latitude, presence: true, exclusion: { in: [0], message: 'can not be %{value}' }
  validates :longitude, presence: true, exclusion: { in: [0], message: 'can not be %{value}' }

  def created_by_email
    created_by.try(:cas_username)
  end

  def value_at(period)
    return {} unless period
    begin
      period_date = Date.parse period
    rescue ArgumentError
      period_date = Date.parse("#{period}-01")
    end
    return {} if period_date < start_date || (end_date.present? && period_date > end_date)
    value = church_values.where('period <= ?', period).order(period: :desc).first.try(:attributes)
    value ||= attributes
    value.with_indifferent_access.slice(:size, :development)
  end

  def default_values
    self.development ||= 1
    self.security ||= :public_church
  end
end