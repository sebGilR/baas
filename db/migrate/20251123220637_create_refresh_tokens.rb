# frozen_string_literal: true

class CreateRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :refresh_tokens do |t|
      t.uuid :public_id, default: "gen_uuidv7()", null: false
      t.references :user, null: false, foreign_key: true
      t.string :jti, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.jsonb :device_info, default: {}
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :refresh_tokens, :public_id, unique: true
    add_index :refresh_tokens, :jti, unique: true
    add_index :refresh_tokens, [:user_id, :revoked_at]
  end
end