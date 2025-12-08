# frozen_string_literal: true

class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      # UUIDv7 public identifier (never expose integer id)
      t.uuid :public_id, default: "gen_uuidv7()", null: false

      # Ownership: tied to both user and account for multi-tenancy
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      # Key identification and security
      t.string :name, null: false                    # Human-readable name ("Postman Dev Key")
      t.string :prefix, null: false                  # First 8 chars of key for identification (ak_live_abc...)
      t.string :secret_digest, null: false           # BCrypt hashed secret

      # Scopes and permissions (JSON array)
      t.jsonb :scopes, default: [], null: false      # ["posts:read", "posts:write", "admin:*"]

      # Environment mode
      t.integer :environment, default: 0, null: false # 0: live, 1: test

      # Lifecycle
      t.datetime :expires_at                          # nil = never expires
      t.datetime :revoked_at                          # nil = active
      t.datetime :last_used_at
      t.string :last_used_ip

      t.timestamps
    end

    add_index :api_keys, :public_id, unique: true
    add_index :api_keys, :prefix, unique: true
    add_index :api_keys, [:user_id, :account_id]
    add_index :api_keys, [:account_id, :revoked_at]
  end
end
