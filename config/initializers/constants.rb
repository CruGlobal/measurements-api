module Constants
  # Valid MCCs (Mission Critical Components)
  MCC_SLM = 'slm'.freeze
  MCC_LLM = 'llm'.freeze
  MCC_GCM = 'gcm'.freeze
  MCC_DS = 'ds'.freeze
  MCCS = [MCC_SLM, MCC_LLM, MCC_GCM, MCC_DS].freeze

  # area_code to min_code map
  AREAS = {
    EUER: 'EEC',
    NAME: 'MEC',
    AFFR: 'FFC',
    AAOP: 'AEP',
    NAOC: 'NAC',
    EUWE: 'EWO',
    AASE: 'ACC',
    AASO: 'ASC',
    AAOR: 'AET',
    AFSE: 'FEC',
    LAAM: 'LAC',
    AFWE: 'FWC',
    PACT: 'CAC'
  }.freeze

  # WHQ Scopes
  SCOPES = %w(National Area Global National\ Region).freeze

  # Team Roles
  LEADER_ROLE = 'leader'.freeze
  INHERITED_LEADER_ROLE = 'inherited_leader'.freeze
  ADMIN_ROLE = 'admin'.freeze
  INHERITED_ADMIN_ROLE = 'inherited_admin'.freeze
  MEMBER_ROLE = 'member'.freeze
  SELF_ASSIGNED_ROLE = 'self_assigned'.freeze
  BLOCKED_ROLE = 'blocked'.freeze
  FORMER_MEMBER_ROLE = 'former_member'.freeze

  VALID_ROLES = [
    LEADER_ROLE,
    INHERITED_LEADER_ROLE,
    ADMIN_ROLE,
    INHERITED_ADMIN_ROLE,
    MEMBER_ROLE,
    SELF_ASSIGNED_ROLE,
    BLOCKED_ROLE,
    FORMER_MEMBER_ROLE
  ].freeze

  VALID_INPUT_ROLES = [
    LEADER_ROLE,
    ADMIN_ROLE,
    MEMBER_ROLE,
    BLOCKED_ROLE,
    SELF_ASSIGNED_ROLE,
    FORMER_MEMBER_ROLE
  ].freeze

  LEADER_ROLES = [
    LEADER_ROLE,
    INHERITED_LEADER_ROLE,
    ADMIN_ROLE,
    INHERITED_ADMIN_ROLE
  ].freeze

  APPROVED_ROLES = [
    LEADER_ROLE,
    INHERITED_LEADER_ROLE,
    ADMIN_ROLE,
    INHERITED_ADMIN_ROLE,
    MEMBER_ROLE
  ].freeze

  APPROVED_LOCAL_ROLES = [
    LEADER_ROLE,
    ADMIN_ROLE,
    MEMBER_ROLE,
    FORMER_MEMBER_ROLE
  ].freeze

  LOCAL_LEADER_ROLES = [
    LEADER_ROLE,
    ADMIN_ROLE
  ].freeze

  INHERITED_ROLES = [
    INHERITED_LEADER_ROLE,
    INHERITED_ADMIN_ROLE
  ].freeze

  LOCAL_NOT_BLOCKED_ROLES = [
    LEADER_ROLE,
    ADMIN_ROLE,
    MEMBER_ROLE,
    SELF_ASSIGNED_ROLE
  ].freeze

  NOT_BLOCKED_ROLES = [
    LEADER_ROLE,
    INHERITED_LEADER_ROLE,
    ADMIN_ROLE,
    INHERITED_ADMIN_ROLE,
    MEMBER_ROLE,
    SELF_ASSIGNED_ROLE
  ].freeze

  BLOCKED_ROLES = [
    BLOCKED_ROLE,
    FORMER_MEMBER_ROLE
  ].freeze
end
