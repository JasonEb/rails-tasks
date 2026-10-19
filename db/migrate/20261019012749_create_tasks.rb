class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.boolean :completed, null: false, default: false
      t.date :due_on
      t.integer :comments_count, null: false, default: 0

      t.timestamps
    end

    add_index :tasks, :created_at
  end
end
