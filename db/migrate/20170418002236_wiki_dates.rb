class WikiDate < ActiveRecord::Migration
  def change
    create_table :wiki_dates do |t|
      t.date :day, null: false
      t.string :event, null: false
      t.timestamps null: false
    end
    add_index :wiki_dates, [:day]
  end
end
