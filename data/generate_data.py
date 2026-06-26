"""
Generates a synthetic but behaviorally realistic e-commerce relational dataset
(customers, products, orders, order_items) into ecommerce.db.

Patterns intentionally built in so SQL analysis surfaces real signal:
- Monthly cohort retention decays over time, varying by acquisition channel.
- Customer value tier drives both order frequency and basket size (so RFM
  segmentation produces a genuine spread, not noise).
- Seasonal order volume lift in November/December.
"""
import sqlite3
import random
from datetime import date, timedelta

random.seed(42)

DB_PATH = "ecommerce.db"
START_DATE = date(2023, 1, 1)
SNAPSHOT_DATE = date(2024, 12, 31)
N_CUSTOMERS = 2000

REGIONS = ["North America", "Europe", "Asia", "South America"]
CHANNELS = {
    "Referral": 1.3,
    "Organic Search": 1.1,
    "Paid Ads": 0.8,
    "Social Media": 0.7,
}
VALUE_TIERS = {
    "high": {"weight": 0.15, "order_mult": 1.8, "basket_mult": 2.2},
    "mid": {"weight": 0.45, "order_mult": 1.1, "basket_mult": 1.2},
    "low": {"weight": 0.40, "order_mult": 0.6, "basket_mult": 0.7},
}

CATEGORIES = {
    "Electronics": (40, 800),
    "Home & Kitchen": (15, 250),
    "Apparel": (10, 120),
    "Beauty": (8, 90),
    "Sports & Outdoors": (12, 300),
    "Books": (5, 40),
}

PRODUCT_NAME_PARTS = {
    "Electronics": ["Wireless Earbuds", "Bluetooth Speaker", "Smartwatch", "Laptop Stand", "USB-C Hub", "Webcam", "Power Bank"],
    "Home & Kitchen": ["Air Fryer", "Coffee Maker", "Blender", "Knife Set", "Throw Blanket", "Storage Bins", "Cookware Set"],
    "Apparel": ["Running Shorts", "Denim Jacket", "Wool Sweater", "Graphic Tee", "Yoga Pants", "Rain Jacket"],
    "Beauty": ["Face Serum", "Hair Dryer", "Makeup Brush Set", "Moisturizer", "Shampoo Bar"],
    "Sports & Outdoors": ["Yoga Mat", "Camping Tent", "Resistance Bands", "Hiking Backpack", "Water Bottle"],
    "Books": ["Mystery Novel", "Cookbook", "Self-Help Guide", "Business Strategy Book", "Sci-Fi Novel"],
}


def months_between(d1, d2):
    return (d2.year - d1.year) * 12 + (d2.month - d1.month)


def random_day_in_month(year, month):
    if month == 12:
        next_month = date(year + 1, 1, 1)
    else:
        next_month = date(year, month + 1, 1)
    days_in_month = (next_month - date(year, month, 1)).days
    return date(year, month, random.randint(1, days_in_month))


def pick_value_tier():
    r = random.random()
    cum = 0
    for tier, cfg in VALUE_TIERS.items():
        cum += cfg["weight"]
        if r <= cum:
            return tier
    return "low"


def build_schema(cur):
    cur.executescript(
        """
        DROP TABLE IF EXISTS order_items;
        DROP TABLE IF EXISTS orders;
        DROP TABLE IF EXISTS customers;
        DROP TABLE IF EXISTS products;

        CREATE TABLE customers (
            customer_id INTEGER PRIMARY KEY,
            signup_date TEXT NOT NULL,
            region TEXT NOT NULL,
            acquisition_channel TEXT NOT NULL,
            value_tier TEXT NOT NULL
        );

        CREATE TABLE products (
            product_id INTEGER PRIMARY KEY,
            product_name TEXT NOT NULL,
            category TEXT NOT NULL,
            unit_price REAL NOT NULL
        );

        CREATE TABLE orders (
            order_id INTEGER PRIMARY KEY,
            customer_id INTEGER NOT NULL,
            order_date TEXT NOT NULL,
            FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        );

        CREATE TABLE order_items (
            order_item_id INTEGER PRIMARY KEY,
            order_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price REAL NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders(order_id),
            FOREIGN KEY (product_id) REFERENCES products(product_id)
        );
        """
    )


