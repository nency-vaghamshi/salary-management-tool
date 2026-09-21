class SalaryImport < ApplicationRecord
  enum :status, { pending: "pending", processing: "processing", completed: "completed", failed: "failed" }

  validates :uploaded_by_id, presence: true
  validates :file_name, presence: true
end
