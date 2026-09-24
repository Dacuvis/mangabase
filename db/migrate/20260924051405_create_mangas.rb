class CreateMangas < ActiveRecord::Migration[8.1]
  def change
    create_table :mangas do |t|
      t.string :title
      t.string :author
      t.text :synopsis
      t.integer :chapet_count
      t.boolean :is_completed

      t.timestamps
    end
  end
end
