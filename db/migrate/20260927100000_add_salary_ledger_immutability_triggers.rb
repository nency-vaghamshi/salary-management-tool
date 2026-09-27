# Database-level backstop for the immutable salary ledger (see
# SalaryRevisionService): history must stay intact even for writes that skip
# the models (console, insert_all, raw SQL). fx dumps these into schema.rb.
#
# Postgres triggers can't hold logic themselves, so each one calls a function.
#
# Deletes are deliberately NOT blocked: deleting an employee cascades through
# employments to their salary records and components via dependent: :destroy.
class AddSalaryLedgerImmutabilityTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :enforce_salary_record_immutability, sql_definition: <<~SQL
      CREATE OR REPLACE FUNCTION enforce_salary_record_immutability() RETURNS trigger AS $$
      BEGIN
        -- A closed (inactive) record is history: frozen completely.
        IF OLD.status = 'inactive' THEN
          RAISE EXCEPTION 'Salary record % is inactive and cannot be modified', OLD.id;
        END IF;

        -- An active record may only be closed (effective_to + status, which is
        -- what SalaryRevisionService does); its identity and terms are fixed.
        IF NEW.employment_id  IS DISTINCT FROM OLD.employment_id OR
           NEW.currency_id    IS DISTINCT FROM OLD.currency_id OR
           NEW.effective_from IS DISTINCT FROM OLD.effective_from THEN
          RAISE EXCEPTION 'Salary record % terms cannot be changed; create a revision instead', OLD.id;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    create_trigger :salary_records_immutability, on: :salary_records, sql_definition: <<~SQL
      CREATE TRIGGER salary_records_immutability
        BEFORE UPDATE ON salary_records
        FOR EACH ROW EXECUTE FUNCTION enforce_salary_record_immutability();
    SQL

    # The amounts live on the components, so they are write-once.
    create_function :prevent_salary_record_component_update, sql_definition: <<~SQL
      CREATE OR REPLACE FUNCTION prevent_salary_record_component_update() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'Salary record component % cannot be modified; create a revision instead', OLD.id;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    create_trigger :salary_record_components_immutability, on: :salary_record_components, sql_definition: <<~SQL
      CREATE TRIGGER salary_record_components_immutability
        BEFORE UPDATE ON salary_record_components
        FOR EACH ROW EXECUTE FUNCTION prevent_salary_record_component_update();
    SQL
  end
end
