-- ============================================================
-- AgriRent – Complete Supabase PostgreSQL Schema
-- Run this entire file in Supabase → SQL Editor → New Query
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ──────────────────────────────────────────────────────────────
-- TABLES
-- ──────────────────────────────────────────────────────────────

-- USERS
CREATE TABLE IF NOT EXISTS public.users (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id           UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name         VARCHAR(255) NOT NULL,
  email             VARCHAR(255) UNIQUE NOT NULL,
  phone             VARCHAR(20),
  role              VARCHAR(20) NOT NULL CHECK (role IN ('farmer','owner','admin')),
  profile_image_url TEXT,
  address           TEXT,
  city              VARCHAR(100),
  state             VARCHAR(100),
  pincode           VARCHAR(10),
  aadhar_number     VARCHAR(20),
  is_verified       BOOLEAN DEFAULT false,
  is_active         BOOLEAN DEFAULT true,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

-- VEHICLES
CREATE TABLE IF NOT EXISTS public.vehicles (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title            VARCHAR(255) NOT NULL,
  description      TEXT,
  vehicle_type     VARCHAR(100) NOT NULL,
  brand            VARCHAR(100),
  model            VARCHAR(100),
  year             INTEGER,
  price_per_hour   DECIMAL(10,2) NOT NULL DEFAULT 0,
  price_per_day    DECIMAL(10,2) NOT NULL DEFAULT 0,
  location         VARCHAR(255),
  city             VARCHAR(100),
  state            VARCHAR(100),
  latitude         DECIMAL(10,8),
  longitude        DECIMAL(11,8),
  image_urls       TEXT[]  DEFAULT '{}',
  features         TEXT[]  DEFAULT '{}',
  is_available     BOOLEAN DEFAULT true,
  is_approved      BOOLEAN DEFAULT false,
  fuel_type        VARCHAR(50),
  horsepower       INTEGER,
  capacity         VARCHAR(100),
  total_bookings   INTEGER DEFAULT 0,
  average_rating   DECIMAL(3,2) DEFAULT 0.0,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- BOOKINGS
CREATE TABLE IF NOT EXISTS public.bookings (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id          UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  farmer_id           UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  owner_id            UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  start_date          TIMESTAMPTZ NOT NULL,
  end_date            TIMESTAMPTZ NOT NULL,
  total_hours         DECIMAL(8,2),
  total_days          DECIMAL(8,2),
  price_per_day       DECIMAL(10,2) NOT NULL,
  subtotal            DECIMAL(10,2) NOT NULL,
  tax_amount          DECIMAL(10,2) DEFAULT 0,
  total_amount        DECIMAL(10,2) NOT NULL,
  status              VARCHAR(50)   DEFAULT 'pending'
                      CHECK (status IN ('pending','confirmed','active','completed','cancelled','rejected')),
  payment_status      VARCHAR(50)   DEFAULT 'unpaid'
                      CHECK (payment_status IN ('unpaid','paid','refunded')),
  booking_notes       TEXT,
  cancellation_reason TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- REVIEWS
CREATE TABLE IF NOT EXISTS public.reviews (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id  UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  vehicle_id  UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  farmer_id   UUID NOT NULL REFERENCES public.users(id)   ON DELETE CASCADE,
  rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  owner_reply TEXT,
  is_visible  BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(booking_id)
);

-- PAYMENTS
CREATE TABLE IF NOT EXISTS public.payments (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id       UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  farmer_id        UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  owner_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount           DECIMAL(10,2) NOT NULL,
  payment_method   VARCHAR(50),
  transaction_id   VARCHAR(255),
  payment_gateway  VARCHAR(50),
  status           VARCHAR(50) DEFAULT 'pending'
                   CHECK (status IN ('pending','success','failed','refunded')),
  payment_date     TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.notifications (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title      VARCHAR(255) NOT NULL,
  message    TEXT NOT NULL,
  type       VARCHAR(50),
  is_read    BOOLEAN DEFAULT false,
  related_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────
-- INDEXES
-- ──────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_vehicles_owner     ON public.vehicles(owner_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_city      ON public.vehicles(city);
CREATE INDEX IF NOT EXISTS idx_vehicles_approved  ON public.vehicles(is_approved);
CREATE INDEX IF NOT EXISTS idx_vehicles_available ON public.vehicles(is_available);
CREATE INDEX IF NOT EXISTS idx_bookings_farmer    ON public.bookings(farmer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_owner     ON public.bookings(owner_id);
CREATE INDEX IF NOT EXISTS idx_bookings_vehicle   ON public.bookings(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status    ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_reviews_vehicle    ON public.reviews(vehicle_id);

-- ──────────────────────────────────────────────────────────────
-- AUTO-UPDATE updated_at TRIGGER
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_vehicles_updated_at
  BEFORE UPDATE ON public.vehicles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ──────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ──────────────────────────────────────────────────────────────
ALTER TABLE public.users         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users: can see and edit their own row
CREATE POLICY "user_select_own"  ON public.users FOR SELECT USING (auth.uid() = auth_id);
CREATE POLICY "user_insert_own"  ON public.users FOR INSERT WITH CHECK (auth.uid() = auth_id);
CREATE POLICY "user_update_own"  ON public.users FOR UPDATE USING (auth.uid() = auth_id);

-- Vehicles: anyone can read approved; owner can CRUD their own
CREATE POLICY "vehicle_public_read" ON public.vehicles FOR SELECT
  USING (is_approved = true OR owner_id IN (
    SELECT id FROM public.users WHERE auth_id = auth.uid()));

CREATE POLICY "vehicle_owner_insert" ON public.vehicles FOR INSERT
  WITH CHECK (owner_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

CREATE POLICY "vehicle_owner_update" ON public.vehicles FOR UPDATE
  USING (owner_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

CREATE POLICY "vehicle_owner_delete" ON public.vehicles FOR DELETE
  USING (owner_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- Bookings: farmer or owner of the booking can read
CREATE POLICY "booking_parties_select" ON public.bookings FOR SELECT
  USING (
    farmer_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()) OR
    owner_id  IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

CREATE POLICY "booking_farmer_insert" ON public.bookings FOR INSERT
  WITH CHECK (farmer_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

CREATE POLICY "booking_parties_update" ON public.bookings FOR UPDATE
  USING (
    farmer_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()) OR
    owner_id  IN (SELECT id FROM public.users WHERE auth_id = auth.uid())
  );

-- Reviews: visible ones are public; only farmer can insert
CREATE POLICY "review_public_select" ON public.reviews FOR SELECT USING (is_visible = true);
CREATE POLICY "review_farmer_insert" ON public.reviews FOR INSERT
  WITH CHECK (farmer_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- Notifications: own only
CREATE POLICY "notif_own_select" ON public.notifications FOR SELECT
  USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

-- ──────────────────────────────────────────────────────────────
-- STORAGE BUCKETS
-- ──────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
  VALUES ('vehicle-images', 'vehicle-images', true)
  ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
  VALUES ('profile-images', 'profile-images', true)
  ON CONFLICT (id) DO NOTHING;

-- Allow public read & authenticated upload for vehicle images
CREATE POLICY "vehicle_img_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'vehicle-images');
CREATE POLICY "vehicle_img_auth_upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'vehicle-images' AND auth.role() = 'authenticated');

-- Allow public read & authenticated upload for profile images
CREATE POLICY "profile_img_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile-images');
CREATE POLICY "profile_img_auth_upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'profile-images' AND auth.role() = 'authenticated');

-- ──────────────────────────────────────────────────────────────
-- SEED / DEMO DATA (optional – run after creating auth users)
-- ──────────────────────────────────────────────────────────────
-- After registering demo accounts via the app, promote one to admin:
--
--   UPDATE public.users SET role = 'admin'
--   WHERE email = 'admin@agrirent.com';
--
-- Approve sample vehicles for testing:
--   UPDATE public.vehicles SET is_approved = true;
