-- ToyVerse Supabase PostgreSQL Database Schema
-- Production Ready Schema with Row Level Security (RLS) policies

-- Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS / PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    avatar_url TEXT,
    role TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'admin', 'delivery_partner')),
    reward_coins INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. CHILDREN TABLE (Personalization)
CREATE TABLE IF NOT EXISTS public.children (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    age INTEGER NOT NULL CHECK (age >= 0 AND age <= 18),
    gender TEXT CHECK (gender IN ('boy', 'girl', 'unspecified')),
    interests TEXT[], -- e.g. ['building', 'dinosaurs', 'space', 'art']
    favorite_character TEXT,
    learning_level TEXT DEFAULT 'beginner',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. BRANDS TABLE
CREATE TABLE IF NOT EXISTS public.brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    logo_url TEXT NOT NULL,
    description TEXT,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. CATEGORIES TABLE (Hierarchical with Parent-Child Structure)
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    icon_key TEXT NOT NULL,
    parent_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    color_hex TEXT DEFAULT '#1E3A8A',
    banner_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4.1 LISTINGS TABLE (Providers, Centers, Schools & Studios)
CREATE TABLE IF NOT EXISTS public.listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    primary_photo_url TEXT NOT NULL,
    gallery_urls TEXT[],
    rating NUMERIC(3, 2) DEFAULT 5.0,
    review_count INTEGER DEFAULT 0,
    address TEXT,
    city TEXT,
    distance_km NUMERIC(4, 1),
    price_range TEXT,
    is_verified BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    phone TEXT,
    whatsapp TEXT,
    operating_hours TEXT,
    age_group TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS public.products (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    title TEXT NOT NULL,
    subtitle TEXT,
    description TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    original_price NUMERIC(10, 2),
    discount_percentage INTEGER DEFAULT 0,
    rating NUMERIC(3, 2) DEFAULT 5.0,
    review_count INTEGER DEFAULT 0,
    stock_quantity INTEGER DEFAULT 50,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    brand_id UUID REFERENCES public.brands(id) ON DELETE SET NULL,
    min_age INTEGER DEFAULT 3,
    max_age INTEGER DEFAULT 12,
    material TEXT DEFAULT 'BPA-Free Plastic & Eco Wood',
    educational_type TEXT, -- STEM, Creative, Motor Skills, Cognitive
    is_trending BOOLEAN DEFAULT false,
    is_best_seller BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    is_limited_edition BOOLEAN DEFAULT false,
    ar_model_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. PRODUCT IMAGES TABLE
CREATE TABLE IF NOT EXISTS public.product_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id TEXT REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0
);

-- 7. ADDRESSES TABLE
CREATE TABLE IF NOT EXISTS public.addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    label TEXT, -- "Home", "Work", etc.
    full_address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 8. ORDERS TABLE (End-to-End Fulfillment Lifecycle)
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    address_id UUID REFERENCES public.addresses(id) ON DELETE SET NULL,
    items JSONB NOT NULL, -- [{product_id, qty, price, title, image_url}]
    subtotal NUMERIC NOT NULL,
    total NUMERIC NOT NULL,
    razorpay_payment_id TEXT,
    razorpay_order_id TEXT,
    status TEXT DEFAULT 'placed', -- 'placed' -> 'preparing' -> 'dispatched' -> 'out_for_delivery' -> 'delivered' (or 'cancelled')
    status_updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    status_history JSONB DEFAULT '{}'::jsonb, -- {"placed": "...", "preparing": "...", "dispatched": "...", "out_for_delivery": "...", "delivered": "..."}
    origin_location TEXT DEFAULT 'Guild Club Fulfillment Hub, Indiranagar, Bengaluru',
    origin_lat DOUBLE PRECISION DEFAULT 12.9716,
    origin_lng DOUBLE PRECISION DEFAULT 77.5946,
    delivery_address_text TEXT,
    destination_lat DOUBLE PRECISION,
    destination_lng DOUBLE PRECISION,
    eta_minutes INTEGER DEFAULT 35,
    delivery_partner_name TEXT DEFAULT 'Alex (Guild Club Logistics)',
    delivery_partner_phone TEXT DEFAULT '+91 98765 43210',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. WISHLIST TABLE
CREATE TABLE IF NOT EXISTS public.wishlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, product_id)
);

-- 12. CART TABLE
CREATE TABLE IF NOT EXISTS public.cart (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    product_id TEXT REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, product_id)
);

