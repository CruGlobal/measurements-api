class Story < ActiveRecord::Base
  enum privacy: { everyone: 0, team_only: 1 }
  enum state: { draft: 0, published: 1, removed: 2 }

  belongs_to :ministry
  belongs_to :created_by, class_name: 'Person'
  belongs_to :church
  belongs_to :training

  mount_uploader :image, ImageUploader

  validates :title, :content, presence: true
  validates :mcc, inclusion: { in: Ministry::MCCS, message: '\'%{value}\' is not a valid MCC' }, unless: 'mcc.blank?'
  validates :church, presence: true, unless: 'church_id.blank?'
  validates :training, presence: true, unless: 'training_id.blank?'
  authorize_values_for :ministry, message: 'INSUFFICIENT_RIGHTS - You must have an approved role for the ministry.'

  attr_accessor :location

  # Virtual attributes
  attr_accessor :person_gr_id, :ministry_gr_id
  before_validation :lookup_person, if: 'person_gr_id.present?'
  before_validation :lookup_ministry, if: 'ministry_gr_id.present?'

  def location=(value)
    return unless value.is_a? Hash
    value = value.with_indifferent_access
    self.latitude = value[:latitude] if value.key?(:latitude)
    self.longitude = value[:longitude] if value.key?(:longitude)
  end

  private

  def lookup_person
    self.created_by_id = Person.find_by(gr_id: person_gr_id).try(:id)
  end

  def lookup_ministry
    self.ministry = Ministry.ministry(ministry_gr_id)
  end
end
