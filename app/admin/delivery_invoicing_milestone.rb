ActiveAdmin.register DeliveryInvoicingMilestone do
  menu false

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

  permit_params :delivery_milestone_id, :invoicing_milestone_id, :comments

  config.sort_order = 'invoicing_milestones.due_date_desc'

  config.clear_action_items!

  scope I18n.t('label.deleted'), if: proc { current_admin_user.role.super_admin }, default: false do |resources|
    DeliveryInvoicingMilestone.only_deleted.where('delivery_milestone_id = ?', params[:delivery_milestone_id]).order('invoicing_milestone_id')
  end

  action_item only: :index do |resource|
    link_to I18n.t('label.all'), admin_delivery_invoicing_milestones_path(project_id: params[:project_id], delivery_milestone_id: params[:delivery_milestone_id])
  end

  action_item only: :index do |resource|
    link_to I18n.t('label.new'), new_admin_delivery_invoicing_milestone_path(project_id: session[:project_id], delivery_milestone_id: session[:delivery_milestone_id]) if session.has_key?(:project_id) and session.has_key?(:delivery_milestone_id)
  end

  action_item only: :index do |resource|
    link_to I18n.t('label.back'), admin_delivery_milestones_path(project_id: session[:project_id])
  end

  action_item only: [:show, :edit, :new, :create] do |resource|
    link_to I18n.t('label.back'), admin_delivery_invoicing_milestones_path(project_id: session[:project_id], delivery_milestone_id: session[:delivery_milestone_id]) if session.has_key?(:project_id) and session.has_key?(:delivery_milestone_id)
  end

  batch_action :destroy, if: proc { params[:scope] != 'deleted' } do |ids|
    delivery_milestone_id = DeliveryInvoicingMilestone.without_deleted.find(ids.first).delivery_milestone_id
    ids.each do |id|
      object = DeliveryInvoicingMilestone.destroy(id)
      if !object.errors.empty?
        flash[:error] = object.errors.full_messages.to_sentence
        break
      end
    end
    redirect_to admin_delivery_invoicing_milestones_path(delivery_milestone_id: delivery_milestone_id, project_id: session[:project_id])
  end

  batch_action :restore, if: proc { params[:scope] == 'deleted' } do |ids|
    delivery_milestone_id = DeliveryInvoicingMilestone.with_deleted.find(ids.first).delivery_milestone_id
    ids.each do |id|
      DeliveryInvoicingMilestone.restore(id)
    end
    redirect_to admin_delivery_invoicing_milestones_path(delivery_milestone_id: delivery_milestone_id, project_id: session[:project_id])
  end

  index as: :grouped_table, group_by_attribute: :project_name do
    selectable_column
    column :id
    column :delivery_milestone, sortable: 'delivery_milestones.name' do |resource|
      resource.delivery_milestone.delivery_milestone_name
    end
    column :invoicing_milestone, sortable: 'invoicing_milestones.name' do |resource|
      resource.invoicing_milestone.invoicing_milestone_name
    end
    column :comments
    if params[:scope] == 'deleted'
      actions defaults: false, dropdown: true do |resource|
        item I18n.t('actions.restore'), admin_api_restore_delivery_invoicing_milestone_path(id: resource.id), method: :post
      end
    else
      actions defaults: true, dropdown: true
    end
  end

  filter :invoicing_milestone, collection: proc { InvoicingMilestone.ordered_lookup(session[:project_id]).map { |a| [a.invoicing_milestone_name, a.id] } }
  filter :comments

  show do |r|
    attributes_table_for r do
      row :id
      row :project do
        r.delivery_milestone.project.name
      end
      row :delivery_milestone do
        r.delivery_milestone.delivery_milestone_name
      end
      row :invoicing_milestone do
        r.invoicing_milestone.invoicing_milestone_name
      end
      row :comments
    end
  end

  controller do
    before_filter do |c|
      c.send(:is_resource_authorized?, [I18n.t('role.manager')])
    end

    before_filter only: :index do |resource|
      if params.has_key?(:project_id)
        session[:project_id] = params[:project_id]
        if params.has_key?(:delivery_milestone_id)
          session[:delivery_milestone_id] = params[:delivery_milestone_id]
        else
          admin_delivery_milestones_path(project_id: session[:project_id])
        end
      else
        redirect_to admin_projects_path
      end
      if params[:commit].blank? && params[:q].blank?
        extra_params = {"q" => {"project_id_eq" => params[:project_id], "delivery_milestone_id_eq" => params[:delivery_milestone_id]}}
        # make sure data is filtered and filters show correctly
        params.merge! extra_params
      end
    end

    before_filter :skip_sidebar!, if: proc { params.has_key?(:scope) }


    def scoped_collection
      DeliveryInvoicingMilestone.includes [:delivery_milestone, :invoicing_milestone]
    end

    def create
      super do |format|
        if !resource.errors.empty?
          flash[:error] = resource.errors.full_messages.to_sentence
        end
        redirect_to collection_url(project_id: session[:project_id], delivery_milestone_id: session[:delivery_milestone_id]) and return if resource.valid?
      end
    end

    def update
      super do |format|
        if !resource.errors.empty?
          flash[:error] = resource.errors.full_messages.to_sentence
        end
        redirect_to collection_url(project_id: session[:project_id], delivery_milestone_id: session[:delivery_milestone_id]) and return if resource.valid?
      end
    end

    def destroy
      super do |format|
        if !resource.errors.empty?
          flash[:error] = resource.errors.full_messages.to_sentence
        end
        redirect_to collection_url(project_id: session[:project_id], delivery_milestone_id: session[:delivery_milestone_id]) and return if resource.valid?
      end
    end

    def restore
      DeliveryInvoicingMilestone.restore(params[:id])
      delivery_invoicing_milestone = DeliveryInvoicingMilestone.find(params[:id])
      redirect_to admin_delivery_invoicing_milestones_path(delivery_milestone_id: delivery_invoicing_milestone.delivery_milestone_id, project_id: session[:project_id])
    end
  end

  form do |f|
    f.object.delivery_milestone_id = session[:delivery_milestone_id]
    f.inputs do
      f.input :project_name, as: :select, required: true, input_html: {disabled: :true}, collection: Project.where(id: session[:project_id]).map { |a| [a.name, a.name] }
      f.input :delivery_milestone, required: true, input_html: {disabled: :true}, collection: DeliveryMilestone.where(id: session[:delivery_milestone_id]).map { |a| [a.delivery_milestone_name, a.id] }
      f.input :delivery_milestone_id, as: :hidden
      if f.object.new_record?
        f.input :invoicing_milestone, required: true, as: :select, collection:
                                        InvoicingMilestone.ordered_lookup(session[:project_id]).map { |a| [a.invoicing_milestone_name, a.id] }, include_blank: true
      else
        f.input :invoicing_milestone, required: true, input_html: {disabled: :true}
        f.input :invoicing_milestone_id, as: :hidden
      end
      f.input :comments
      f.actions do
        f.action(:submit, label: I18n.t('label.save'))
      end
    end
  end
end
