# frozen_string_literal: true
class ChurchValue < ActiveRecord::Base
  belongs_to :church

  def self.values_for(church_ids, period)
    key = "#{self.class}/#{period}/#{church_ids.join(',')}"
    Rails.cache.fetch(key, expires_in: 1.minute) do
      subquery = ChurchValue.select('church_id, max(period) as max_period')
                            .where('period <= ?', period)
                            .group(:church_id).to_sql
      ChurchValue.joins("JOIN (#{subquery}) max_vals ON church_values.church_id = max_vals.church_id"\
                        ' AND church_values.period = max_vals.max_period').group_by(&:church_id)
    end
  end
end
