class StaffingRequirement < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :pipeline, class_name: 'Pipeline', foreign_key: :pipeline_id
  belongs_to :skill, :class_name => 'Skill', :foreign_key => :skill_id
  belongs_to :designation, :class_name => 'Designation', :foreign_key => :designation_id

  has_many :assigned_resources, class_name: 'AssignedResource'

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :number_required, presence: true
  validates :hours_per_day, presence: true
  validates :pipeline_id, presence: true
  validates :skill_id, presence: true
  validates :designation_id, presence: true

  before_create :date_check, :hours_check
  before_update :date_check, :hours_check

  def skill_name
    Skill.find(self.skill_id).name
  end

  def date_check
    if self.start_date > self.end_date
      errors.add(:base, I18n.t('errors.date_check'))
      return false
    end
  end

  def hours_check
    if self.hours_per_day < 0 || self.hours_per_day > 24
      errors.add(:base, I18n.t('errors.hours_per_day'))
      return false
    end
  end

  def name
    '[' + self.id.to_s + '] [' + self.start_date.to_s + '] [' + self.end_date.to_s + '] ' + self.skill.name + ', ' + self.designation.name + ', ' + self.number_required.to_s + ' resources  required, ' + self.hours_per_day.to_s + ' hours per day'
  end

  def self.ordered_lookup(pipeline_id)
    StaffingRequirement.where(pipeline_id: pipeline_id).order(:start_date, :end_date)
  end

  def self.staffing_forecast(as_on, with_details)
    as_on = (as_on.nil?) ? Date.today : Date.parse(as_on.to_s)
    with_details = (with_details.to_s == 'true') ? true : false
    data = []
    StaffingRequirement.joins(:skill, :designation).where('? between start_date and end_date', as_on).order('skills.name').pluck('skills.id, skills.name, designations.id, designations.name, start_date, end_date').uniq.each do |sr|
      skill_id = sr[0]
      skill_name = sr[1]
      designation_id = sr[2]
      designation_name = sr[3]
      start_date = sr[4]
      end_date = sr[5]
      details = {}
      details['skill_name'] = skill_name
      details['designation_name'] = designation_name
      details['staffing_required'] = StaffingRequirement.where('skill_id = ? and designation_id = ? and ? between start_date and end_date', skill_id, designation_id, as_on).count
      details['staffing_fulfilled'] = StaffingRequirement.where('skill_id = ? and designation_id = ? and ? between start_date and end_date and fulfilled is true', skill_id, designation_id, as_on).count
      details['staffing_gap'] = details['staffing_required'] - details['staffing_fulfilled']
      details['deployable_resources'] = StaffingRequirement.deployable_resources(skill_id, designation_id, start_date, end_date, as_on, with_details)
      details['recruitment_need'] = [(details['staffing_gap'] - details['deployable_resources']['count']), 0].max
      data << details
    end
    result = {}
    result['data'] = data
    result
  end

  private

  def self.deployable_resources(skill_id, designation_id, start_date, end_date, as_on, with_details)
    as_on = (as_on.nil?) ? Date.today : Date.parse(as_on.to_s)
    with_details = (with_details.to_s == 'true') ? true : false
    deployable_resources = []
    count = 0
    Resource.latest(as_on).each do |r|
      deployable = true
      if r.skill_id == skill_id and r.admin_user.designation_id = designation_id
        (start_date..end_date).each do |d|
          unused_capacity_hours = Rails.configuration.max_work_hours_per_day - AssignedResource.assigned_hours(r.admin_user_id, d, d)
          if unused_capacity_hours <= 0
            deployable = false
            break
          end
        end
        if deployable
          count += 1
          if with_details
            deployable_resource_details = {}
            deployable_resource_details['admin_user_id'] = r.admin_user_id
            deployable_resource_details['admin_user_name'] = r.admin_user.name
            deployable_resource_details['bill_rate'] = r.bill_rate
            deployable_resource_details['cost_rate'] = r.cost_rate
            deployable_resources << deployable_resource_details
          end
        end
      end
    end
    result = {}
    result['count'] = deployable_resources.count
    if with_details
      result['deployable_resources'] = deployable_resources
    end
    result
  end
end