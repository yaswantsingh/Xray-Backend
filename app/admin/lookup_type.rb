ActiveAdmin.register LookupType do
  menu if: proc { is_menu_authorized? [I18n.t('role.director')] }, label: I18n.t('menu.define_lookups'), parent: I18n.t('menu.setup'), priority: 10

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

  permit_params  :name, :description, :comments

  config.sort_order = 'name_asc'

  config.clear_action_items!

  action_item only: :index do |resource|
    link_to I18n.t('label.new'), new_admin_lookup_type_path
  end

  action_item only: :show do |resource|
    link_to I18n.t('label.back'), admin_lookup_types_path(lookup_type_id: nil)
  end

  index do
    selectable_column
    column :id
    column :name
    column :description
    column :comments
    actions defaults: true  , dropdown: true do |resource|
      item I18n.t('actions.lookups'), admin_lookups_path(lookup_type_id: resource)
    end
  end

  filter :name
  filter :description
  filter :comments

  controller do
    before_filter do |c|
      c.send(:is_resource_authorized?, [I18n.t('role.director')])
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
    f.inputs
    f.actions do
      f.action(:submit, label: I18n.t('label.save'))
      f.cancel_link
    end
  end
end
