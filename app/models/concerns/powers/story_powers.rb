module Powers
  module StoryPowers
    extend ActiveSupport::Concern

    included do
      power :stories do
        # All public stories or all stories on the ministry
        table = Story.arel_table
        query = table[:privacy].eq(Story.privacies[:everyone])
        if assignment.try(:approved_role?) || inherited_assignment.try(:leader_role?)
          query = query.or(table[:ministry_id].eq(ministry.id))
        end
        Story.where(query).order(created_at: :desc).distinct
      end

      power :show_stories do
        table = Story.arel_table
        query = if inherited_assignment.try(:leader_role?)
                  # Leader Roles can see all stories at the ministry
                  table[:ministry_id].eq(ministry.id)
                elsif assignment.try(:approved_role?)
                  # Approved roles can see published stories
                  table[:ministry_id].eq(ministry.id).and(table[:state].eq(Story.states[:published]))
                else
                  # Everyone else can see public, published stories
                  table[:privacy].eq(Story.privacies[:everyone]).and(table[:state].eq(Story.states[:published]))
                end
        # User can see stories they created
        query = query.or(table[:created_by_id].eq(user.id))
        Story.where(query)
      end

      power :update_stories do
        # Leaders can update any stories at the ministry
        break Story.where(ministry_id: ministry.id) if inherited_assignment.try(:leader_role?)
        # Everyone can update their own stories
        Story.where(created_by_id: user.id)
      end

      power :create_story do
        Story::UserCreatedStory
      end
    end

    def assignable_story_ministries
      return [assignment.ministry] if assignment.try(:approved_role?)
      [inherited_assignment.ministry] if inherited_assignment.try(:approved_role?)
    end
  end
end
