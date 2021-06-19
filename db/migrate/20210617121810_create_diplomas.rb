class CreateDiplomas < ActiveRecord::Migration[6.1]
  def change
    create_table :diplomas do |t|
      t.string :seria, length: 3
      t.string :number, length: 6
      t.string :name, null: false
      t.string :diploma_file
      t.references :order, null: false, foreign_key: true

      t.timestamps
    end
    add_index :diplomas, :name, unique: true
    add_index :diplomas, [:seria, :number], unique: true
    # add_check_constraint :diplomas, 'seria REGEXP "/(B|C|E|M)\d{2}/"', name: "check_seria"
  end
end
