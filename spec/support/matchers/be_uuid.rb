# frozen_string_literal: true
RSpec::Matchers.define :be_uuid do
  match do |actual|
    return false unless actual.is_a? String
    four_hex_digits = '[[:xdigit:]]{4}'
    eight_hex_digit_groups = "(#{four_hex_digits}-?){7}#{four_hex_digits}"
    /\A(#{eight_hex_digit_groups}|({#{eight_hex_digit_groups}}))\z/ =~ actual
  end
end
