class Timesheet < ActiveRecord::Base
  belongs_to :assigned_resource, class_name: 'AssignedResource', foreign_key: :assigned_resource_id

  validates :assigned_resource_id, presence: true
  validates :timesheet_date, presence: true
  validates :hours, presence: true

  validates_uniqueness_of :assigned_resource_id, scope: [:assigned_resource_id, :timesheet_date]
  validates_uniqueness_of :timesheet_date, scope: [:assigned_resource_id, :timesheet_date]

  before_create :date_check
  before_update :date_check

  def date_check
    if self.timesheet_date < self.assigned_resource.start_date or self.timesheet_date > self.assigned_resource.end_date
      raise I18n.t('errors.timesheet_outside_assignment_date_range')
    end
  end
end