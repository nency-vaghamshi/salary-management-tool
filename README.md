# Salary Management Software

A web-based system replacing HR's Excel-based salary tracking — managing multi-country compensation, tax, and payslips for 10,000 employees, with built-in salary analytics.

## Description

ACME's HR team currently manages salary data for 10,000 employees across multiple countries entirely through Excel — a process that is slow, error-prone, and gives no easy way to answer basic questions about the org's own pay data. This module replaces that spreadsheet workflow with a web-based Ruby on Rails application that lets the HR manager maintain salary records directly and query them for insight, instead of maintaining pivot tables by hand.

### Problem statement

Currently, ACME org's HR team manages salary data for 10,000 employees across multiple countries, with everything managed via Excel, which is tedious. We want the HR manager to manage the salary data via web-based software and be able to answer questions about how the org pays people.

## Table of Contents

* [Features](#features)
* [Data Model](#data-model)
* [Tech Stack](#tech-stack)
* [Installation](#installation)
* [Usage](#usage)

## Features

> **Note:** The following features are part of the initial scope and are not finalized. They may change or be added during the design and development process.

### 1. Employee salary management

* CRUD salary information, with **activate/deactivate** (not delete) so history is preserved
* View salary history per employee
* Import salary data from Excel (with preview before committing)
* Generate payslip

### 2. Salary components & payroll calculation

* Configurable salary components (earnings: basic, HRA, bonus; deductions: PF, statutory deductions, etc.)
* Payroll calculation engine that computes gross → net per employee, per country, using their assigned components and applicable tax rules

### 3. Multi-country salary management

* Country-specific currency per employee/salary record
* Exchange-rate handling, used only for cross-country reporting — never for altering an employee's actual local-currency pay
* Full audit log of every HR action

### 4. Income tax data (country-specific)

* Tax slabs/rules stored as data per country (not hardcoded), since tax law changes on its own schedule per country
* Feeds directly into payroll calculation and payslip generation

### 5. Dashboard & salary analytics

* Filterable analytics view
* Total salary expenditure
* Salary breakdown by country, department, and job title
* Average, highest, and lowest salary

## Tech Stack

| Technology    | Version    |
| ------------- | ---------- |
| Ruby          | `3.2.0`    |
| Ruby on Rails | `8.0.5.1`  |
| Database      | PostgreSQL |


## Installation

This module is currently in the **design/planning stage** — no application code exists yet. Once implementation starts:

```bash
bundle install

bundle exec rails db:create db:migrate db:seed

bundle exec rails server
```

Environment-specific configuration (database credentials, encryption keys for salary data) will be documented here once the app is scaffolded.
