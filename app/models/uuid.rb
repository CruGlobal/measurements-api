# frozen_string_literal: true

class Uuid
  def self.uuid?(id)
    return postgres_uuid?(id) unless id.blank? || !id.is_a?(String)
    false
  end

  # note:
  # postgresql's uuid acceptability rules[http://www.postgresql.org/docs/9.1/static/datatype-uuid.html]
  # are different from IETF's[http://tools.ietf.org/html/rfc4122]
  def self.postgres_uuid?(id)
    four_hex_digits = "[[:xdigit:]]{4}"
    eight_hex_digit_groups = "(#{four_hex_digits}-?){7}#{four_hex_digits}"
    /\A(#{eight_hex_digit_groups}|({#{eight_hex_digit_groups}}))\z/ =~ id
  end
end