-- 13. REVIEWS & RATINGS TABLE
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id TEXT REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 14. COUPONS TABLE
CREATE TABLE IF NOT EXISTS public.coupons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    discount_amount NUMERIC(10, 2) NOT NULL,
    min_order_value NUMERIC(10, 2) DEFAULT 0,
    valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- 15. REWARD POINTS / HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.reward_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    points_earned INTEGER NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 16. DELIVERY TRACKING TABLE
CREATE TABLE IF NOT EXISTS public.delivery_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    partner_name TEXT DEFAULT 'ToyVerse Express',
    partner_phone TEXT DEFAULT '+91 98765 43210',
    current_lat NUMERIC(10, 7),
    current_lng NUMERIC(10, 7),
    eta_minutes INTEGER DEFAULT 25,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 17. BANNERS TABLE
CREATE TABLE IF NOT EXISTS public.banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    subtitle TEXT,
    image_url TEXT NOT NULL,
    cta_text TEXT DEFAULT 'Shop Now',
    target_category_slug TEXT,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0
);

-- ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.children ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by owner" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can manage own children" ON public.children FOR ALL USING (auth.uid() = parent_id);
-- Explicit Orders Scoping Policies
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own orders" ON public.orders FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage own wishlist" ON public.wishlist FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own cart" ON public.cart FOR ALL USING (auth.uid() = user_id);

-- Explicit Addresses Scoping Policies
CREATE POLICY "Users can view own addresses" ON public.addresses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own addresses" ON public.addresses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own addresses" ON public.addresses FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own addresses" ON public.addresses FOR DELETE USING (auth.uid() = user_id);

-- =================================================================
-- GUILD CLUB COIN & REWARDS ENGINE SCHEMA
-- =================================================================

-- 18. DEDICATED WALLETS TABLE (Single Source of Truth for Balance)
CREATE TABLE IF NOT EXISTS public.wallets (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    coin_balance INTEGER DEFAULT 0 CHECK (coin_balance >= 0),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 19. REWARD TRANSACTIONS LEDGER (Immutable Ledger)
CREATE TABLE IF NOT EXISTS public.reward_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('daily_spin', 'daily_login_bonus', 'redemption', 'order_cashback', 'streak_bonus')),
    amount INTEGER NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 20. DAILY ACTIVITY TRACKER (Rate Limits & One-Spin-Per-Day Enforcement)
CREATE TABLE IF NOT EXISTS public.daily_activity (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    activity_date DATE DEFAULT CURRENT_DATE NOT NULL,
    spun_today BOOLEAN DEFAULT false NOT NULL,
    login_bonus_claimed_today BOOLEAN DEFAULT false NOT NULL,
    PRIMARY KEY (user_id, activity_date)
);

-- AUTOMATIC BALANCE CONSISTENCY TRIGGER
-- Recalculates and updates wallets.coin_balance whenever a transaction is inserted into reward_transactions
CREATE OR REPLACE FUNCTION public.update_wallet_balance_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.wallets (user_id, coin_balance, updated_at)
    VALUES (NEW.user_id, NEW.amount, NOW())
    ON CONFLICT (user_id) DO UPDATE
    SET coin_balance = public.wallets.coin_balance + NEW.amount,
        updated_at = NOW();

    -- Reject negative balance resulting from invalid redemptions
    IF (SELECT coin_balance FROM public.wallets WHERE user_id = NEW.user_id) < 0 THEN
        RAISE EXCEPTION 'Transaction rejected: Insufficient coin balance for user %', NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_wallet_balance ON public.reward_transactions;
CREATE TRIGGER trigger_update_wallet_balance
AFTER INSERT ON public.reward_transactions
FOR EACH ROW
EXECUTE FUNCTION public.update_wallet_balance_on_transaction();

-- REWARDS SYSTEM RLS POLICIES (STRICT READ-ONLY FOR CLIENTS)
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_activity ENABLE ROW LEVEL SECURITY;

-- Clients can only SELECT their own rows. No INSERT/UPDATE/DELETE policies are granted to clients.
-- Writes are strictly restricted to Edge Functions running with service_role privileges.
CREATE POLICY "Users can view own wallet balance"
ON public.wallets FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can view own reward transactions"
ON public.reward_transactions FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can view own daily activity status"
ON public.daily_activity FOR SELECT
USING (auth.uid() = user_id);

