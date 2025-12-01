# frozen_string_literal: true

class CreateDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :drafts do |t|
      t.uuid :public_id, null: false, default: -> { "gen_uuidv7()" }
      t.references :account, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.references :post, foreign_key: true # Optional: link to existing post for editing

      t.string :title
      t.text :content
      t.datetime :autosaved_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :drafts, :public_id, unique: true
    add_index :drafts, [:account_id, :author_id]
    add_index :drafts, [:account_id, :blog_id]
  end
end
