PRAGMA foreign_keys = ON;

drop view if exists v_order_total;
create view v_order_total as
select o.Order_id, o.Customer_id, o.Order_date, o.Order_status,
    sum(c.Quantity * c.Unit_price) as items_subtotal,
    sum(c.Quantity * c.Unit_price) - o.Discount_amount + o.Shipping_fee + o.Tax_amount as order_total
from ORDERS o
join CONTAINS c on c.Order_id = o.Order_id
group by o.Order_id;

-- USE CASE 1: Customer order history
-- Business question: what did a customer buy, and what did they pay?

-- 1a. Everything customer 1 bought, at the price paid at the time
select o.Order_id, o.Order_date, o.Order_status, p.Name as product, v.Sku_code,
    c.Quantity, c.Unit_price, c.Quantity * c.Unit_price as line_total
from ORDERS o
join CONTAINS c on c.Order_id = o.Order_id
join VARIANT v on v.Sku_id = c.Sku_id
join PRODUCT p on p.Product_id = v.Product_id
where o.Customer_id = 1
order by o.Order_date;

-- 1b. Order totals with a running total of each customer's spending (window function)
select Customer_id, Order_id, Order_date, round(order_total, 2) as order_total,
    round(sum(order_total) over (partition by Customer_id order by Order_date), 2) as running_spend
from v_order_total
order by Customer_id, Order_date;

-- 1c. Orders that never had a successful payment (subquery)
select Order_id, Order_date, Order_status
from ORDERS
where Order_id not in (select Order_id from PAYMENT where Payment_status = 'succeeded');

-- USE CASE 2: Browse and search the catalogue
-- Business question: how can a shopper find products?

-- 2a. Category tree with full path (recursive CTE)
with recursive tree(Category_id, Name, path, depth) as (
    select Category_id, Name, Name, 0
    from CATEGORY where Parent_Category_id is null
    union all
    select c.Category_id, c.Name, tree.path || ' > ' || c.Name, tree.depth + 1
    from CATEGORY c join tree on c.Parent_Category_id = tree.Category_id
)
select Category_id, path, depth from tree order by path;

-- 2b. Search buyable (active, in-stock) variants by keyword
select p.Name, v.Sku_code, v.Size, v.Color, v.Price, v.Stock_quantity
from PRODUCT p
join VARIANT v on v.Product_id = p.Product_id
where p.Status = 'active' and v.Is_active = 1 and v.Stock_quantity > 0
    and (p.Name like '%shirt%' or p.Description like '%shirt%')
order by v.Price;

-- 2c. Average rating per product (products with no reviews still appear)
select p.Name, round(avg(r.Rating), 2) as avg_rating, count(r.Review_id) as num_reviews
from PRODUCT p left join REVIEW r on r.Product_id = p.Product_id
group by p.Product_id
order by avg_rating desc;

-- USE CASE 3: Marketing analytics
-- Business question: who are our best customers and what sells together?

-- 3a. Basket analysis: which variants are bought together (self-join).
select va.Sku_code as item_a, vb.Sku_code as item_b, count(*) as times_together
from CONTAINS a
join CONTAINS b on a.Order_id = b.Order_id and a.Sku_id < b.Sku_id
join VARIANT va on va.Sku_id = a.Sku_id
join VARIANT vb on vb.Sku_id = b.Sku_id
group by a.Sku_id, b.Sku_id
order by times_together desc;

-- 3b. Rank customers by spend and segment them (RANK + CASE).
-- Refunded and cancelled orders are excluded. Thresholds suit the small dataset.
select cu.First_name, round(sum(t.order_total), 2) as total_spend,
    rank() over (order by sum(t.order_total) desc) as spend_rank,
    case when sum(t.order_total) >= 85 then 'VIP'
         when sum(t.order_total) >= 60 then 'Regular'
         else 'Low' end as segment
from CUSTOMER cu
join v_order_total t on t.Customer_id = cu.Customer_id
where t.Order_status not in ('cancelled', 'refunded')
group by cu.Customer_id;

-- 3c. Monthly revenue and month-over-month change (CTE + LAG)
with monthly as (
    select strftime('%Y-%m', Order_date) as month, sum(order_total) as revenue
    from v_order_total
    where Order_status not in ('cancelled', 'refunded')
    group by month
)
select month, round(revenue, 2) as revenue,
    round(100.0 * (revenue - lag(revenue) over (order by month))
          / lag(revenue) over (order by month), 1) as pct_change
from monthly;