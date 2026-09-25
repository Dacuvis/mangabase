class CreateReadingLists < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :manga, null: false, foreign_key: true
      t.string :status
      t.integer :progress_chapter

      t.timestamps
    end
  end
end
