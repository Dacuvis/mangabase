class CreateUnderratedMangas < ActiveRecord::Migration[8.1]
  def change
    create_table :underrated_mangas do |t|
      t.integer :rank
      t.decimal :score
      t.text :reason
      t.references :manga, null: false, foreign_key: true

      t.timestamps
    end
  end
end
