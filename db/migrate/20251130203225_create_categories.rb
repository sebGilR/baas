# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.uuid :public_id, null: false, default: -> { "gen_uuidv7()" }
      t.references :account, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :categories }

      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :categories, :public_id, unique: true
    add_index :categories, [:account_id, :slug], unique: true
    add_index :categories, [:account_id, :parent_id]
  end
end
