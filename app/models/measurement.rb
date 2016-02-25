class Measurement < ActiveRecord::Base
  belongs_to :parent, class_name: 'Measurement'
  has_many :measurement_translations

  def perm_link_stub
    perm_link.sub('lmi_total_custom_', '').sub('lmi_total_', '')
  end

  def localized_name(language, ministry)
    ministry = ministry.id if ministry.is_a? Ministry
    translation = measurement_translations.find_by(language: language, ministry: ministry)
    return english unless translation
    translation.name
  end

  def localized_description(language, ministry)
    ministry = ministry.id if ministry.is_a? Ministry
    translation = measurement_translations.find_by(language: language, ministry: ministry)
    return description unless translation
    translation.description
  end

  def self.find_by_perm_link(perm_link)
    find_by(perm_link: ["lmi_total_#{perm_link}", "lmi_total_custom_#{perm_link}"])
  end
end
