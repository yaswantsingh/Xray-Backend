class InvoicingMilestone < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :project, class_name: 'Project', foreign_key: :project_id

  has_many :delivery_invoicing_milestones, class_name: 'DeliveryInvoicingMilestone'
  has_many :invoice_lines, class_name: 'InvoiceLine'

  validates :project_id, presence: true
  validates :name, presence: true
  validates :due_date, presence: true
  validates :amount, presence: true

  validates_uniqueness_of :project_id, scope: [:project_id, :name, :due_date]
  validates_uniqueness_of :name, scope: [:project_id, :name, :due_date]
  validates_uniqueness_of :due_date, scope: [:project_id, :name, :due_date]

  def invoicing_milestone_name
    'Id: [' + self.id.to_s + '], Name: [' + self.name + '], Due Date: [' + self.due_date.to_s + '], Amount: [' + self.amount.to_s + '], Uninvoiced: [' + self.uninvoiced.to_s + ']'
  end

  def project_name
    self.project.name
  end

  def uninvoiced
    self.amount - InvoiceLine.where(invoicing_milestone_id: self.id).sum(:line_amount)
  end

  def self.ordered_lookup(project_id)
    InvoicingMilestone.where(project_id: project_id).order(:name)
  end

  def self.invoicing_milestones_for_project(project_id)
    InvoicingMilestone.where(project_id: project_id).order(:due_date)
  end

  def self.invoicing_milestones(as_on, due_status, completion_status)
    as_on = (as_on.nil?) ? Date.today : Date.parse(as_on.to_s)
    data = []
    if due_status.upcase == 'DUE' and completion_status.upcase == 'INCOMPLETE'
      InvoicingMilestone.where('due_date <= ? and completion_date is null', as_on).order('due_date').each do |im|
        details = {}
        details['id'] = im.id
        details['name'] = im.name
        details['amount'] = im.amount
        details['uninvoiced'] = im.uninvoiced
        details['remaining'] = im.amount - im.uninvoiced
        details['due_date'] = im.due_date.to_s
        details['last_reminder_date'] = im.last_reminder_date
        details['completion_date'] = im.completion_date.to_s
        details['project'] = im.project.name
        details['client'] = im.project.pipeline.client.name
        details['business_unit'] = im.project.business_unit_name
        data << details
      end
    elsif due_status.upcase == 'DUE' and completion_status.upcase == 'COMPLETE'
      InvoicingMilestone.where('due_date <= ? and completion_date is not null', as_on).order('due_date').each do |im|
        details = {}
        details['id'] = im.id
        details['name'] = im.name
        details['amount'] = im.amount
        details['uninvoiced'] = im.uninvoiced
        details['remaining'] = im.amount - im.uninvoiced
        details['due_date'] = im.due_date.to_s
        details['last_reminder_date'] = im.last_reminder_date
        details['completion_date'] = im.completion_date.to_s
        details['project'] = im.project.name
        details['client'] = im.project.pipeline.client.name
        details['business_unit'] = im.project.business_unit_name
        data << details
      end
    elsif due_status.upcase == 'DUE' and completion_status.upcase == 'ALL'
      InvoicingMilestone.all.order('due_date').each do |im|
        details = {}
        details['id'] = im.id
        details['name'] = im.name
        details['amount'] = im.amount
        details['uninvoiced'] = im.uninvoiced
        details['remaining'] = im.amount - im.uninvoiced
        details['due_date'] = im.due_date.to_s
        details['last_reminder_date'] = im.last_reminder_date
        details['completion_date'] = im.completion_date.to_s
        details['project'] = im.project.name
        details['client'] = im.project.pipeline.client.name
        details['business_unit'] = im.project.business_unit_name
        data << details
      end
    elsif due_status.upcase == 'FUTURE' and completion_status.upcase == 'INCOMPLETE'
      InvoicingMilestone.where('due_date > ? and completion_date is null', as_on).order('due_date').each do |im|
        details = {}
        details['id'] = im.id
        details['name'] = im.name
        details['amount'] = im.amount
        details['uninvoiced'] = im.uninvoiced
        details['remaining'] = im.amount - im.uninvoiced
        details['due_date'] = im.due_date.to_s
        details['last_reminder_date'] = im.last_reminder_date
        details['completion_date'] = im.completion_date.to_s
        details['project'] = im.project.name
        details['client'] = im.project.pipeline.client.name
        details['business_unit'] = im.project.business_unit_name
        data << details
      end
    elsif due_status.upcase == 'FUTURE' and completion_status.upcase == 'COMPLETE'
      InvoicingMilestone.where('due_date > ? and completion_date is not null', as_on).order('due_date').each do |im|
        details = {}
        details['id'] = im.id
        details['name'] = im.name
        details['amount'] = im.amount
        details['uninvoiced'] = im.uninvoiced
        details['remaining'] = im.amount - im.uninvoiced
        details['due_date'] = im.due_date.to_s
        details['last_reminder_date'] = im.last_reminder_date
        details['completion_date'] = im.completion_date.to_s
        details['project'] = im.project.name
        details['client'] = im.project.pipeline.client.name
        details['business_unit'] = im.project.business_unit_name
        data << details
      end
    elsif due_status.upcase == 'FUTURE' and completion_status.upcase == 'ALL'
      InvoicingMilestone.where('due_date > ?', as_on).order('due_date').each do |im|
        details = {}
        details['id'] = im.id
        details['name'] = im.name
        details['amount'] = im.amount
        details['uninvoiced'] = im.uninvoiced
        details['remaining'] = im.amount - im.uninvoiced
        details['due_date'] = im.due_date.to_s
        details['last_reminder_date'] = im.last_reminder_date
        details['completion_date'] = im.completion_date.to_s
        details['project'] = im.project.name
        details['client'] = im.project.pipeline.client.name
        details['business_unit'] = im.project.business_unit_name
        data << details
      end
    elsif due_status.upcase == 'ALL' and completion_status.upcase == 'INCOMPLETE'
      InvoicingMilestone.where('completion_date is null').order('due_date').each do |im|
        details = {}
        details['id'] = im.id
        details['name'] = im.name
        details['amount'] = im.amount
        details['uninvoiced'] = im.uninvoiced
        details['remaining'] = im.amount - im.uninvoiced
        details['due_date'] = im.due_date.to_s
        details['last_reminder_date'] = im.last_reminder_date
        details['completion_date'] = im.completion_date.to_s
        details['project'] = im.project.name
        details['client'] = im.project.pipeline.client.name
        details['business_unit'] = im.project.business_unit_name
        data << details
      end
    elsif due_status.upcase == 'ALL' and completion_status.upcase == 'COMPLETE'
      InvoicingMilestone.where('completion_date is not null').order('due_date').each do |im|
        details = {}
        details['id'] = im.id
        details['name'] = im.name
        details['amount'] = im.amount
        details['uninvoiced'] = im.uninvoiced
        details['remaining'] = im.amount - im.uninvoiced
        details['due_date'] = im.due_date.to_s
        details['last_reminder_date'] = im.last_reminder_date
        details['completion_date'] = im.completion_date.to_s
        details['project'] = im.project.name
        details['client'] = im.project.pipeline.client.name
        details['business_unit'] = im.project.business_unit_name
        data << details
      end
    elsif due_status.upcase == 'ALL' and completion_status.upcase == 'ALL'
      InvoicingMilestone.all.order('due_date').each do |im|
        details = {}
        details['id'] = im.id
        details['name'] = im.name
        details['amount'] = im.amount
        details['uninvoiced'] = im.uninvoiced
        details['remaining'] = im.amount - im.uninvoiced
        details['due_date'] = im.due_date.to_s
        details['last_reminder_date'] = im.last_reminder_date
        details['completion_date'] = im.completion_date.to_s
        details['project'] = im.project.name
        details['client'] = im.project.pipeline.client.name
        details['business_unit'] = im.project.business_unit_name
        data << details
      end
    end
    data
  end
end