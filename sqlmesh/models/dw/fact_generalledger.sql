MODEL (
  name dw.fact_generalledger,            
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column posting_date,
    lookback 90 -- Handle late-arriving data
  ),
  start '2023-01-01',
  cron '@daily',
  grain (
    company_key,
    account_key,
    project_key,
    posting_date,
    voucher_id
  )
);

with base as (

  select
    company_code                as company_code,
    account_no::int             as account_no,
    project_code                as project_code,
    posting_date,
    amount::numeric(18, 2)      as amount,
    voucher_no                  as voucher_id,
    created_at                  as load_timestamp
  from raw.generalledger
  where posting_date between @start_date and @end_date
),

company_match as (

  select
    b.*,
    dc.company_key
  from base b
  inner join dw.dim_company dc
    on b.company_code = dc.company_code
),

account_match as (

  select
    c.*,
    da.account_key
  from company_match c
  inner join dw.dim_account da
    on c.account_no = da.account_no
),

project_match as (

  select
    a.*,
    dp.project_key
  from account_match a
  left join dw.dim_project dp
    on a.project_code = dp.project_code
)

select
  company_key,
  account_key,
  project_key,
  posting_date,
  amount,
  voucher_id,
  load_timestamp
from project_match;