-- =================================================================
-- CATEGORIES & LISTINGS RLS POLICIES & SEED DATA
-- =================================================================

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
CREATE POLICY "Categories are viewable by everyone"
ON public.categories FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Active listings are viewable by everyone" ON public.listings;
CREATE POLICY "Active listings are viewable by everyone"
ON public.listings FOR SELECT
USING (is_active = true);

-- TOP-LEVEL CATEGORIES SEED DATA (Explicit Heraldic Crest Palette Rotation)
INSERT INTO public.categories (id, name, slug, icon_key, parent_id, sort_order, color_hex, is_active)
VALUES
    ('c1000000-0000-0000-0000-000000000001', 'Play Schools', 'play-schools', 'play_schools', NULL, 1, '#1E3A8A', true),
    ('c1000000-0000-0000-0000-000000000002', 'Child Development Centers', 'child-development-centers', 'child_development', NULL, 2, '#B91C1C', true),
    ('c1000000-0000-0000-0000-000000000003', 'Schools', 'schools', 'schools', NULL, 3, '#0F172A', true),
    ('c1000000-0000-0000-0000-000000000004', 'Interior Designing', 'interior-designing', 'interior_designing', NULL, 4, '#FFFFFF', true)
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    icon_key = EXCLUDED.icon_key,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    color_hex = EXCLUDED.color_hex,
    is_active = EXCLUDED.is_active;

-- SUBCATEGORIES SEED DATA (Under Child Development Centers - Explicit Heraldic Color Rotation)
INSERT INTO public.categories (id, name, slug, icon_key, parent_id, sort_order, color_hex, is_active)
VALUES
    ('c2000000-0000-0000-0000-000000000001', 'Speech Therapy', 'speech-therapy', 'speech_therapy', 'c1000000-0000-0000-0000-000000000002', 1, '#1E3A8A', true),
    ('c2000000-0000-0000-0000-000000000002', 'Occupational Therapy', 'occupational-therapy', 'occupational_therapy', 'c1000000-0000-0000-0000-000000000002', 2, '#B91C1C', true),
    ('c2000000-0000-0000-0000-000000000003', 'Behavioural Therapy', 'behavioural-therapy', 'behavioural_therapy', 'c1000000-0000-0000-0000-000000000002', 3, '#0F172A', true),
    ('c2000000-0000-0000-0000-000000000004', 'Special Education', 'special-education', 'special_education', 'c1000000-0000-0000-0000-000000000002', 4, '#FFFFFF', true)
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    icon_key = EXCLUDED.icon_key,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    color_hex = EXCLUDED.color_hex,
    is_active = EXCLUDED.is_active;

