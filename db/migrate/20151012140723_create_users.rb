class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.integer :views_count

      t.timestamps null: false
    end
  end
end
