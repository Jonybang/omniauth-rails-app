class CreateBlogs < ActiveRecord::Migration
  def change
    create_table :blogs do |t|
      t.string :uid, null: false
      t.string :views_count

      t.timestamps null: false
    end
  end
end
