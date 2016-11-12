ActiveAdmin.register Role do
  menu if: proc { is_not_authorized? ["User"] }, label: 'Define Roles', parent: 'Security', priority: 30

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

  permit_params :name, :description, :rank, :comments, :super_admin, :parent_id

  config.sort_order = 'rank_asc'

  config.clear_action_items!

  action_item only: :index do |resource|
    link_to "New", new_admin_role_path
  end

  action_item only: :show do |resource|
    link_to "Back", admin_roles_path
  end

  index do
    selectable_column
    column :id
    column :name
    column :super_admin
    column :description
    column :rank
    column 'Parent', :immediate_parent
    column :comments
    actions defaults: true, dropdown: true do |resource|
    end
  end

  filter :name
  filter :description
  filter :super_admin
  filter :rank
  filter :ancestry
  filter :comments

  controller do
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
    if f.object.rank.blank?
      f.object.rank = Role.generate_next_rank
    end
    f.inputs do
      f.input :name
      f.input :description
      f.input :super_admin
      f.input :rank
      f.input :parent_id, as: :select, collection:
          Role.all.map { |a| [a.name, a.id] }, include_blank: true
      f.input :comments
    end
    f.actions do
      f.action(:submit, label: 'Save')
      f.cancel_link
    end
  end
end
