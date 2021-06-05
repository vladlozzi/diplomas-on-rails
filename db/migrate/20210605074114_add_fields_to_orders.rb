class AddFieldsToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :xml_file, :string
  end
end
