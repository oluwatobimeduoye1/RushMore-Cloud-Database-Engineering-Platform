
-- TABLE 1: Stores
-- Holds information for each physical pizzeria location
CREATE TABLE Stores (
    store_id        SERIAL          PRIMARY KEY,
    address         VARCHAR(100)    NOT NULL,
    city            VARCHAR(100)    NOT NULL,
    contact_number    VARCHAR(20)     UNIQUE NOT NULL,
    opened_at       TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 2: Customers
-- Stores PII for all registered customers
CREATE TABLE Customers (
    customer_id     SERIAL          PRIMARY KEY,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    email           VARCHAR(255)    UNIQUE NOT NULL,
    phone_number    VARCHAR(20)     UNIQUE NOT NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 3: Ingredients
-- Master list of all raw ingredients used to make menu items
CREATE TABLE Ingredients (
    ingredient_id   SERIAL          PRIMARY KEY,
    name            VARCHAR(100)    UNIQUE NOT NULL,
    stock_quantity  NUMERIC(10, 2)  NOT NULL DEFAULT 0,
    unit            VARCHAR(20)     NOT NULL,

    CONSTRAINT chk_stock_quantity CHECK (stock_quantity >= 0)
);

-- TABLE 4: Menu_Items
-- Master product catalog for all items sold
CREATE TABLE Menu_Items (
    item_id         SERIAL          PRIMARY KEY,
    name            VARCHAR(150)    NOT NULL,
    category        VARCHAR(50)     NOT NULL,
    size            VARCHAR(20)     DEFAULT 'N/A',
    price           NUMERIC(10, 2)  NOT NULL,

    -- Data quality: price must be greater than zero
    CONSTRAINT chk_price CHECK (price > 0),

    -- Data quality: category must be a known value
    CONSTRAINT chk_category CHECK (category IN ('Pizza', 'Drink', 'Side'))
);

-- TABLE 6: Orders
-- Master transaction table — each row is one complete order
CREATE TABLE Orders (
    order_id            SERIAL          PRIMARY KEY,
    customer_id         INTEGER,
    store_id            INTEGER         NOT NULL,
    order_timestamp     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount        NUMERIC(10, 2)  NOT NULL,

    -- FK to Customers: SET NULL on delete so order history
    -- is preserved even if a customer account is deleted
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES Customers(customer_id) ON DELETE SET NULL,

    -- FK to Stores: RESTRICT delete to prevent orphaning order data
    CONSTRAINT fk_orders_store    FOREIGN KEY (store_id)
        REFERENCES Stores(store_id) ON DELETE RESTRICT,

    -- Data quality: total must be greater than zero
    CONSTRAINT chk_total_amount CHECK (total_amount > 0)
);



-- TABLE 7: Order_Items
-- Line items for each order — what was actually ordered
CREATE TABLE Order_Items (
    order_item_id   SERIAL          PRIMARY KEY,
    order_id        INTEGER         NOT NULL,
    item_id         INTEGER         NOT NULL,
    quantity        INTEGER         NOT NULL,
    unit_price      NUMERIC(10, 2)  NOT NULL,

	-- FK to Orders: CASCADE delete — if an order is deleted,
    -- its line items should be deleted too
    CONSTRAINT fk_oi_order FOREIGN KEY (order_id)
        REFERENCES Orders(order_id) ON DELETE CASCADE,

    -- FK to Menu_Items: RESTRICT delete — can't delete a menu
    -- item that appears in existing orders (historical record)
    CONSTRAINT fk_oi_item  FOREIGN KEY (item_id)
        REFERENCES Menu_Items(item_id) ON DELETE RESTRICT,

    -- Data quality constraints
    CONSTRAINT chk_oi_quantity   CHECK (quantity >= 1),
    CONSTRAINT chk_oi_unit_price CHECK (unit_price > 0)
);


-- INDEXES — for fast retrieval on commonly queried columns
CREATE INDEX idx_orders_customer_id    ON Orders(customer_id);
CREATE INDEX idx_orders_store_id       ON Orders(store_id);
CREATE INDEX idx_order_items_order_id ON Order_Items(order_id);
CREATE INDEX idx_order_items_item_id  ON Order_Items(item_id);


-- TABLE 5: Menu_Item_Ingredients (Bridge Table)
-- Connects Menu_Items to Ingredients (Many-to-Many)
CREATE TABLE Menu_Item_Ingredients (
    menu_ingredient_id  SERIAL          PRIMARY KEY,
    item_id             INTEGER         NOT NULL,
    ingredient_id       INTEGER         NOT NULL,
    quantity_needed     NUMERIC(10, 2)  NOT NULL,

    -- Foreign Keys
    CONSTRAINT fk_mii_item       FOREIGN KEY (item_id)
        REFERENCES Menu_Items(item_id) ON DELETE CASCADE,

    CONSTRAINT fk_mii_ingredient FOREIGN KEY (ingredient_id)
        REFERENCES Ingredients(ingredient_id) ON DELETE CASCADE,

    -- Data quality: quantity must be greater than zero
    CONSTRAINT chk_quantity_needed CHECK (quantity_needed > 0),

    -- Prevent duplicate ingredient entries for the same menu item
    CONSTRAINT uq_item_ingredient UNIQUE (item_id, ingredient_id)
);












