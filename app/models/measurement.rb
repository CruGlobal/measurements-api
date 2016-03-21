class Measurement < ActiveRecord::Base
  belongs_to :parent, class_name: 'Measurement'
  has_many :children, class_name: 'Measurement', foreign_key: :parent_id
  has_many :measurement_translations

  validates :person_id, presence: true
  validates :local_id, presence: true
  validates :total_id, presence: true

  attr_accessor :total, :local, :person, :loaded_children

  def initialize(attributes = nil, options = {})
    super(attributes, options)
    @translations = {}
  end

  def perm_link_stub
    perm_link.sub('lmi_total_custom_', '').sub('lmi_total_', '')
  end

  def localized_name(language, ministry)
    translation = translation_for(language, ministry)
    return english unless translation
    translation.name
  end

  def localized_description(language, ministry)
    translation = translation_for(language, ministry)
    return description unless translation
    translation.description
  end

  def locale(language, ministry)
    return language if translation_for language, ministry
    'en'
  end

  def translation_for(language, ministry)
    return unless language && ministry
    @translations ||= {}
    key = "#{language}-#{ministry}"
    return @translations[key] if @translations.key? key
    ministry = Ministry.find_by(id: ministry) unless ministry.is_a? Ministry
    return @translations[key] = nil unless ministry
    ministry = ministry.self_and_ancestors.joins(:measurement_translations).reorder(lft: :desc)
                       .find_by(measurement_translations: { language: language, measurement_id: id })
    @translations[key] = measurement_translations.find_by(language: language, ministry: ministry)
  end

  def self.find_by_perm_link(perm_link)
    perm_link = perm_link.sub('lmi_total_custom_', '').sub('lmi_total_', '')
    find_by(perm_link: ["lmi_total_#{perm_link}", "lmi_total_custom_#{perm_link}"])
  end
end
