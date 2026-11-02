--SQLite ignores foreign keys unless this is switched on, so run everytime database is opened 
PRAGMA foreign_keys = ON; 

-- Remove old tables first (children before parents) so this file can be re-run safely any number of times.
drop table if exists SHIPMENT_ITEM;
drop table if exists REVIEW;
drop table if exists SHIPMENT;
drop table if exists PAYMENT;
drop table if exists CONTAINS;
drop table if exists ORDERS;
drop table if exists HOLDS;
drop table if exists CART;
drop table if exists CLASSIFIED_IN;
drop table if exists VARIANT;
drop table if exists ADDRESS;
drop table if exists COUPON;
drop table if exists PRODUCT;
drop table if exists CATEGORY;
drop table if exists CUSTOMER;

--table with no foreign keys 
create table CUSTOMER (
    Customer_id integer primary key autoincrement, 
    First_name text not null, 
    Last_name text not null, 
    Email text not null unique, 
    Password_hash text not null, 
    Phone text, 
    Date_of_birth text, 
    Registered_at text not null default (datetime('now')),
    Account_status text not null null default 'active' check (Account_status in ('active', 'suspended', 'closed'))
);

--a category can have a parent category (self-referencing)
create table CATEGORY (
    Category_id integer primary key autoincrement, 
    Name text not null, 
    Parent_Category_id integer, 
    foreign key (Parent_Category_id) references category(Category_id)
);

create table PRODUCT (
    Product_id integer primary key autoincrement, 
    Name text not null, 
    Description text, 
    Brand text, 
    Status text not null default 'active' check (status in ('active', 'draft', 'discontinued')),
    Created_at text not null default (datetime('now'))
);

create table COUPON (
    Coupon_id integer primary key autoincrement, 
    Code text not null unique, 
    Discount_type text not null check (Discount_type in ('percent', 'fixed')), 
    Discount_value real not null check (Discount_value > 0),
    Valid_from text not null, 
    Valid_to text not null, 
    Usage_limit integer, 
    check (Valid_to >= Valid_from)
);

--these tables are dependent on the ones above 
create table ADDRESS (
    Address_id integer primary key autoincrement, 
    Line1 text not null,
    Line2 text, 
    City text not null, 
    Postcode text not null, 
    Country text not null, 
    Is_default integer not null default 0 check (Is_default in (0,1)),
    Is_active integer not null default 1 check (Is_active in (0,1)),
    Customer_id integer not null, 
    foreign key (Customer_id) references CUSTOMER(Customer_id)
);

--price and stock live on the variant (SKU)
create table VARIANT (
    Sku_id integer primary key autoincrement, 
    Sku_code text not null unique, 
    Size text, 
    Color text, 
    Price real not null check (price >= 0), 
    Stock_quantity integer not null default 0 check (Stock_quantity >= 0),
    Is_active integer not null default 1 check (Is_active in (0,1)),
    Product_id integer not null, 
    foreign key (Product_id) references PRODUCT(Product_id)
);

--a product can be in several categories (many to many)
create table CLASSIFIED_IN (
    Product_id integer not null, 
    Category_id integer not null, 
    primary key (Product_id, Category_id),
    foreign key (Product_id) references PRODUCT(Product_id),
    foreign key (Category_id) references CATEGORY(Category_id)
);

--Unique on Customer_id (at most one cart per customer)
create table CART (
    Cart_id integer primary key autoincrement, 
    Created_at text not null default (datetime('now')), 
    Updated_at text not null default (datetime('now')), 
    Customer_id integer not null unique, 
    foreign key (Customer_id) references CUSTOMER(Customer_id)
);

create table HOLDS (
    Cart_id integer not null, 
    Sku_id integer not null, 
    Quantity integer not null check (Quantity > 0),
    Added_at text not null default (datetime('now')), 
    primary key (Cart_id, Sku_id),
    foreign key (Cart_id) references CART(Cart_id),
    foreign key (Sku_id) references VARIANT(Sku_id)
);

--two FK for address (shipping, billing)
create table ORDERS (
    Order_id integer primary key autoincrement, 
    Order_date text not null default (date('now')), 
    Order_status text not null default 'pending' check (Order_status in ('pending', 'paid', 'shipped', 'delivered', 'cancelled', 'refunded')), 
    Shipping_fee real not null default 0 check (Shipping_fee >= 0), 
    Tax_amount real not null default 0 check (Tax_amount >= 0),
    Discount_amount real not null default 0 check (Discount_amount >= 0),
    Currency text not null default 'GBP', 
    Customer_id integer not null, 
    Shipping_address_id integer not null, 
    Billing_address_id integer not null, 
    Coupon_id integer, 
    foreign key (Customer_id) references CUSTOMER(Customer_id),
    foreign key (Shipping_address_id) references ADDRESS(Address_id),
    foreign key (Billing_address_id) references ADDRESS(Address_id),
    foreign key (Coupon_id) references COUPON(Coupon_id)
);

create table CONTAINS (
    Order_id integer not null, 
    Sku_id integer not null, 
    Quantity integer not null check (Quantity > 0),
    Unit_price real not null check (Unit_price >= 0),
    Discount_amount real not null default 0 check (Discount_amount >= 0),
    primary key (Order_id, Sku_id), 
    foreign key (Order_id) references ORDERS(Order_id),
    foreign key (Sku_id) references VARIANT(Sku_id)
);

--one row per payment attempt (failed attempts, refunds)
create table PAYMENT (
    Payment_id integer primary key autoincrement,
    Method text not null check (Method in ('card', 'paypal', 'bank transfer', 'other')), 
    Amount real not null check (Amount > 0), 
    Payment_status text not null check (Payment_status in ('pending', 'failed', 'succeeded', 'refunded')),
    transaction_ref text not null unique, 
    paid_at text, 
    order_id integer not null, 
    foreign key (order_id) references ORDERS(order_id)
);

create table SHIPMENT (
    Shipment_id integer primary key autoincrement, 
    Carrier text not null, 
    Tracking_num text, 
    Shipment_status text not null default 'preparing' check (Shipment_status in ('preparing', 'shipped', 'in_transit', 'delivered', 'returned')),
    Shipped_at text, 
    Delivered_at text, 
    Order_id integer not null, 
    foreign key (Order_id) references ORDERS(order_id)
);

--one review per customer per product 
create table REVIEW (
    Review_id integer primary key autoincrement, 
    Rating integer not null check (Rating Between 1 and 5), 
    Title text, 
    Comment_txt text, 
    Created_at text not null default (datetime('now')), 
    Customer_id integer not null, 
    Product_id integer not null, 
    Unique (Customer_id, Product_id), 
    foreign key (Customer_id) references CUSTOMER(Customer_id), 
    foreign key (Product_id) references PRODUCT(Product_id)
);

--parcel shipped to multiple sections
create table SHIPMENT_ITEM (
    Shipment_id integer not null, 
    Order_id integer not null, 
    Sku_id integer not null, 
    Quantity integer not null check (Quantity > 0),
    primary key (Shipment_id, Sku_id),
    foreign key (Shipment_id) references SHIPMENT(Shipment_id),
    foreign key(Order_id, Sku_id) references CONTAINS(Order_id, Sku_id)
);