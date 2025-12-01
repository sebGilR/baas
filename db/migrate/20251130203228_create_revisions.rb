# frozen_string_literal: true

class CreateRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :revisions do |t|
      t.uuid :public_id, null: false, default: -> { "gen_uuidv7()" }
      t.references :account, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.string :title, null: false
      t.text :content
      t.integer :revision_number, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :revisions, :public_id, unique: true
    add_index :revisions, [:account_id, :post_id, :revision_number], unique: true
    add_index :revisions, [:account_id, :post_id, :created_at]
  end
end
