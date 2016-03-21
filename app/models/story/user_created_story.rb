class Story
  class UserCreatedStory < ::Story
    after_create :write_audit, if: 'published?'

    validates :title, presence: true

    def write_audit
      Audit.create(ministry_id: ministry_id, person_id: created_by_id, audit_type: :new_story,
                   message: "#{created_by.full_name} added a story.")
    end
  end
end
