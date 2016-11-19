ActiveAdmin.register Client do
  menu if: proc { is_menu_authorized? ["Executive"] }, label: 'Clients', parent: 'Masters', priority: 30

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

  permit_params :business_unit_id, :name, :contact_name, :contact_email, :contact_phone, :comments

# config.sort_order = 'admin_users.name_asc_and_skills.name_asc_and_as_on_desc'

  config.clear_action_items!

  action_item only: :index do |resource|
    link_to "New", new_admin_client_path
  end

  action_item only: :show do |resource|
    link_to "Back", admin_clients_path
  end

# index do
  index as: :grouped_table, group_by_attribute: :business_unit_name do
    selectable_column
    column :id
    # column :business_unit, sortable: 'business_units.name' do |resource|
    #   resource.business_unit.name
    # end
    column :name
    column :contact_name
    column :contact_email
    column :contact_phone
    column :comments
    actions defaults: true, dropdown: true
  end

  filter :business_unit, collection:
                           proc { Lookup.lookups_for_name('Business Units') }
  filter :name
  filter :contact_name
  filter :contact_email
  filter :contact_phone
  filter :comments

  show do |r|
    attributes_table_for r do
      row :id
      row :business_unit do
        r.business_unit.name
      end
      row :name
      row :contact_name
      row :contact_email
      row :contact_phone
      row :comments
    end
  end

  controller do
    before_filter do |c|
      c.send(:is_resource_authorized?, ["Executive"])
    end

    def scoped_collection
      Client.includes [:business_unit]
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
    f.inputs do
      if f.object.business_unit_id.blank?
        f.input :business_unit, as: :select, collection:
                                  Lookup.lookups_for_name('Business Units')
                                      .map { |a| [a.name, a.id] }, include_blank: true
      else
        f.input :business_unit, input_html: {disabled: :true}
        f.input :business_unit_id, as: :hidden
      end
      if !f.object.new_record?
        f.input :name, input_html: {readonly: true}
      else
        f.input :name
      end
      f.input :contact_name
      f.input :contact_email
      f.input :contact_phone
      f.input :comments
    end
    f.actions do
      f.action(:submit, label: 'Save')
      f.cancel_link
    end
  end
end