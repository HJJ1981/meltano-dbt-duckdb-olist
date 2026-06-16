with source as (
    select * from {{ source('raw', 'products') }}
),

renamed_and_casted as (
    select
        product_id,
        product_category_name,
        
        -- Explicitly fixing our data types once and for all!
        cast(product_weight_g as integer) as product_weight_g,
        cast(product_length_cm as integer) as product_length_cm,
        cast(product_height_cm as integer) as product_height_cm,
        cast(product_width_cm as integer) as product_width_cm
    from source
)

select * from renamed_and_casted
