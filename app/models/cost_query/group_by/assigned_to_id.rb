class CostQuery::GroupBy
  class AssignedToId < Base
    join_table Issue
    applies_for :label_issue_attributes

    def self.label
      Issue.human_attribute_name(:assigned_to)
    end
  end
end
