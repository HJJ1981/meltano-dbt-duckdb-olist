-- Custom test: Total transactional item amounts should always be greater than zero.
-- Returns rows where the business logic is broken.

select
    order_item_key,
    total_item_amount
from {{ ref('fct_orders') }}
where total_item_amount < 0