with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

-- 1. Bring in the customer staging table to get the unique human ID
customers as (
    select customer_id, customer_unique_id from {{ ref('stg_customers') }}
),

final as (
    select
       md5(cast(coalesce(cast(o.order_id as string), '') || '-' || 
                 coalesce(cast(i.product_id as string), '') || '-' || 
                 coalesce(cast(i.line_item_number as string), '') as string)) as order_item_key,
        
        o.order_id,
        o.customer_id,
        c.customer_unique_id,  -- 2. Pull the clean human ID into your final select list!
        i.product_id,  
        i.line_item_number, 
        
        o.order_status,
        o.order_purchase_at,
        o.order_delivered_customer_at,
        o.order_estimated_delivery_at,
        
        1 as item_count,
        i.price as item_price,
        i.freight_value as item_freight_value,
        (i.price + i.freight_value) as total_item_amount,

        date_diff('day', o.order_purchase_at, o.order_delivered_customer_at) as days_to_delivery,
        date_diff('day', o.order_estimated_delivery_at, o.order_delivered_customer_at) as delivery_delay_days

    from orders o
    inner join order_items i 
        on o.order_id = i.order_id
    -- 3. Join to the customer dimension table using the receipt token
    left join customers c
        on o.customer_id = c.customer_id
)

select * from final
where customer_unique_id is not null 
  and customer_unique_id != ''