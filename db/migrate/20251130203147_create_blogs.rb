# frozen_string_literal: true

class CreateBlogs < ActiveRecord::Migration[8.1]
  def change
    create_table :blogs do |t|
      t.uuid :public_id, null: false, default: -> { "gen_uuidv7()" }
      t.references :account, null: false, foreign_key: true

      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.jsonb :settings, default: {}
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :blogs, :public_id, unique: true
    add_index :blogs, [:account_id, :slug], unique: true
    add_index :blogs, [:account_id, :status]
  end
end
