ActiveAdmin.register VacationPolicy do
  menu label: 'Vacation Policies', parent: 'Setup', priority: 20

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

  permit_params :vacation_code_id, :description, :as_on, :paid, :days_allowed, :comments, :business_unit_id

  config.sort_order = 'as_on_desc_and_business_unit_id_asc_and_vacation_code_id_asc'

  config.clear_action_items!

  action_item only: :index do |resource|
    link_to "New", new_admin_vacation_policy_path
  end

  index do
    selectable_column
    column :id
    column :vacation_code do |resource|
      resource.vacation_code.name
    end
    column :business_unit do |resource|
      resource.business_unit.name
    end
    column :description
    column :as_on
    column :paid
    column :days_allowed
    column :comments
    actions defaults: true, dropdown: true
  end


  filter :vacation_code, collection:
                           proc { Lookup.where(lookup_type_id: LookupType.where(name: 'Business Units').first.id) }
  filter :business_unit, collection:
                           proc { Lookup.where(lookup_type_id: LookupType.where(name: 'Vacation Codes').first.id) }
  filter :description
  filter :as_on
  filter :paid
  filter :days_allowed
  filter :comments

  controller do
    def scoped_collection
      resource_class.includes(:vacation_code)
      resource_class.includes(:business_unit)
    end

    def create
      super do |format|
        redirect_to collection_url and return if resource.valid?
      end
    end

    def update
      super do |format|
        redirect_to collection_url and return if resource.valid?
      end
    end
  end

  form do |f|
    if f.object.as_on.blank?
      f.object.as_on = Date.today
    end
    if f.object.paid.blank?
      f.object.paid = false
    end
    f.inputs do
      if f.object.business_unit_id.blank?
        f.input :business_unit, as: :select, collection:
                                  Lookup.where(lookup_type_id: LookupType.where(name: 'Business Units').first.id)
                                      .map { |a| [a.name, a.id] }, include_blank: true
      else
        f.input :business_unit, input_html: {disabled: :true}
        f.input :business_unit_id, as: :hidden
      end
      if f.object.vacation_code_id.blank?
        f.input :vacation_code, as: :select, collection:
                                  Lookup.where(lookup_type_id: LookupType.where(name: 'Vacation Codes').first.id)
                                      .map { |a| [a.name, a.id] }, include_blank: true
      else
        f.input :vacation_code, input_html: {disabled: :true}
        f.input :vacation_code_id, as: :hidden
      end
      f.input :description
      f.input :as_on, as: :datepicker
      f.input :paid
      f.input :days_allowed
      f.input :comments
    end
    f.actions
  end
end