with source as (
    select * from {{ source('raw', 'order_items') }}
),

renamed_and_casted as (
    select
        order_id,
        order_item_id as line_item_number,
        product_id,
        seller_id,
        cast(shipping_limit_date as timestamp) as shipping_limit_at,
        
        -- Ensuring our financial metrics are floats for precise math
        cast(price as double) as price,
        cast(freight_value as double) as freight_value
    from source
)

select * from renamed_and_casted