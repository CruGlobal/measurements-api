module Powers
  module MinistryPowers
    extend ActiveSupport::Concern

    included do
      # :index
      power :ministries do
        Ministry.all
      end

      power :showable_ministries do
        # Only leader may show a ministry
        if @assignment.blank? || !@assignment.leader_role?
          nil
        else
          @assignment.ministry
        end
      end

      # :create
      power :createable_ministries do
      end

      # :update
      power :updatable_ministries do
      end
    end
  end
end
