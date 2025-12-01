# frozen_string_literal: true

class CreateTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :taggings do |t|
      t.uuid :public_id, null: false, default: -> { "gen_uuidv7()" }
      t.references :account, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.references :taggable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :taggings, :public_id, unique: true
    add_index :taggings, [:account_id, :tag_id, :taggable_type, :taggable_id],
              unique: true, name: "index_taggings_uniqueness"
  end
end
