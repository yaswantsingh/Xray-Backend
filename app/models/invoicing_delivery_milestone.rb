class InvoicingDeliveryMilestone < ActiveRecord::Base
  acts_as_paranoid

  self.table_name = 'delivery_invoicing_milestones'

  belongs_to :delivery_milestone, class_name: 'DeliveryMilestone', foreign_key: :delivery_milestone_id
  belongs_to :invoicing_milestone, class_name: 'InvoicingMilestone', foreign_key: :invoicing_milestone_id

  validates :delivery_milestone_id, presence: true
  validates :invoicing_milestone_id, presence: true

  validates_uniqueness_of :delivery_milestone_id, scope: [:delivery_milestone_id,:invoicing_milestone_id]
  validates_uniqueness_of :invoicing_milestone_id, scope: [:delivery_milestone_id, :invoicing_milestone_id]

  def project_name
    self.invoicing_milestone.project.name
  end
end