-- ============================================================
-- Propify – Supabase Schema
-- Run this in the Supabase SQL Editor to set up all tables,
-- RLS policies and the trigger that auto-creates profiles.
-- ============================================================

-- -------------------------
-- Enable UUID extension (provides gen_random_uuid() used for primary keys)
-- -------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -------------------------
-- profiles
-- -------------------------
CREATE TABLE IF NOT EXISTS profiles (
    id   uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email text UNIQUE NOT NULL,
    role  text NOT NULL DEFAULT 'tenant' CHECK (role IN ('owner', 'tenant'))
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile; owner can read all
CREATE POLICY "profiles: own read" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles: owner read all" ON profiles
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'owner')
    );

-- Auto-create a profile on first sign-in (role defaults to 'tenant')
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (NEW.id, NEW.email, 'tenant')
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Allow owner to update any profile (e.g., to change roles)
CREATE POLICY "profiles: owner update all" ON profiles
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'owner')
    );

-- -------------------------
-- tenants
-- -------------------------
CREATE TABLE IF NOT EXISTS tenants (
    id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name       text NOT NULL,
    phone      text,
    payday     int,
    rent       numeric NOT NULL,
    start_date date NOT NULL,
    end_date   date,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- Owner: full access; Tenant: read-only
CREATE POLICY "tenants: owner all" ON tenants
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'owner')
    );

CREATE POLICY "tenants: tenant read" ON tenants
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- -------------------------
-- payments  (arriendo)
-- -------------------------
CREATE TABLE IF NOT EXISTS payments (
    id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id    uuid REFERENCES tenants(id) ON DELETE CASCADE,
    concept      text,
    amount       numeric NOT NULL,
    month        text NOT NULL,          -- YYYY-MM
    receipt_url  text,
    receipt_type text,                  -- 'image' | 'pdf'
    created_at   timestamptz DEFAULT now()
);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payments: owner all" ON payments
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'owner')
    );

CREATE POLICY "payments: tenant read" ON payments
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- -------------------------
-- admin_fees
-- -------------------------
CREATE TABLE IF NOT EXISTS admin_fees (
    id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    month      text NOT NULL UNIQUE,    -- YYYY-MM
    amount     numeric NOT NULL DEFAULT 204800,
    status     text NOT NULL DEFAULT 'Pendiente' CHECK (status IN ('Pagado', 'Pendiente')),
    created_at timestamptz DEFAULT now()
);

ALTER TABLE admin_fees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_fees: owner all" ON admin_fees
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'owner')
    );

CREATE POLICY "admin_fees: tenant read" ON admin_fees
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- -------------------------
-- utility_accounts
-- -------------------------
CREATE TABLE IF NOT EXISTS utility_accounts (
    id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    type            text NOT NULL,      -- Afinia, Surtigas, Aguas de Cartagena
    contract        text NOT NULL,
    due_date        text,
    last_paid_month text
);

ALTER TABLE utility_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "utility_accounts: owner all" ON utility_accounts
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'owner')
    );

CREATE POLICY "utility_accounts: tenant read" ON utility_accounts
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- -------------------------
-- service_readings
-- -------------------------
CREATE TABLE IF NOT EXISTS service_readings (
    id             uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id      uuid REFERENCES tenants(id) ON DELETE CASCADE,
    type           text NOT NULL,      -- Luz | Agua | Gas
    meter_reading  numeric NOT NULL,
    date           date DEFAULT CURRENT_DATE,
    created_at     timestamptz DEFAULT now()
);

ALTER TABLE service_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_readings: owner all" ON service_readings
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'owner')
    );

CREATE POLICY "service_readings: tenant read" ON service_readings
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- -------------------------
-- service_payments
-- -------------------------
CREATE TABLE IF NOT EXISTS service_payments (
    id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id    uuid REFERENCES tenants(id) ON DELETE CASCADE,
    type         text NOT NULL,         -- Luz | Agua | Gas
    amount       numeric NOT NULL,
    month        text NOT NULL,         -- YYYY-MM
    support_url  text,
    support_type text,                  -- 'image' | 'pdf'
    date         date DEFAULT CURRENT_DATE,
    created_at   timestamptz DEFAULT now()
);

ALTER TABLE service_payments ENABLE ROW LEVEL SECURITY;

-- Owner: full access
CREATE POLICY "service_payments: owner all" ON service_payments
    FOR ALL USING (
        EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'owner')
    );

-- Tenant: can insert and read all service payments
CREATE POLICY "service_payments: tenant read" ON service_payments
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "service_payments: tenant insert" ON service_payments
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- -------------------------
-- Storage bucket policy (run after creating the 'supports' bucket)
-- -------------------------
-- INSERT INTO storage.buckets (id, name, public) VALUES ('supports', 'supports', true)
-- ON CONFLICT (id) DO NOTHING;

CREATE POLICY "supports: public read" ON storage.objects
    FOR SELECT USING (bucket_id = 'supports');

CREATE POLICY "supports: authenticated upload" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'supports' AND auth.uid() IS NOT NULL);
