class HolidayCalendar < ActiveRecord::Base
  belongs_to :business_unit, :class_name => 'Lookup', :foreign_key => :business_unit_id

  validates :name, presence: true
  validates :as_on, presence: true
  validates :business_unit_id, presence: true

  validates_uniqueness_of :name, scope: [:name, :as_on, :business_unit_id]
  validates_uniqueness_of :as_on, scope: [:name, :as_on, :business_unit_id]
  validates_uniqueness_of :business_unit_id, scope: [:name, :as_on, :business_unit_id]
end