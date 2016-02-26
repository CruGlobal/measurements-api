class Ministry < ActiveRecord::Base
  # Valid MCCs (Mission Critical Components)
  MCC_SLM = 'slm'.freeze
  MCC_LLM = 'llm'.freeze
  MCC_GCM = 'gcm'.freeze
  MCC_DS = 'ds'.freeze
  MCCS = [MCC_SLM, MCC_LLM, MCC_GCM, MCC_DS].freeze

  # WHQ Scopes
  SCOPES = %w(National Area Global National\ Region).freeze

  include GlobalRegistry::EntityMethods
  include GlobalRegistry::Ministry

  acts_as_nested_set dependent: :nullify

  scope :inherited_ministries, lambda { |person|
    joins(inherited_ministry_join)
      .joins(assignment_join)
      .where(assignments: { person_id: person.id } )
      .where(assignments: Assignment.local_leader_condition)
      .distinct
  }

  has_many :assignments, dependent: :destroy, inverse_of: :ministry
  has_many :people, through: :assignments

  has_many :user_content_locales, dependent: :destroy

  auto_strip_attributes :name

  validates :name, presence: true
  validates :default_mcc, inclusion: { in: MCCS, message: '\'%{value}\' is not a valid MCC' },
                          unless: 'default_mcc.blank?'

  authorize_values_for :parent_id, message: 'Only leaders of both ministries may move a ministry'

  # Find Ministry by gr_id, update from Global Registry if nil or refresh is true
  def self.ministry(gr_id, refresh = false)
    ministry = find_by(gr_id: gr_id)
    if ministry.nil? || refresh
      ministry = new(gr_id: gr_id) if ministry.nil?
      entity = ministry.update_from_entity
      return nil if entity.nil? || (entity.key?(:is_active) && entity[:is_active] == false)
      ministry.save
    end
    ministry
  end

  def descendants_ids
    children.map do |child|
      child.descendants_ids.append child.id
    end.flatten
  end

  protected

  # Walks ministry ancestors until it finds a ministry with a WHQ scope
  def parent_whq_ministry(ministry = nil)
    return nil if ministry.nil?
    return ministry if SCOPES.include?(ministry.ministry_scope)
    parent_whq_ministry(ministry.parent)
  end

  class << self
    private

    # Arel methods
    def inherited_ministry_join
      arel_table
        .join(arel_table.alias('self'))
        .on(inherited_left_condition.and(inherited_right_condition))
        .join_sources
    end

    def inherited_left_condition
      arel_table.alias('self')[left_column_name].lteq(arel_table[left_column_name])
    end

    def inherited_right_condition
      arel_table.alias('self')[right_column_name].gteq(arel_table[right_column_name])
    end

    def assignment_join
      arel_table
        .join(Assignment.arel_table)
        .on(Assignment.arel_table[:ministry_id].eq(arel_table.alias('self')[:id]))
        .join_sources
    end
  end
end
