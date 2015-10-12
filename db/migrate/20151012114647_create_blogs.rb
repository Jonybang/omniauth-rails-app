class CreateBlogs < ActiveRecord::Migration
  def change
    create_table :blogs do |t|
      t.string :name, null: false

      t.integer :notes
      t.integer :followers
      t.integer :posts
      t.integer :queue

      t.boolean :hidden

      t.belongs_to :user

      t.timestamps null: false
    end
  end
end
