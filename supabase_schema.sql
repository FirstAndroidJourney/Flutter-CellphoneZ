    -- Supabase Database Schema for E-commerce App
    -- Run these commands in Supabase SQL Editor

    -- Enable UUID extension
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

    -- Enable Row Level Security
    ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

    -- User Profiles Table
    CREATE TABLE user_profiles (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        email TEXT UNIQUE NOT NULL,
        name TEXT,
        avatar_url TEXT,
        phone TEXT,
        address TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Categories Table
    CREATE TABLE categories (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name TEXT NOT NULL,
        parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Products Table
    CREATE TABLE products (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        name TEXT NOT NULL,
        price DECIMAL(10,2) NOT NULL,
        description TEXT,
        image_url TEXT,
        category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
        is_available BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Cart Items Table
    CREATE TABLE cart_items (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
        product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        UNIQUE(user_id, product_id)
    );

    -- Orders Table  
    CREATE TABLE orders (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
        total_price DECIMAL(10,2) NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'shipping', 'completed', 'cancelled')),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Order Items Table
    CREATE TABLE order_items (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        price DECIMAL(10,2) NOT NULL, -- Store price at time of order
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Indexes for better performance
    CREATE INDEX idx_products_category ON products(category_id);
    CREATE INDEX idx_products_available ON products(is_available);
    CREATE INDEX idx_cart_items_user ON cart_items(user_id);
    CREATE INDEX idx_orders_user ON orders(user_id);
    CREATE INDEX idx_orders_status ON orders(status);
    CREATE INDEX idx_order_items_order ON order_items(order_id);

    -- Row Level Security Policies

    -- User Profiles
    ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
    CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);
    CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);

    -- Categories (Public read access)
    ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Anyone can view categories" ON categories FOR SELECT TO public USING (true);

    -- Products (Public read access)
    ALTER TABLE products ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Anyone can view available products" ON products FOR SELECT TO public USING (is_available = true);

    -- Cart Items
    ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Users can view own cart items" ON cart_items FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can insert own cart items" ON cart_items FOR INSERT WITH CHECK (auth.uid() = user_id);
    CREATE POLICY "Users can update own cart items" ON cart_items FOR UPDATE USING (auth.uid() = user_id);
    CREATE POLICY "Users can delete own cart items" ON cart_items FOR DELETE USING (auth.uid() = user_id);

    -- Orders
    ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Users can view own orders" ON orders FOR SELECT USING (auth.uid() = user_id);
    CREATE POLICY "Users can insert own orders" ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);

    -- Order Items
    ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Users can view own order items" ON order_items FOR SELECT USING (
        auth.uid() IN (SELECT user_id FROM orders WHERE orders.id = order_items.order_id)
    );
    CREATE POLICY "Users can insert own order items" ON order_items FOR INSERT WITH CHECK (
        auth.uid() IN (SELECT user_id FROM orders WHERE orders.id = order_items.order_id)
    );

    -- Functions for updated_at timestamp
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ language 'plpgsql';

    -- Triggers for updated_at
    CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    CREATE TRIGGER update_cart_items_updated_at BEFORE UPDATE ON cart_items
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    -- Sample data (optional)
    INSERT INTO categories (name) VALUES 
        ('Electronics'),
        ('Clothing'),
        ('Books'),
        ('Home & Garden');

    INSERT INTO categories (name, parent_id) VALUES 
        ('Smartphones', (SELECT id FROM categories WHERE name = 'Electronics')),
        ('Laptops', (SELECT id FROM categories WHERE name = 'Electronics')),
        ('Men''s Clothing', (SELECT id FROM categories WHERE name = 'Clothing')),
        ('Women''s Clothing', (SELECT id FROM categories WHERE name = 'Clothing'));

    -- You can add sample products here as well
    INSERT INTO products (name, price, description, category_id, image_url) VALUES 
        ('iPhone 15', 999.99, 'Latest iPhone with advanced features', 
        (SELECT id FROM categories WHERE name = 'Smartphones'), 
        'https://example.com/iphone15.jpg'),
        ('MacBook Pro', 1999.99, 'Powerful laptop for professionals', 
        (SELECT id FROM categories WHERE name = 'Laptops'), 
        'https://example.com/macbook.jpg');