class CostAdderType < ActiveRecord::Base
  self.primary_key = 'id'

  has_many :overheads, class_name: 'Overhead'
  has_many :project_overheads, class_name: 'ProjectOverhead'
end