class AddChildrenCountToChurch < ActiveRecord::Migration
  def change
    add_column :churches, :children_count, :integer, default: 0, null: false

    Church.find_each do |church|
      Church.reset_counters(church.id, :children)
    end
  end
end
