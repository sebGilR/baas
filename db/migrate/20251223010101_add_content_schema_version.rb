# frozen_string_literal: true

class AddContentSchemaVersion < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :content_schema_version, :integer, default: 1, null: false
    add_column :drafts, :content_schema_version, :integer, default: 1, null: false
    add_column :revisions, :content_schema_version, :integer, default: 1, null: false
  end
end
