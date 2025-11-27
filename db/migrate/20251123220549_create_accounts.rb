# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.uuid :public_id, default: "gen_uuidv7()", null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :status, default: 0
      t.integer :plan, default: 0

      t.timestamps
    end

    add_index :accounts, :public_id, unique: true
    add_index :accounts, :slug, unique: true
  end
end