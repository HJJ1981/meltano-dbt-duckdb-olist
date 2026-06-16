with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed_and_casted as (
    select
        order_id,
        customer_id,
        order_status,
        
        -- Safely casting string timestamps into actual datetime types
        cast(order_purchase_timestamp as timestamp) as order_purchase_at,
        cast(order_approved_at as timestamp) as order_approved_at,
        cast(order_delivered_carrier_date as timestamp) as order_delivered_carrier_at,
        cast(order_delivered_customer_date as timestamp) as order_delivered_customer_at,
        cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_at
    from source
)

select * from renamed_and_casted