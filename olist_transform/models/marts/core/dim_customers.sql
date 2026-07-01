with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

-- Step 1: Rank addresses for customers who moved, prioritizing their latest purchase date
ranked_customer_geography as (
    select
        c.customer_unique_id,
        c.customer_state,
        c.customer_city,
        row_number() over (
            partition by c.customer_unique_id 
            -- FIX: Left join with orders means order_purchase_at can be null for zero-order accounts
            order by o.order_purchase_at desc nulls last, c.customer_id desc
        ) as location_rank
    -- CRITICAL FIX: Changed from INNER JOIN to RIGHT JOIN (or LEFT JOIN from customers)
    -- If a customer registered but has 0 orders, an INNER JOIN drops them entirely from your dim table!
    from orders o
    right join customers c 
        on o.customer_id = c.customer_id
),

-- Step 2: Keep ONLY the latest single location per human
latest_geography as (
    select 
        customer_unique_id,
        customer_state,
        customer_city
    from ranked_customer_geography
    where location_rank = 1
),

-- Step 3: Run your metrics over the fact table at the pure human grain
-- Note: Coalescing metrics to 0 so customers with no orders don't show up as completely NULL
customer_orders_aggregated as (
    select
        c.customer_unique_id,
        min(o.order_purchase_at) as first_purchase_at,
        max(o.order_purchase_at) as most_recent_purchase_at,
        count(distinct o.order_id) as total_orders,
        coalesce(sum(o.total_item_amount), 0) as lifetime_value,
        coalesce(avg(o.total_item_amount), 0) as average_order_item_value
    from customers c
    left join orders o on c.customer_id = o.customer_id
    group by 1
)

-- Step 4: Stitch the metrics and the single latest location back together perfectly
select 
    g.customer_unique_id,
    g.customer_state,         
    g.customer_city,         
    a.first_purchase_at,
    a.most_recent_purchase_at,
    a.total_orders,
    a.lifetime_value,
    a.average_order_item_value,

    case 
        when a.total_orders = 1 then 'One-Time Buyer'
        when a.total_orders = 2 then 'Repeat Customer'
        when a.total_orders >= 3 then 'Loyal Core'
        else 'Registered / No Orders' -- Handles the 0-orders edge case safely
    end as customer_segment,

    -- NEW: The Power BI Sort Column
    case 
        when a.total_orders >= 3 then 1     -- Loyal Core at the top of the stack
        when a.total_orders = 2 then 2      -- Repeat Customer in the middle
        when a.total_orders = 1 then 3      -- One-Time Buyer at the bottom
        else 4                              -- No orders fallback
    end as customer_segment_sort

from latest_geography g
inner join customer_orders_aggregated a 
    on g.customer_unique_id = a.customer_unique_id