class Lookup < ActiveRecord::Base
  belongs_to :lookup_type, :class_name => 'LookupType', :foreign_key => :lookup_type_id

  has_many :vacation_reasons, :class_name => 'VacationReason'

  validates :value, presence: true
  validates :rank, presence: true
  validates :lookup_type_id, presence: true

  validates_uniqueness_of :value, scope: [:lookup_type_id]
  validates_uniqueness_of :rank, scope: [:lookup_type_id]
end
