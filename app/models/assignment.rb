# frozen_string_literal: true
class Assignment < ActiveRecord::Base
  APPROVED_ROLES = %w(leader inherited_leader admin inherited_admin member).freeze
  LOCAL_APPROVED_ROLES = %w(leader admin member).freeze
  LOCAL_LEADER_ROLES = %w(leader admin).freeze
  VALID_INPUT_ROLES = %w(leader admin member self_assigned blocked former_member).freeze
  LEADER_ROLES = %w(leader admin inherited_leader inherited_admin).freeze
  INHERITED_ROLES = %w(inherited_leader inherited_admin).freeze
  BLOCKED_ROLES = %w(blocked former_member).freeze

  enum role: { blocked: 0, former_member: 1, self_assigned: 2, member: 3,
               inherited_leader: 4, leader: 5, inherited_admin: 6, admin: 7 }

  belongs_to :person
  validates :person, presence: { message: '\'person_id\' missing or invalid' }

  belongs_to :ministry
  validates :ministry, presence: { message: '\'ministry_id\' missing or invalid' }

  # Alias team_role to role - json model uses team_role
  alias_attribute :team_role, :role
  validates :role, presence: true
  validates :role, inclusion: { in: VALID_INPUT_ROLES, message: '\'%{value}\' is not a valid Team Role' }
  authorize_values_for :role

  scope :leaders, -> { where(leader_condition) }
  scope :local_leaders, -> { where(local_leader_condition) }
  scope :local_approved, -> { where(local_approved_condition) }

  scope :ancestor_assignments, lambda { |ministry|
    joins(ministries_join)
      .joins(inherited_ministries_join)
      .where(ministry_condition(ministry.id).and(assignment_condition(ministry.id)))
      .order(ministry_ordering)
  }

  def approved_role?
    APPROVED_ROLES.include? role
  end

  def leader_role?(include_inherited = true)
    (include_inherited ? LEADER_ROLES : LOCAL_LEADER_ROLES).include? role
  end

  def self.leader_condition
    { role: roles.slice(*LEADER_ROLES).values }
  end

  def self.local_leader_condition
    { role: roles.slice(*LOCAL_LEADER_ROLES).values }
  end

  def self.approved_condition
    { role: roles.slice(*APPROVED_ROLES).values }
  end

  def self.local_approved_condition
    { role: roles.slice(*LOCAL_APPROVED_ROLES).values }
  end

  def inherited_role?
    INHERITED_ROLES.include? role
  end

  def blocked_role?
    BLOCKED_ROLES.include? role
  end

  def as_inherited_assignment(min_id = nil)
    return nil unless leader_role?
    Assignment.new(person_id: person_id,
                   ministry_id: min_id.present? ? min_id : ministry_id,
                   role: inherited_role? ? role : "inherited_#{role}".to_sym)
  end

  def create_gr_relationship
    GrSync::AssignmentPush.new(self).push_to_gr
  end

  class << self
    private

    def ministry_table
      Ministry.arel_table
    end

    def inherited_ministry_table
      Ministry.arel_table.alias('inherited')
    end

    def ministries_join
      arel_table
        .join(ministry_table)
        .on(ministry_table[:id].eq(arel_table[:ministry_id]))
        .join_sources
    end

    def inherited_ministries_join
      arel_table
        .join(inherited_ministry_table)
        .on(inherited_left_condition.and(inherited_right_condition))
        .join_sources
    end

    def inherited_left_condition
      inherited_ministry_table[Ministry.left_column_name].gteq(ministry_table[Ministry.left_column_name])
    end

    def inherited_right_condition
      inherited_ministry_table[Ministry.right_column_name].lteq(ministry_table[Ministry.right_column_name])
    end

    def assignment_condition(ministry_id)
      arel_table[:ministry_id].eq(ministry_id).or(arel_table[:role].in(local_leader_condition[:role]))
    end

    def ministry_condition(ministry_id)
      inherited_ministry_table[:id].eq(ministry_id)
    end

    def ministry_ordering
      ministry_table[:lft].desc
    end
  end
end
