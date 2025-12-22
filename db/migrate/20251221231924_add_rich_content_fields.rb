# frozen_string_literal: true

class AddRichContentFields < ActiveRecord::Migration[8.1]
  TABLES = [:posts, :drafts, :revisions].freeze

  def change
    TABLES.each do |table|
      add_column table, :content_json, :jsonb
      add_column table, :content_html, :text
      add_column table, :content_text, :text
    end
  end
end
