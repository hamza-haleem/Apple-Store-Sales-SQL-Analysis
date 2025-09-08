-- Apple Retails Sales Schema

-- Drop Table Commands
drop table if exists warranty;
drop table if exists sales;
drop table if exists products;
drop table if exists category;
drop table if exists stores;

-- Create Table Commands

-- CATEGORY TABLE
CREATE TABLE category (
    category_id VARCHAR(10) PRIMARY KEY,
    category_name VARCHAR(20)
);

-- PRODUCTS TABLE
CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(35),
    category_id VARCHAR(10),
    launch_date DATE,
    price DOUBLE PRECISION,
    CONSTRAINT fk_category
        FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- STORES TABLE
CREATE TABLE stores (
    store_id VARCHAR(5) PRIMARY KEY,
    store_name VARCHAR(30),
    city VARCHAR(25),
    country VARCHAR(25)
);

-- SALES TABLE
CREATE TABLE sales (
    sale_id VARCHAR(15) PRIMARY KEY,
    sale_date DATE,
    store_id VARCHAR(10),
    product_id VARCHAR(10),
    quantity INTEGER,
    CONSTRAINT fk_store
        FOREIGN KEY (store_id) REFERENCES stores(store_id),
    CONSTRAINT fk_product
        FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- WARRANTY TABLE
CREATE TABLE warranty (
    claim_id VARCHAR(10) PRIMARY KEY,
    claim_date DATE,
    sale_id VARCHAR(15),
    repair_status VARCHAR(15),
    CONSTRAINT fk_sale
        FOREIGN KEY (sale_id) REFERENCES sales(sale_id)
);

-- Success Message
SELECT 'Schema created successful' as Success_Message;