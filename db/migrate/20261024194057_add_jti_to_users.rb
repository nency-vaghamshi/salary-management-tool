class AddJtiToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # 1. Add column as nullable (instant, no lock)
    add_column :users, :jti, :string

    # 2. Backfill existing rows with unique values
    User.find_each do |user|
      user.update_columns(jti: SecureRandom.hex(16))
    end

    # 3. Add unique index concurrently (no write lock on PostgreSQL)
    add_index :users, :jti, unique: true, algorithm: :concurrently

    # 4. Enforce NOT NULL
    change_column_null :users, :jti, false
  end

  def down
    remove_index :users, :jti
    remove_column :users, :jti
  end
end
