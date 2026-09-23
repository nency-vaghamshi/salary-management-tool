class AddDeviseToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :encrypted_password, :string, null: false, default: ""

    reversible do |dir|
      dir.up do
        execute "UPDATE users SET encrypted_password = password_digest"
      end
    end

    remove_column :users, :password_digest, :string, null: false
  end
end
