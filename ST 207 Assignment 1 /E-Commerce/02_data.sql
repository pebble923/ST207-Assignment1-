--sample data
PRAGMA foreign_keys = ON;

insert into CUSTOMER (First_name, Last_name, Email, Password_hash, Phone, Date_of_birth) values 
('Alice', 'Smith', 'alice@example.com', 'hash1', '07000000001', '1995-04-12'),
('Ben', 'Carter', 'ben@example.com', 'hash2', NULL, '1988-09-30'),
('Chloe', 'Silva', 'chloe123@example.com', 'hash3', '07000000003', NULL), 
('Dev', 'Patel', 'devpatel@example.com', 'hash4', NULL, '2001-01-05'),
('Halle', 'Bailey', 'halle@example.com', 'hash5', '07000000005', '1992-12-20');

--Alice has 2 addresses 
insert into ADDRESS (Line1, Line2, City, Postcode, Country, Is_default, Customer_id) values 
('1 High St', NULL, 'London', 'E1 1AA', 'UK', 1, 1),
('22 Park Rd', 'Flat 3', 'London', 'N1 2BB', 'UK', 0, 1),
('5 Mill Ln', NULL,'Leeds','LS1 3CC','UK',1,2),
('9 Oak Ave', NULL,'Bristol','BS1 4DD','UK',1,3),
('77 River St', NULL,' York','YO1 5EE','UK',1,4),
('14 Elm Rd', NULL,'Bath','BA1 6FF','UK',1,5);

--Category Tree: clothing -> shoes, tshirts; electronics -> headphones, accessories 
insert into CATEGORY (Category_id, Name, Parent_Category_id) values 
(1, 'Clothing', NULL),
(2, 'Shoes', 1),
(3, 'T-Shirts', 1),
(4, 'Electronics', NULL), 
(5, 'Headphones', 4),
(6, 'Accessories', 4);

insert into PRODUCT (Product_id, Name, Description, Brand, Status) values 
(1, 'Classic T-Shirt', 'Soft cotton tee', 'Uniwear', 'active'),
(2, 'Running Shoes', 'Lightweight trainers', 'SprintX', 'active'),
(3, 'Wireless Headphones', 'Bluetooth over-ear', 'SoundMax', 'active'),
(4, 'Hoodie', 'Warm fleece hoodie', 'Women', 'active'),
(5, 'Phone Case', 'Protective Case', 'Casify', 'active');

--price and stock live on the variant 
insert into VARIANT (Sku_id, Sku_code, Size, Color, Price, Stock_quantity, Product_id) values 
(1,'TEE-S-BLK','S','Black',15.00,50,1),
(2,'TEE-M-BLK','M','Black',15.00,40,1),
(3,'TEE-M-WHT','M','White',15.00,30,1),
(4,'RUN-42-RED','42','Red',60.00,10,2),
(5,'RUN-43-RED','43','Red',60.00,5,2),
(6,'HP-BLK',NULL,'Black',80.00,20,3),
(7,'HOOD-L-GRY','L','Grey',35.00,25,4),
(8,'CASE-STD',NULL,NULL,10.00,100,5);

insert into CLASSIFIED_IN (Product_id, Category_id) values
(1,3),(1,1),
(2,2),(2,1),
(3,5),(3,4),
(4,1),
(5,6),(5,4);

insert into COUPON (Coupon_id, Code, Discount_type, Discount_value, Valid_from, Valid_to, Usage_limit) values 
(1,'WELCOME10','percent',10,'2026-01-01','2026-12-31',NULL),
(2,'SAVE5','fixed',5,'2026-01-01','2026-12-31',1),
(3,'OLD20','percent',20,'2025-01-01','2025-06-30',NULL);

insert into CART (Cart_id, Customer_id) values (1, 2), (2, 5);
insert into HOLDS (Cart_id, Sku_id, Quantity) values (1,6,1), (2,1,2), (2,8,1);

insert into ORDERS (Order_id, Order_date, Order_status, Shipping_fee, Tax_amount, Discount_amount, Customer_id, Shipping_address_id, Billing_address_id, Coupon_id) values 
(1,'2026-09-01','delivered',3.99,5.00,6.50,1,1,1,1),
(2,'2026-09-15','shipped',4.99,6.00,0,2,3,3,NULL),
(3,'2026-10-01','paid',0,6.00,5.00,3,4,4,2),
(4,'2026-10-10','refunded',4.99,5.00,0,1,2,1,NULL),
(5,'2026-10-20','pending',3.99,3.00,0,4,5,5,NULL);

insert into CONTAINS (Order_id, Sku_id, Quantity, Unit_price, Discount_amount) values 
(1,2,2,15.00,0),(1,7,1,35.00,0),
(2,4,1,60.00,0),(2,8,2,10.00,0),
(3,6,1,80.00,0),
(4,5,1,60.00,0),
(5,3,3,15.00,0);

insert into PAYMENT (Order_id, Method, Amount, Payment_status, transaction_ref, paid_at) values 
(1,'card',67.49,'succeeded','TXN-0001','2026-09-01 10:00:00'),
(2,'paypal',90.99,'succeeded','TXN-0002','2026-09-15 12:30:00'),
(3,'card',81.00,'succeeded','TXN-0003','2026-10-01 09:15:00'),
(4,'card',69.99,'failed','TXN-0004',NULL),
(4,'card',69.99,'succeeded','TXN-0005','2026-10-10 14:00:00'),
(4,'card',69.99,'refunded','TXN-0006','2026-10-15 11:00:00'),
(5,'card',51.99,'failed','TXN-0007',NULL);

insert into SHIPMENT (Shipment_id, Carrier, Tracking_num, Shipment_status, Shipped_at, Delivered_at, Order_id) values 
(1,'DHL','DHL123','delivered','2026-09-02','2026-09-04',1),
(2,'DHL','DHL124','delivered','2026-09-03','2026-09-06',1),
(3,'UPS','UPS555','in_transit','2026-09-16',NULL,2),
(4,'DHL','DHL900','delivered','2026-10-11','2026-10-13',4);

insert into SHIPMENT_ITEM (Shipment_id, Order_id, Sku_id, Quantity) values 
(1,1,2,2),
(2,1,7,1),
(3,2,4,1),
(3,2,8,2),
(4,4,5,1);

insert into REVIEW (Customer_id, Product_id, Rating, Title, Comment_txt) values 
(1,1,5,'Great fit','Love it'),
(1,4,5,'Very warm',NULL),
(2,2,4,'Comfy','Runs slightly small'),
(3,3,2,'Poor battery','Dies in two hours');


