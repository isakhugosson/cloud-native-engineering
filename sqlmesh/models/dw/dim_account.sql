MODEL (
  name dw.dim_account,
  kind FULL,
  grain (account_key)
);

with base as (

  select
    account_no::int                  as account_no,
    concat('Konto ', account_no)     as account_name,
    case
      when account_no like '3%' then 'Intäkter'
      when account_no like '4%' then 'Kostnad sålda varor'
      when account_no like '5%' then 'Personalkostnader'
      when account_no like '7%' then 'Övriga externa kostnader'
      else 'Övrigt'
    end                              as account_group,
    max(created_at)                  as updated_at

  from raw.generalledger
  where account_no is not null

  group by 1,2,3
),

with_sk as (

  select
    abs(hashtextextended(account_no::text, 0))::bigint as account_key,
    account_no,
    account_name,
    account_group,
    updated_at
  from base
)

select
  account_key,
  account_no,
  account_name,
  account_group,
  updated_at
from with_sk;