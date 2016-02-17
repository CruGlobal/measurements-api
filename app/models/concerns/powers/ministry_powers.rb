module Powers
  module MinistryPowers
    extend ActiveSupport::Concern

    included do
      power :ministries do
        Ministry.all
      end

      power :createable_ministries do
        Ministry
      end
    end
  end
end
