with source as (
    select * from {{ source('raw', 'customers') }}
),

renamed as (
    select
        customer_id,           -- Links directly to stg_orders.customer_id
        customer_unique_id,    -- The TRUE master key for a unique person
        customer_zip_code_prefix,
        customer_city,
        customer_state
    from source
)

select * from renamed