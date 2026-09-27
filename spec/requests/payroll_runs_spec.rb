require "rails_helper"

RSpec.describe "Payroll runs", type: :request do
  let(:headers) { auth_headers }

  describe "GET /payroll_runs" do
    it "lists payroll runs" do
      create(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))

      get payroll_runs_path, headers: headers

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /payroll_runs/new" do
    it "renders the form" do
      get new_payroll_run_path, headers: headers

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /payroll_runs" do
    let(:params) { { payroll_run: { period_start: "2026-09-01", period_end: "2026-09-30" } } }

    it "creates a draft run and queues it for processing by id" do
      expect { post payroll_runs_path, params: params, headers: headers }.to change(PayrollRun, :count).by(1)

      run = PayrollRun.last
      expect(run).to be_draft
      expect(ProcessPayrollRunJob).to have_been_enqueued.with(run.id)
      expect(response).to redirect_to(payroll_run_path(run))
    end

    it "re-renders the form with 422 and queues nothing when invalid" do
      invalid = { payroll_run: { period_start: "2026-09-30", period_end: "2026-09-01" } }

      expect { post payroll_runs_path, params: invalid, headers: headers }.not_to change(PayrollRun, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(ProcessPayrollRunJob).not_to have_been_enqueued
    end

    it "rejects a second run for the same period" do
      post payroll_runs_path, params: params, headers: headers

      expect { post payroll_runs_path, params: params, headers: headers }.not_to change(PayrollRun, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /payroll_runs/:id" do
    let(:run) { create(:payroll_run, status: "completed") }

    def add_line_item(employee)
      create(:payroll_line_item, payroll_run: run, employee: employee, salary_record: employee.current_salary_record)
    end

    it "shows the run's line items" do
      add_line_item(create(:employee, :with_salary, first_name: "Ada", last_name: "Lovelace"))

      get payroll_run_path(run), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ada Lovelace")
    end

    it "filters line items by the employee search" do
      add_line_item(create(:employee, :with_salary, first_name: "Ada", last_name: "Lovelace"))
      add_line_item(create(:employee, :with_salary, first_name: "Grace", last_name: "Hopper"))

      get payroll_run_path(run), params: { q: "grace" }, headers: headers

      expect(response.body).to include("Grace Hopper")
      expect(response.body).not_to include("Ada Lovelace")
    end

    it "returns 404 for an unknown run" do
      get payroll_run_path(0), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