-- SAMPLE LISTINGS SEED DATA
INSERT INTO public.listings (id, category_id, name, description, primary_photo_url, gallery_urls, rating, review_count, address, city, distance_km, price_range, is_verified, is_active, phone, whatsapp, operating_hours, age_group)
VALUES
    -- Play Schools
    ('l1000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'Little Explorers Early Learning Academy', 'Holistic Montessori play school offering experiential play, nature immersion, and cognitive sensory zones tailored for toddlers.', 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop', 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?q=80&w=800&auto=format&fit=crop'], 4.9, 148, '14th Main Road, Indiranagar', 'Bengaluru', 1.8, '₹8,000 - ₹15,000 / month', true, true, '+91 98450 12345', '+91 98450 12345', '8:30 AM - 1:30 PM (Mon-Fri)', '1.5 - 5.5 Years'),
    ('l1000000-0000-0000-0000-000000000002', 'c1000000-0000-0000-0000-000000000001', 'Blooms Play & Discovery Haven', 'Play-based preschool curriculum with low teacher-to-student ratios, organic nutrition meals, and indoor sensory gym.', 'https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=800&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=800&auto=format&fit=crop'], 4.8, 92, '5th Block, Koramangala', 'Bengaluru', 3.2, '₹10,000 - ₹18,000 / month', true, true, '+91 99801 54321', '+91 99801 54321', '9:00 AM - 2:00 PM (Mon-Fri)', '2 - 6 Years'),

    -- Schools
    ('l1000000-0000-0000-0000-000000000003', 'c1000000-0000-0000-0000-000000000003', 'The Cambridge International Academy', 'Premier ICSE & IGCSE affiliated institution emphasizing holistic development, robotics laboratories, and sports excellence.', 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?q=80&w=800&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1580582932707-520aed937b7b?q=80&w=800&auto=format&fit=crop'], 4.9, 310, 'Sarjapur Main Road', 'Bengaluru', 5.4, '₹1.5L - ₹2.8L / year', true, true, '+91 80 4123 7890', '+91 98450 67890', '8:00 AM - 3:30 PM (Mon-Fri)', 'Grade 1 - 12'),

    -- Interior Designing
    ('l1000000-0000-0000-0000-000000000004', 'c1000000-0000-0000-0000-000000000004', 'Studio Nestling Kids Interiors', 'Bespoke, child-safe interior design studio specializing in themed kids bedrooms, study nooks, and montessori playroom spaces.', 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=800&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=800&auto=format&fit=crop'], 4.9, 78, '100ft Road, Defence Colony', 'Bengaluru', 2.1, 'Custom Quote / Consultation', true, true, '+91 98860 99887', '+91 98860 99887', '10:00 AM - 7:00 PM (Mon-Sat)', 'All Ages'),

    -- Speech Therapy (Child Development Subcategory)
    ('l2000000-0000-0000-0000-000000000001', 'c2000000-0000-0000-0000-000000000001', 'SoundSteps Pediatric Speech Therapy', 'Certified pediatric speech-language pathologists assisting children with speech delays, articulation, fluency, and AAC systems.', 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?q=80&w=800&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?q=80&w=800&auto=format&fit=crop'], 5.0, 116, 'HSR Layout Sector 2', 'Bengaluru', 2.9, '₹1,200 - ₹2,000 / session', true, true, '+91 97410 44556', '+91 97410 44556', '9:00 AM - 6:00 PM (Mon-Sat)', '1.5 - 14 Years'),

    -- Occupational Therapy (Child Development Subcategory)
    ('l2000000-0000-0000-0000-000000000002', 'c2000000-0000-0000-0000-000000000002', 'SensoryRise Occupational Therapy Hub', 'Comprehensive sensory integration therapy, fine motor skill enhancement, and developmental coordination rehabilitation.', 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?q=80&w=800&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?q=80&w=800&auto=format&fit=crop'], 4.9, 94, 'Jayanagar 4th Block', 'Bengaluru', 4.1, '₹1,500 - ₹2,200 / session', true, true, '+91 99002 33445', '+91 99002 33445', '8:30 AM - 6:30 PM (Mon-Sat)', '2 - 16 Years'),

    -- Behavioural Therapy (Child Development Subcategory)
    ('l2000000-0000-0000-0000-000000000003', 'c2000000-0000-0000-0000-000000000003', 'MindSpring Child Behavioural Clinic', 'Evidence-based ABA therapy, emotional regulation coaching, and social skills peer groups with licensed child psychologists.', 'https://images.unsplash.com/photo-1516627145497-ae6968895b74?q=80&w=800&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1516627145497-ae6968895b74?q=80&w=800&auto=format&fit=crop'], 4.8, 83, 'Kalyan Nagar', 'Bengaluru', 6.0, '₹1,800 - ₹2,500 / session', true, true, '+91 98452 77889', '+91 98452 77889', '9:30 AM - 5:30 PM (Mon-Fri)', '3 - 15 Years'),

    -- Special Education (Child Development Subcategory)
    ('l2000000-0000-0000-0000-000000000004', 'c2000000-0000-0000-0000-000000000004', 'BrightBridge Inclusive Learning Center', 'Individualized Education Programs (IEP), remedial learning, dyslexic support, and adaptive academic coaching.', 'https://images.unsplash.com/photo-1509062522246-3755977927d7?q=80&w=800&auto=format&fit=crop', ARRAY['https://images.unsplash.com/photo-1509062522246-3755977927d7?q=80&w=800&auto=format&fit=crop'], 4.9, 105, 'BTM Layout 2nd Stage', 'Bengaluru', 3.7, '₹1,000 - ₹1,800 / session', true, true, '+91 97312 88990', '+91 97312 88990', '9:00 AM - 5:00 PM (Mon-Sat)', '4 - 18 Years')
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    category_id = EXCLUDED.category_id,
    description = EXCLUDED.description,
    primary_photo_url = EXCLUDED.primary_photo_url,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    address = EXCLUDED.address,
    city = EXCLUDED.city,
    distance_km = EXCLUDED.distance_km,
    price_range = EXCLUDED.price_range,
    is_verified = EXCLUDED.is_verified,
    phone = EXCLUDED.phone,
    whatsapp = EXCLUDED.whatsapp,
    operating_hours = EXCLUDED.operating_hours,
    age_group = EXCLUDED.age_group;


