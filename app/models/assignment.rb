class Assignment < ActiveRecord::Base
  enum role: { blocked: 0, former_member: 1, self_assigned: 2, member: 3,
               inherited_leader: 4, leader: 5, inherited_admin: 6, admin: 7 }

  belongs_to :person, foreign_key: :person_id, primary_key: :person_id
  validates :person, presence: { message: '\'person_id\' missing or invalid' }

  belongs_to :ministry, foreign_key: :ministry_id, primary_key: :ministry_id
  validates :ministry, presence: { message: '\'ministry_id\' missing or invalid' }

  # Alias team_role to role - json model uses team_role
  alias_attribute :team_role, :role
  validates :role, presence: true
  validates :role, inclusion: { in: roles, message: '\'%{value}\' is not a valid Team Role' }

  def approved?
    %w(leader inherited_leader admin inherited_admin member).include? role
  end
end
