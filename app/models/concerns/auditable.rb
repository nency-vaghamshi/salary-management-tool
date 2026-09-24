# Writes an AuditLog row whenever an including model is created, updated, or
# destroyed, attributing the change to whichever HR user is signed in for the
# current request (Current.user). Kept as its own concern rather than
# callbacks on Employee/SalaryRecord directly so the same auditing behavior
# can be dropped onto any future auditable model without duplication.
module Auditable
  extend ActiveSupport::Concern

  IGNORED_ATTRIBUTES = %w[created_at updated_at].freeze

  included do
    after_create { record_audit("created", saved_changes) }
    after_update { record_audit("updated", saved_changes) }
    # previous_changes is empty here for the common find-then-destroy flow
    # (no attribute was ever assigned on this in-memory instance before
    # destroy), so record what existed rather than a before/after diff.
    after_destroy { record_audit("destroyed", destroyed_snapshot) }
  end

  private

  def destroyed_snapshot
    attributes.except("id", *IGNORED_ATTRIBUTES).transform_values { |value| [ value, nil ] }
  end

  def record_audit(action, changes)
    relevant_changes = changes.except(*IGNORED_ATTRIBUTES)
    return if relevant_changes.blank?

    AuditLog.create!(
      actor: Current.user,
      action: action,
      auditable: self,
      audited_changes: relevant_changes
    )
  end
end
