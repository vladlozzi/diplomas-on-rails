class AddPartnerToOrder < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :partner_uk, :string
    add_column :orders, :partner_en, :string
  end
end
