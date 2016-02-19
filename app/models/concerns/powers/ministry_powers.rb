module Powers
  module MinistryPowers
    extend ActiveSupport::Concern

    included do
      # :index
      power :ministries do
        Ministry.all
      end

      power :show_ministry do
        # Only leader may show a ministry
        (@assignment.blank? || !@assignment.leader_role?) ? nil : @assignment.ministry
      end

      # :create
      power :create_ministry do
        # Anyone can create Ministries, only leaders of a ministry can create sub-ministries
        (@assignment.present? && !@assignment.leader_role?) ? nil : ::Ministry::UserCreatedMinistry
      end

      # :update
      power :update_ministry do
        # Only leaders may update a ministry
        if @assignment.present? && @assignment.leader_role?
          # TODO: Only leaders of both ministries may move a ministry
          @assignment.ministry
        end
        nil
      end
    end

    def assignable_ministry_parents(_ministry)
    end
  end
end
