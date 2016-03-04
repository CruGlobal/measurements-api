class Measurement < ActiveRecord::Base
  belongs_to :parent, class_name: 'Measurement'
  has_many :measurement_translations

  validates :person_id, presence: true
  validates :local_id, presence: true
  validates :total_id, presence: true

  attr_accessor :total, :local, :person

  def initialize(attributes = nil, options = {})
    super(attributes, options)
    @translations = {}
  end

  def perm_link_stub
    perm_link.sub('lmi_total_custom_', '').sub('lmi_total_', '')
  end

  def localized_name(language, ministry)
    ministry = ministry.id if ministry.is_a? Ministry
    translation = translation_for(language, ministry)
    return english unless translation
    translation.name
  end

  def localized_description(language, ministry)
    ministry = ministry.id if ministry.is_a? Ministry
    translation = translation_for(language, ministry)
    return description unless translation
    translation.description
  end

  def locale(language, ministry_id)
    return language if measurement_translations.where(language: language, ministry_id: ministry_id).any?
    'en'
  end

  def translation_for(language, ministry_id)
    return unless language && ministry_id
    key = "#{language}-#{ministry_id}"
    return @translations[key] if @translations[key].present?
    @translations[key] = measurement_translations.find_by(language: language, ministry_id: ministry_id)
  end

  def self.find_by_perm_link(perm_link)
    find_by(perm_link: ["lmi_total_#{perm_link}", "lmi_total_custom_#{perm_link}"])
  end
end
