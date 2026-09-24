# Runs PayrollCalculator off the request cycle: a 10k-employee run takes far
# too long to hold an HTTP request open.
#
# No retry_on on purpose: PayrollCalculator marks a run "failed" when it
# raises, and only draft runs can be processed, so an automatic retry could
# never succeed — the failure is left visible in Solid Queue instead.
class ProcessPayrollRunJob < ApplicationJob
  queue_as :default

  # Solid Queue-level lock so a duplicate enqueue can never process the same
  # run twice in parallel (the draft? check alone is not atomic).
  limits_concurrency to: 1, key: ->(payroll_run) { payroll_run }

  discard_on ActiveJob::DeserializationError

  def perform(payroll_run)
    return unless payroll_run.draft?

    PayrollCalculator.new(payroll_run).call
  end
end
