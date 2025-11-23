class EnablePostgresExtensions < ActiveRecord::Migration[8.0]
  def change
    enable_extension "uuid-ossp"
    # Note: neighbor gem handles vector operations without requiring pgvector extension
  end
end