def generate_products(cur):
    products = []
    pid = 1
    for category, (lo, hi) in CATEGORIES.items():
        for name in PRODUCT_NAME_PARTS[category]:
            price = round(random.uniform(lo, hi), 2)
            products.append((pid, name, category, price))
            pid += 1
    cur.executemany(
        "INSERT INTO products (product_id, product_name, category, unit_price) VALUES (?, ?, ?, ?)",
        products,
    )
    return products


def generate_customers(cur):
    customers = []
    total_months = months_between(START_DATE, SNAPSHOT_DATE)
    for cid in range(1, N_CUSTOMERS + 1):
        signup_month_offset = random.randint(0, total_months - 1)
        year = START_DATE.year + (START_DATE.month - 1 + signup_month_offset) // 12
        month = (START_DATE.month - 1 + signup_month_offset) % 12 + 1
        signup_date = random_day_in_month(year, month)
        region = random.choice(REGIONS)
        channel = random.choice(list(CHANNELS.keys()))
        value_tier = pick_value_tier()
        customers.append((cid, signup_date.isoformat(), region, channel, value_tier))
    cur.executemany(
        "INSERT INTO customers (customer_id, signup_date, region, acquisition_channel, value_tier) VALUES (?, ?, ?, ?, ?)",
        customers,
    )
    return customers


def generate_orders_and_items(cur, customers, products):
    order_id = 1
    order_item_id = 1
    orders_rows = []
    items_rows = []

    products_by_category = {}
    for p in products:
        products_by_category.setdefault(p[2], []).append(p)

    for (cid, signup_date_str, region, channel, value_tier) in customers:
        signup_date = date.fromisoformat(signup_date_str)
        channel_mult = CHANNELS[channel]
        tier_cfg = VALUE_TIERS[value_tier]

        months_active = months_between(signup_date, SNAPSHOT_DATE)
        base_monthly_retention = 0.78

        for t in range(0, months_active + 1):
            retention_prob = min(1.0, (base_monthly_retention ** t) * channel_mult)
            if t == 0:
                retention_prob = max(retention_prob, 0.9)  # signup month: near-certain first order

            if random.random() > retention_prob:
                continue

            year = signup_date.year + (signup_date.month - 1 + t) // 12
            month = (signup_date.month - 1 + t) % 12 + 1

            seasonal_lift = 1.0
            if month in (11, 12):
                seasonal_lift = 1.4

            n_orders_this_month = 1
            if random.random() < 0.25 * tier_cfg["order_mult"] * seasonal_lift:
                n_orders_this_month = 2

            for _ in range(n_orders_this_month):
                order_date = random_day_in_month(year, month)
                if order_date > SNAPSHOT_DATE:
                    continue
                orders_rows.append((order_id, cid, order_date.isoformat()))

                n_items = random.randint(1, 4)
                chosen_categories = random.sample(list(products_by_category.keys()), k=min(n_items, len(products_by_category)))
                for cat in chosen_categories:
                    product = random.choice(products_by_category[cat])
                    qty = random.randint(1, 3)
                    unit_price = round(product[3] * tier_cfg["basket_mult"] * random.uniform(0.9, 1.1), 2)
                    items_rows.append((order_item_id, order_id, product[0], qty, unit_price))
                    order_item_id += 1

                order_id += 1

    cur.executemany("INSERT INTO orders (order_id, customer_id, order_date) VALUES (?, ?, ?)", orders_rows)
    cur.executemany(
        "INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?, ?)",
        items_rows,
    )
    return len(orders_rows), len(items_rows)


def main():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    build_schema(cur)
    products = generate_products(cur)
    customers = generate_customers(cur)
    n_orders, n_items = generate_orders_and_items(cur, customers, products)
    conn.commit()
    print(f"Generated {len(customers)} customers, {len(products)} products, {n_orders} orders, {n_items} order_items")
    conn.close()


if __name__ == "__main__":
    main()
