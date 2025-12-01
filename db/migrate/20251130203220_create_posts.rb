# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.uuid :public_id, null: false, default: -> { "gen_uuidv7()" }
      t.references :account, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.string :title, null: false
      t.string :slug, null: false
      t.text :content
      t.text :excerpt
      t.integer :status, default: 0, null: false
      t.datetime :published_at
      t.datetime :scheduled_for
      t.string :seo_title
      t.text :seo_description
      t.integer :reading_time_minutes
      t.boolean :featured, default: false, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :posts, :public_id, unique: true
    add_index :posts, [:account_id, :slug], unique: true
    add_index :posts, [:account_id, :status]
    add_index :posts, [:account_id, :published_at]
    add_index :posts, [:account_id, :blog_id]
    add_index :posts, [:account_id, :featured]
  end
end
