class AuditLog < ApplicationRecord
  belongs_to :auditable, polymorphic: true
  belongs_to :actor, class_name: "User", optional: true, foreign_key: :actor_id, inverse_of: false

  validates :action, presence: true
  validates :audited_changes, presence: true

  scope :creations_of, ->(records) { where(action: "created", auditable: records) }

  def actor_name
    actor&.name || "System"
  end

  # Audit logs are an append-only trail: once written, a record must never be
  # changed or removed, so persistence writes other than the initial create
  # are rejected at the AR layer rather than relying on callers to behave.
  def readonly?
    persisted?
  end
end
