# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.uuid :public_id, default: "gen_uuidv7()", null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :users, :public_id, unique: true
    add_index :users, :email, unique: true
  end
end