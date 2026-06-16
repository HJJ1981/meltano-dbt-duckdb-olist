with products as (
    select * from {{ ref('stg_products') }}
),

product_category_translation as (
    select * from {{ ref('stg_product_category_name_translation') }}
),

fct_orders as (
    -- Bringing in our fresh item-level fact table
    select * from {{ ref('fct_orders') }}
),

customers as (
    -- Bringing in the customer staging table to get the true customer_unique_id
    select * from {{ ref('stg_customers') }}
),

-- 1. Identify all unique product IDs that have actually been ordered
ordered_product_ids as (
    select distinct product_id from fct_orders
),

-- 2. Master list of products: Combines known catalog with orphan IDs from orders
final_base_products as (
    select 
        product_id,
        product_category_name
    from products

    union all

    select 
        o.product_id,
        'missing_catalog_data' as product_category_name -- Our internal flag for orphans
    from ordered_product_ids o
    left join products p 
        on o.product_id = p.product_id
    where p.product_id is null -- Only grabs the IDs missing from stg_products
),

product_buyer_counts as (
    select
        fo.product_id,
        -- Operational metrics (Volume)
        count(fo.order_id) as total_units_sold,
        
        -- Market Penetration metrics (Unique Customers)
        count(distinct c.customer_unique_id) as unique_customer_count
        
    from fct_orders fo
    inner join customers c 
        on fo.customer_id = c.customer_id
    group by 1
)

select
    p.product_id,
    p.product_category_name,
    
    -- 3. If it's an orphan, map its English translation directly to 'Missing Catalog Data'
    coalesce(t.product_category_name_english, 'Missing Catalog Data') as product_category_name_english,
    
    -- Popularity Metrics
    coalesce(pbc.total_units_sold, 0) as total_units_sold,
    coalesce(pbc.unique_customer_count, 0) as unique_customer_count,
    
    -- Categorizing popularity based on unique buyers
    case 
        when pbc.unique_customer_count >= 50 then 'Mass Appeal'
        when pbc.unique_customer_count between 10 and 49 then 'Steady Seller'
        when pbc.unique_customer_count between 1 and 9 then 'Niche Product'
        else 'Unsold Inventory'
    end as product_popularity_segment

-- 4. Drive the query from our new self-healing base product list
from final_base_products p
left join product_category_translation t
    on p.product_category_name = t.product_category_name
left join product_buyer_counts pbc
    on p.product_id = pbc.product_id