ActiveAdmin.register StaffingRequirement do
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

  permit_params :start_date, :end_date, :number_required, :hours_per_day, :fulfilled, :created_at, :updated_at, :pipeline_id, :skill_id, :designation_id, :comments

  config.sort_order = 'skills.name_asc_and_start_date_asc_and_end_date_asc'

  config.clear_action_items!

  scope I18n.t('label.deleted'), if: proc { current_admin_user.role.super_admin }, default: false do |resources|
    StaffingRequirement.only_deleted.where('pipeline_id = ?', session[:pipeline_id]).order('start_date asc, end_date asc')
  end

  action_item only: :index do |resource|
    link_to I18n.t('label.all'), admin_staffing_requirements_path(pipeline_id: params[:pipeline_id])
  end

  action_item only: :index do |resource|
    link_to I18n.t('label.new'), new_admin_staffing_requirement_path(pipeline_id: session[:pipeline_id]) if session.has_key?(:pipeline_id)
  end

  action_item only: :index do |resource|
    link_to I18n.t('label.back'), admin_staffing_requirements_path(pipeline_id: nil)
  end

  action_item only: [:show, :edit, :new, :create] do |resource|
    link_to I18n.t('label.back'), admin_staffing_requirements_path(pipeline_id: session[:pipeline_id]) if session.has_key?(:pipeline_id)
  end

  batch_action :destroy, if: proc { params[:scope] != 'deleted' } do |ids|
    ids.each do |id|
      object = StaffingRequirement.destroy(id)
      if !object.errors.empty?
        flash[:error] = object.errors.full_messages.to_sentence
        break
      end
    end
    redirect_to admin_staffing_requirements_path(pipeline_id: session[:pipeline_id])
  end

  batch_action :restore, if: proc { params[:scope] == 'deleted' } do |ids|
    ids.each do |id|
      StaffingRequirement.restore(id)
    end
    redirect_to admin_staffing_requirements_path(pipeline_id: session[:pipeline_id])
  end

  index as: :grouped_table, group_by_attribute: :skill_name do
    selectable_column
    column :id
    column :pipeline, sortable: 'pipelines.name' do |resource|
      resource.pipeline.name
    end
    column :designation, sortable: 'designations.name' do |resource|
      resource.designation.name
    end
    column :number_required do |element|
      div :style => "text-align: right;" do
        number_with_precision element.number_required, precision: 0, delimiter: ','
      end
    end
    column :hours_per_day do |element|
      div :style => "text-align: right;" do
        number_with_precision element.hours_per_day, precision: 1, delimiter: ','
      end
    end
    column :start_date
    column :end_date
    column :fulfilled
    column :comments
    if params[:scope] == 'deleted'
      actions defaults: false, dropdown: true do |resource|
        item I18n.t('actions.restore'), admin_api_restore_staffing_requirement_path(id: resource.id), method: :post
      end
    else
      actions defaults: true, dropdown: true
    end
  end

  filter :skill
  filter :designation
  filter :number_required
  filter :hours_per_day
  filter :start_date
  filter :end_date
  filter :fulfilled
  filter :comments

  show do |r|
    attributes_table_for r do
      row :id
      row :pipeline do
        r.pipeline.name
      end
      row :skill
      row :designation
      row :number_required
      row :hours_per_day
      row :start_date
      row :end_date
      row :fulfilled
      row :comments
    end
  end

  controller do
    before_filter do |c|
      c.send(:is_resource_authorized?, [I18n.t('role.manager')])
    end

    before_filter only: :index do |resource|
      if params.has_key?(:pipeline_id)
        session[:pipeline_id] = params[:pipeline_id]
      else
        redirect_to admin_pipelines_path
      end
      if params[:commit].blank? && params[:q].blank?
        extra_params = {"q" => {"pipeline_id_eq" => params[:pipeline_id]}}
        # make sure data is filtered and filters show correctly
        params.merge! extra_params
      end
    end

    before_filter :skip_sidebar!, if: proc { params.has_key?(:scope) }

    def scoped_collection
      StaffingRequirement.includes [:pipeline, :skill, :designation]
    end

    def create
      super do |format|
        if !resource.errors.empty?
          flash[:error] = resource.errors.full_messages.to_sentence
        end
        redirect_to collection_url(pipeline_id: session[:pipeline_id]) and return if resource.valid?
      end
    end

    def update
      super do |format|
        if !resource.errors.empty?
          flash[:error] = resource.errors.full_messages.to_sentence
        end
        redirect_to collection_url(pipeline_id: session[:pipeline_id]) and return if resource.valid?
      end
    end

    def destroy
      super do |format|
        if !resource.errors.empty?
          flash[:error] = resource.errors.full_messages.to_sentence
        end
        redirect_to collection_url(pipeline_id: session[:pipeline_id]) and return if resource.valid?
      end
    end

    def restore
      StaffingRequirement.restore(params[:id])
      redirect_to admin_staffing_requirements_path(pipeline_id: session[:pipeline_id])
    end

    def staffing_forecast
      as_on = params[:as_on]
      result = StaffingRequirement.staffing_forecast(as_on, false)
      render json: result
    end

    def staffing_required
      as_on = params[:as_on]
      skill_id = params[:skill_id]
      designation_id = params[:designation_id]
      result = StaffingRequirement.staffing_required(skill_id, designation_id, as_on, true)
      render json: result
    end

    def staffing_fulfilled
      as_on = params[:as_on]
      skill_id = params[:skill_id]
      designation_id = params[:designation_id]
      result = StaffingRequirement.staffing_fulfilled(skill_id, designation_id, as_on, true)
      render json: result
    end

    def deployable_resources
      as_on = params[:as_on]
      skill_id = params[:skill_id]
      designation_id = params[:designation_id]
      result = StaffingRequirement.deployable_resources(skill_id, designation_id, as_on, true)
      render json: result
    end
  end

  form do |f|
    f.object.pipeline_id = session[:pipeline_id]
    if f.object.new_record?
      f.object.number_required = 1
      f.object.hours_per_day = Rails.configuration.max_work_hours_per_day
      f.object.start_date = Date.today
      f.object.end_date = Date.today
    end
    f.inputs do
      f.input :pipeline, required: true, input_html: {disabled: :true}
      f.input :pipeline_id, as: :hidden
      if f.object.skill_id.blank?
        f.input :skill, required: true, as: :select, collection:
                          Lookup.lookups_for_name(I18n.t('models.skills'))
                              .map { |a| [a.name, a.id] }, include_blank: true
      else
        f.input :skill, required: true, input_html: {disabled: :true}
        f.input :skill_id, as: :hidden
      end
      if f.object.designation_id.blank?
        f.input :designation, required: true, as: :select, collection:
                                Lookup.lookups_for_name(I18n.t('models.designations'))
                                    .map { |a| [a.name, a.id] }, include_blank: true
      else
        f.input :designation, required: true, input_html: {disabled: :true}
        f.input :designation_id, as: :hidden
      end
      if f.object.new_record?
        f.input :number_required
        f.input :hours_per_day
      else
        f.input :number_required, required: true, input_html: {readonly: :true}
        f.input :hours_per_day, required: true, input_html: {readonly: :true}
      end
      if !f.object.new_record?
        f.input :start_date, label: I18n.t('label.start'), as: :datepicker, input_html: {disabled: :true}
        f.input :start_date, as: :hidden
      else
        f.input :start_date, label: I18n.t('label.start'), as: :datepicker
      end
      if !f.object.new_record?
        f.input :end_date, label: I18n.t('label.end'), as: :datepicker, input_html: {disabled: :true}
        f.input :end_date, as: :hidden
      else
        f.input :end_date, label: I18n.t('label.end'), as: :datepicker
      end
      f.input :fulfilled
      f.input :comments
    end
    f.actions do
      f.action(:submit, label: I18n.t('label.save'))
    end
  end
end
