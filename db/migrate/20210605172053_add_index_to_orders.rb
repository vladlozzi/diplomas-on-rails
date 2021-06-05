class AddIndexToOrders < ActiveRecord::Migration[6.1]
  def change
    add_index :orders, :name, unique: true
  end
end
