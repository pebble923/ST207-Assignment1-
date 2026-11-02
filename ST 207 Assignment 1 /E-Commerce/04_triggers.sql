PRAGMA foreign_keys = ON;

drop trigger if exists trg_check_stock;
drop trigger if exists trg_decrement_stock;
drop trigger if exists trg_coupon_dates;
drop trigger if exists trg_coupon_limit;

-- SITUATION 1: Stock 
-- Block an order line that asks for more than is in stock or for a variant that is switched off
create trigger trg_check_stock
before insert on CONTAINS
for each row 
when NEW.Quantity > (select Stock_quantity from VARIANT where Sku_id = NEW.Sku_id)
    or (select Is_active from VARIANT where Sku_id = NEW.Sku_id) = 0
begin 
    select raise(abort, 'Insufficient stock or inactive product variant');
end;

-- If the insert was allowed, subtract the quantity from stock 
create trigger trg_decrement_stock
after insert on CONTAINS
for each row 
begin 
    update VARIANT
    set Stock_quantity = Stock_quantity - NEW.Quantity
    where Sku_id = NEW.Sku_id;
end;



-- SITUATION 2: Coupons 
-- Reject a coupon used outside its validity dates 
create trigger trg_coupon_dates
before insert on ORDERS
for each row 
when NEW.Coupon_id is not NULL and (
    date(NEW.Order_date) < (select Valid_from from COUPON where Coupon_id = NEW.Coupon_id)
    or date(NEW.Order_date) > (select Valid_to from COUPON where Coupon_id = NEW.Coupon_id)
)
begin 
    select raise(Abort, 'Coupon is expired or not yet valid');
end;

-- Reject a coupon that has reached its usage limit (NULL limit = unlimited)
create trigger trg_coupon_limit
before insert on ORDERS
for each row
when NEW.Coupon_id is not NULL and (select Usage_limit from COUPON where Coupon_id = NEW.Coupon_id) is not NULL
and (select count(*) from ORDERS where Coupon_id = NEW.Coupon_id and Order_status <> 'cancelled') 
>= (select Usage_limit from COUPON where Coupon_id = NEW.Coupon_id)
begin 
    select raise(abort, 'Coupon Usage Limit Reached');
end;