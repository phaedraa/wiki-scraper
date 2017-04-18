class WikiDate < ActiveRecord::Migration
  def change
    create_table :wiki_date do |t|
      t.date :day, null: false
      t.string :event, null: false
    end
    add_index :wiki_dates, [:day]
  end
end
