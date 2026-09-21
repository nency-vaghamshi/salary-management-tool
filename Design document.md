# Database Design

## Models

### Employee

Stores basic employee information.

**Used for:**

* Identifying employees
* Linking employees with salary records
* Filtering salary data by department, job title, and country

### SalaryRecord

Stores an employee's salary information for a specific period.

**Used for:**

* Maintaining current salary
* Maintaining salary history
* Tracking salary changes over time

### PayComponent

Defines salary components such as Basic Salary, HRA, Bonus, PF, etc.

**Used for:**

* Defining different salary components
* Reusing components across employees
* Supporting different salary structures

### SalaryComponentValue

Stores the actual value of a salary component for a salary record.

**Used for:**

* Storing the amount of each component
* Connecting `SalaryRecord` with `PayComponent`
* Calculating total salary

### Department

Stores employee department information.

**Used for:**

* Grouping employees
* Department-wise salary analytics

### Country

Stores country information.

**Used for:**

* Managing employees across multiple countries
* Country-wise salary analytics
* Supporting country-specific salary information

---

## Relationships

* Employee has many SalaryRecords
* SalaryRecord belongs to Employee
* SalaryRecord has many SalaryComponentValues
* SalaryComponentValue belongs to SalaryRecord
* SalaryComponentValue belongs to PayComponent
* Employee belongs to Department
* Employee belongs to Country

---

## Important Design Factors

### Salary History

Salary changes should create a new salary record instead of overwriting the previous salary.

### Reusable Components

Salary components are stored separately so the same component can be used for multiple employees.

### Auditability

Important salary changes should be recorded so HR can know what was changed and when.

