# frozen_string_literal: true

class CreateAccountMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :account_memberships do |t|
      t.uuid :public_id, default: "gen_uuidv7()", null: false
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.integer :role, default: 0
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :account_memberships, :public_id, unique: true
    add_index :account_memberships, [:user_id, :account_id], unique: true
  end
end