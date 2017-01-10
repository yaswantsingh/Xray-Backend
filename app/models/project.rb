class Project < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :client, class_name: 'Client', foreign_key: :client_id
  belongs_to :project_type_code, class_name: 'ProjectTypeCode', foreign_key: :project_type_code_id
  belongs_to :project_status, class_name: 'ProjectStatus', foreign_key: :project_status_id
  belongs_to :business_unit, class_name: 'BusinessUnit', foreign_key: :business_unit_id
  belongs_to :sales_person, class_name: 'AdminUser', foreign_key: :sales_person_id
  belongs_to :estimator, class_name: 'AdminUser', foreign_key: :estimator_id
  belongs_to :engagement_manager, class_name: 'AdminUser', foreign_key: :engagement_manager_id
  belongs_to :delivery_manager, class_name: 'AdminUser', foreign_key: :delivery_manager_id
  belongs_to :pipeline, class_name: 'Pipeline', foreign_key: :pipeline_id

  has_many :projects_audits, class_name: 'ProjectAudit'
  has_many :assigned_resources, class_name: 'AssignedResource'
  has_many :project_overheads, class_name: 'ProjectOverhead'
  has_many :delivery_milestones, class_name: 'DeliveryMilestone'
  has_many :invoicing_milestones, class_name: 'InvoicingMilestone'

  validates :name, presence: true
  validates :client_id, presence: true
  validates :project_type_code_id, presence: true
  validates :project_status_id, presence: true
  validates :business_unit_id, presence: true
  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :booking_value, presence: true
  validates :sales_person_id, presence: true
  validates :estimator_id, presence: true
  validates :engagement_manager_id, presence: true
  validates :delivery_manager_id, presence: true

  before_create :date_check
  before_update :date_check

  validates_uniqueness_of :business_unit_id, scope: [:business_unit_id, :client_id]
  validates_uniqueness_of :client_id, scope: [:business_unit_id, :client_id]

  after_create :create_audit_record
  after_update :create_audit_record

  def business_unit_name
    BusinessUnit.find(self.business_unit_id).name
  end

  def create_audit_record
    audit_record = ProjectsAudit.new
    audit_record.name = self.name
    audit_record.description = self.description
    audit_record.start_date = self.start_date
    audit_record.end_date = self.end_date
    audit_record.booking_value = self.booking_value
    audit_record.comments = self.comments
    audit_record.created_at = self.created_at
    audit_record.client_id = self.client_id
    audit_record.project_type_code_id = self.project_type_code_id
    audit_record.project_status_id = self.project_status_id
    audit_record.business_unit_id = self.business_unit_id
    audit_record.estimator_id = self.estimator_id
    audit_record.engagement_manager_id = self.engagement_manager_id
    audit_record.delivery_manager_id = self.delivery_manager_id
    audit_record.pipeline_id = self.pipeline_id
    audit_record.sales_person_id = self.sales_person_id
    audit_record.project_id = self.id
    audit_record.updated_at = DateTime.now
    audit_record.updated_by = self.updated_by
    audit_record.ip_address = self.ip_address
    audit_record.save!
  end

  def date_check
    if self.start_date > self.end_date
      errors.add(:base, I18n.t('errors.date_check'))
      return false
    end
  end

  def invoiced_amount
    InvoiceLine.where(project_id: self.id).sum(:line_amount)
  end

  def paid_amount
    invoice_line_ids = InvoiceLine.where(project_id: self.id).pluck(:id)
    PaymentLine.where(invoice_line_id: invoice_line_ids).sum(:line_amount)
  end

  def unpaid_amount
    self.invoiced_amount - self.paid_amount
  end

  def missed_delivery(as_on, with_details)
    as_on = Date.today.to_s if as_on.nil?
    with_details = (with_details == 'true') ? true : false
    data = []
    count = 0
    DeliveryMilestone.where('project_id = ? and due_date < ? and completion_date is null', self.id, as_on).order(:due_date).each do |dm|
      if with_details
        details = {}
        details['base'] = dm
        data << details
      end
      count += 1
    end
    result = {}
    result['count'] = count
    if with_details
      result['data'] = data
    end
    result
  end

  def missed_invoicing(as_on, with_details)
    as_on = Date.today.to_s if as_on.nil?
    with_details = (with_details == 'true') ? true : false
    data = []
    count = 0
    total_uninvoiced = 0
    InvoicingMilestone.where('project_id = ? and due_date < ? and completion_date is null', self.id, as_on).order(:due_date).each do |im|
      if with_details
        details = {}
        details['base'] = im
        details['uninvoiced'] = im.uninvoiced
        data << details

      end
      count += 1
      total_uninvoiced += im.uninvoiced
    end
    result = {}
    result['count'] = count
    result['total_uninvoiced'] = total_uninvoiced
    if with_details
      result['data'] = data
    end
    result
  end

  def missed_payments(as_on, with_details)
    as_on = Date.today.to_s if as_on.nil?
    with_details = (with_details == 'true') ? true : false
    data = []
    count = 0
    total_unpaid = 0
    InvoiceLine.where('project_id = ? and invoice_headers.due_date < ?', self.id, Date.parse(as_on)).joins(:invoice_header).order('invoice_headers.id, invoice_headers.due_date').each do |il|
      if il.unpaid_amount > 0
        if with_details
          details = {}
          details['invoice_line'] = il
          details['invoice_header'] = il.invoice_header
          details['client'] = il.invoice_header.client
          details['unpaid_amount'] = il.unpaid_amount
          data << details
          total_unpaid += details['unpaid_amount']
        end
        count += 1
        total_unpaid += il.unpaid_amount
      end
    end
    result = {}
    result['count'] = count
    result['total_unpaid'] = total_unpaid
    if with_details
      result['data'] = data
    end
    result
  end

  def direct_resource_cost(as_on, with_details)
    as_on = Date.today.to_s if as_on.nil?
    with_details = (with_details == 'true') ? true : false
    data = []
    count = 0
    total_direct_resource_cost = 0
    AssignedResource.where('project_id = ?', self.id).order('start_date, end_date').each do |ar|
      if with_details
        details = {}
        details['assigned_resource'] = ar
        details['assigned_hours'] = ar.hours_assigned(as_on)
        details['direct_resource_cost'] = ar.assignment_cost(as_on)
        data << details
      end
      count += 1
      total_direct_resource_cost += ar.assignment_cost(as_on)
    end
    result = {}
    result['count'] = count
    result['total_direct_resource_cost'] = total_direct_resource_cost
    if with_details
      result['data'] = data
    end
    result
  end

  def direct_overhead_cost(as_on, with_details)
    as_on = Date.today.to_s if as_on.nil?
    with_details = (with_details == 'true') ? true : false
    data = []
    count = 0
    total_direct_overhead_cost = 0
    ProjectOverhead.where('project_id = ? and amount_date <= ?', self.id, Date.parse(as_on)).joins(:cost_adder_type).order('amount_date').each do |po|
      if with_details
        details = {}
        details['project_overhead'] = po
        details['cost_adder_type'] = po.cost_adder_type
        details['direct_overhead_cost'] = po.amount
        data << details
      end
      count += 1
      total_direct_overhead_cost += po.amount
    end
    result = {}
    result['count'] = count
    result['total_direct_overhead_cost'] = total_direct_overhead_cost
    if with_details
      result['data'] = data
    end
    result
  end

  # def total_direct_cost(as_on)
  #   0
  # end
  #
  # def indirect_resource_cost_share(as_on)
  #   result = 0
  #   result
  # end
  #
  # def indirect_overhead_cost_share(as_on)
  #   result = 0
  #   result
  # end
  #
  # def total_indirect_cost_share(as_on)
  #   indirect_resource_cost_share(as_on) + indirect_overhead_cost_share(as_on)
  # end
  #
  # def total_cost(as_on)
  #   total_direct_cost(as_on) + total_indirect_cost_share(as_on)
  # end
  #
  # def total_revenue(as_on)
  #   result = 0
  #   InvoiceLine.where('project_id = ?', self.id).each do |il|
  #     if il.invoice_header.invoice_date <= as_on
  #       result += il.line_amount
  #     end
  #   end
  #   result
  # end
  #
  # def contribution(as_on)
  #   total_revenue(as_on) - total_direct_cost(as_on)
  # end
  #
  # def gross_profit(as_on)
  #   contribution(as_on) - total_indirect_cost_share(as_on)
  # end
end