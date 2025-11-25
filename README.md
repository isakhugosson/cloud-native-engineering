# Cloud-Native Analytics Demo

End-to-end demo of a **modern analytics stack** running on a small Debian server:

- **PostgreSQL** in Docker for raw + analytics databases  
- **SQLMesh** for version-controlled transformations as for T in ELT/ETL
- **Cube.dev** as a semantic layer & API ready for embedded analytics and AI-ready

The goal is to show how you can go from **raw data** → **DW star schema** → **API / charts** in a cloud-native way. 
- Version-controlled all the way😍

---

## Architecture

**Docker Containers:**

- `postgres`
  - Image: `postgres:16`
  - Databases:
    - `analytics_dev` – DW for development
    - `analytics_prod` – DW for “prod”
  - Init scripts in `db/init/`:
    - `001_create_databases.sql` – creates databases
    - `010_sa_raw_schema.sql` – schema `raw` + `raw.generalledger`
    - `020_seed_generalledger.sql` – seeds fictive general ledger rows

- `cube`
  - Image: `cubejs/cube:latest`
  - Connects to PostgreSQL (`analytics_dev` or `analytics_prod`, depending on env vars)
  - Loads cube definitions from `cube/model/*.yml`
  - Dev UI exposed on port **4000**

**SQLMesh:**

- gateway **dev** → `analytics_dev`
- gateway **prod** → `analytics_prod`

DW schema (`dw`) contains a small **star schema**:

- `dw.dim_company`
  - `company_key` (surrogate key, bigint)
  - `company_code`, `company_name`, `updated_at`
- `dw.dim_account`
  - `account_key`
  - `account_no`, `account_name`, `account_group`, `updated_at`
- `dw.dim_project`
  - `project_key`
  - `project_code`, `project_name`, `updated_at`
- `dw.fact_generalledger`
  - `company_key`, `account_key`, `project_key`
  - `posting_date` (date)
  - `amount` (numeric)
  - `voucher_id`

`fact_generalledger` is defined as an **incremental model** by month with a 3-month lookback.

**Semantic layer:**

- Cubes:
  - `dim_company`, `dim_account`, `dim_project`
  - `fact_generalledger`
- Joins:
  - `fact_generalledger` → `dim_company` on `company_key`
  - `fact_generalledger` → `dim_account` on `account_key`
  - `fact_generalledger` → `dim_project` on `project_key`
- Measures:
  - `fact_generalledger.amount` – `sum(amount)` (Utfall)
  - `fact_generalledger.row_count` – `count(*)`
- Dimensions:
  - `posting_date` (time)
  - `company_name`, `account_group`, etc.

This gives a nice generalledger view directly through Cube Playground or REST API.

