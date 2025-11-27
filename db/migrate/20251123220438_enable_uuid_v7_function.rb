# frozen_string_literal: true

class EnableUuidV7Function < ActiveRecord::Migration[8.0]
  def up
    # This function is from https://github.com/gearkill/pg-uuid-v7
    # It provides a way to generate sequential UUIDs (UUIDv7) in PostgreSQL.
    execute <<~SQL
      create or replace function gen_uuidv7() returns uuid as $$
      declare
        unix_ts_ms bytea;
        rand_bytes bytea;
        uuid_bytes bytea;
      begin
        unix_ts_ms = decode(lpad(to_hex(floor(extract(epoch from clock_timestamp()) * 1000)::bigint), 12, '0'), 'hex');
        rand_bytes = gen_random_bytes(10);
        uuid_bytes = unix_ts_ms || rand_bytes;
        uuid_bytes = set_byte(uuid_bytes, 6, (get_byte(uuid_bytes, 6) & 15) | 112);
        uuid_bytes = set_byte(uuid_bytes, 8, (get_byte(uuid_bytes, 8) & 63) | 128);
        return encode(uuid_bytes, 'hex')::uuid;
      end
      $$ language plpgsql volatile;
    SQL
  end

  def down
    execute "drop function if exists gen_uuidv7();"
  end
end