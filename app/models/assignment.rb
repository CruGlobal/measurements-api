class Assignment < ActiveRecord::Base
  APPROVED_ROLES = %w(leader inherited_leader admin inherited_admin member).freeze
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

  scope :leaders, -> { where(leader_condition) }
  scope :local_leaders, -> { where(local_leader_condition) }

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

  def inherited_role?
    INHERITED_ROLES.include? role
  end

  def blocked_role?
    BLOCKED_ROLES.include? role
  end
end
