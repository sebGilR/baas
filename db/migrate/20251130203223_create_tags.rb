# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.uuid :public_id, null: false, default: -> { "gen_uuidv7()" }
      t.references :account, null: false, foreign_key: true

      t.string :name, null: false
      t.string :slug, null: false
      t.string :color

      t.timestamps
    end

    add_index :tags, :public_id, unique: true
    add_index :tags, [:account_id, :slug], unique: true
    add_index :tags, [:account_id, :name]
  end
end
