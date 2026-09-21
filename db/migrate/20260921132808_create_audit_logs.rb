class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.bigint :actor_id
      t.string :action, null: false
      t.references :auditable, polymorphic: true, null: false
      t.jsonb :audited_changes, null: false

      # Append-only log: created_at only, no updated_at - see AuditLog#readonly?
      t.datetime :created_at, null: false
    end

    add_index :audit_logs, :actor_id
    add_index :audit_logs, :created_at
  end
end
