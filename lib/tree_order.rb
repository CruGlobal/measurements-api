# frozen_string_literal: true

class TreeOrder
  def initialize(rows, id_field, parent_id_field)
    @rows = rows
    @id_field = id_field
    @parent_id_field = parent_id_field
    @ordered_rows = []
    @ordered_rows_set = Set.new
    @children = {}
  end

  def ordered_parents_first
    collect_children
    order_parents_first(nil)
    @ordered_rows
  end

  private

  def order_parents_first(parent_id)
    children = @children[parent_id]
    return unless children.present?
    children.each do |child|
      add_child(child)
      order_parents_first(child[@id_field])
    end
  end

  def add_child(child)
    !child.in?(@ordered_rows_set) || raise("Cycle found for #{child.inspect}")
    @ordered_rows_set << child
    @ordered_rows << child
  end

  def collect_children
    @rows.each do |row|
      parent_id = row[@parent_id_field]
      @children[parent_id] ||= []
      @children[parent_id] << row
    end
  end
end
