class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :wiki_url, null: false
      t.string :title, null: false
      t.text :summary, null: false
      t.string :image_url, null: false
      t.timestamps null: false
    end
    add_index :events, [:title]
  end 
end
