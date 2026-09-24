# Database Design
PostgreSQL database behind ACME Salary Management. It covers about 10,000 employees across many countries.

## Overview

```
Department ─┐
JobTitle ───┼── Employee ── Employment ── SalaryRecord ── SalaryRecordComponent ── SalaryComponent
Country ────┘  (nationality,   │  (payroll      │  (currency,
 (residence)    residence)     │   country)     │   effective dates)
                               │                │
Country ── Currency            │                └── PayrollLineItem ── Payslip
   └── TaxConfiguration ── TaxBracket               │
                                               PayrollRun

User ── AuditLog (polymorphic: Employee, SalaryRecord)
User ── SalaryImport
```

## Models

### People

#### Employee

* Identifying employees (employee number and email are unique)
* Searching and filtering the roster
* Linking employees to their employments, salaries and payslips

#### Employment

* Deciding which country's tax rules apply (the **payroll country**)
* Keeping the history of an employee moving between countries
* Owning the employee's salary records

#### Department and JobTitle

* Store the organisation's departments and job titles (name and unique code).

### Salary

#### SalaryRecord

* The current salary (the open-ended record)
* Salary history (closed records)
* The exact salary a payroll line item was paid from

#### SalaryComponent

* Defining the building blocks of a salary: Base Salary, Bonus, Housing, Transport and Other Allowance
* Marking which parts of a salary count as taxable income

#### SalaryRecordComponent

* Storing each component amount (the salary total is their sum)
* Connecting `SalaryRecord` with `SalaryComponent`
* Calculating taxable income (taxable components only)

### Countries and tax

#### Country and Currency

* An employee's three distinct country roles: nationality, residence and payroll country
* Formatting money in the right currency

#### TaxConfiguration

* Stores one tax setup per country per tax year (unique on country + year), with status `active` / `inactive`.


#### TaxBracket

* Calculating income tax band by band, without any country-specific code

### Payroll

#### PayrollRun

* Running payroll for a period in the background
* Pro-rating pay: a run pays days in the period ÷ days in the year of the annual amounts

#### PayrollLineItem

* A frozen record of each payment (gross = net + tax)
* Month-wise payroll and payroll cost reporting

#### Payslip

* Showing and printing an employee's payslip for a run

### Administration

#### User

* Stores an HR user: name, unique email, role (`hr_manager`) and hashed password.

#### AuditLog

* Showing who changed a salary and when
* Tracing changes to employees and salary records