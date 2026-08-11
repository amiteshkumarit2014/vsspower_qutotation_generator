-- ============================================================
-- VSS Power Quotation Generator — Supabase Schema
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. COMPANY SETTINGS
-- ============================================================
CREATE TABLE IF NOT EXISTS company_settings (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name          TEXT,
  address               TEXT,
  city                  TEXT,
  country               TEXT,
  postcode              TEXT,
  phone                 TEXT,
  email                 TEXT,
  website               TEXT,
  vat_number            TEXT,
  logo_url              TEXT,
  bank_details          TEXT,
  footer_text           TEXT,
  default_currency      TEXT DEFAULT 'GBP',
  default_validity_days INTEGER DEFAULT 30,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- 2. CUSTOMERS
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name   TEXT NOT NULL,
  contact_person TEXT,
  email          TEXT,
  phone          TEXT,
  address        TEXT,
  city           TEXT,
  country        TEXT,
  postcode       TEXT,
  created_at     TIMESTAMPTZ DEFAULT now(),
  updated_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customers_company_name ON customers (lower(company_name));

-- ============================================================
-- 3. QUOTATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS quotations (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_number     TEXT UNIQUE NOT NULL,
  customer_id          UUID REFERENCES customers(id) ON DELETE SET NULL,
  quotation_date       DATE,
  valid_until          DATE,
  status               TEXT DEFAULT 'Draft' CHECK (status IN ('Draft','Under Review','Sent','Accepted','Rejected','Expired')),
  currency             TEXT DEFAULT 'GBP',
  subtotal             NUMERIC(12,2) DEFAULT 0,
  vat_percentage       NUMERIC(5,2) DEFAULT 0,
  vat_amount           NUMERIC(12,2) DEFAULT 0,
  total_amount         NUMERIC(12,2) DEFAULT 0,
  notes                TEXT,
  terms_and_conditions TEXT,
  -- Full quotation JSON payload (stores all wizard data for PDF/edit)
  payload              TEXT,
  created_at           TIMESTAMPTZ DEFAULT now(),
  updated_at           TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_quotations_customer_id   ON quotations (customer_id);
CREATE INDEX IF NOT EXISTS idx_quotations_status        ON quotations (status);
CREATE INDEX IF NOT EXISTS idx_quotations_quotation_date ON quotations (quotation_date);

-- ============================================================
-- 4. QUOTATION ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS quotation_items (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id   UUID REFERENCES quotations(id) ON DELETE CASCADE,
  description    TEXT NOT NULL,
  quantity       NUMERIC(12,2) DEFAULT 1,
  unit_price     NUMERIC(12,2) DEFAULT 0,
  total_price    NUMERIC(12,2) DEFAULT 0,
  sort_order     INTEGER DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_quotation_items_quotation_id ON quotation_items (quotation_id);

-- ============================================================
-- 5. UPDATED_AT TRIGGER (auto-update timestamps)
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_customers_updated_at ON customers;
CREATE TRIGGER trg_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_quotations_updated_at ON quotations;
CREATE TRIGGER trg_quotations_updated_at
  BEFORE UPDATE ON quotations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_company_settings_updated_at ON company_settings;
CREATE TRIGGER trg_company_settings_updated_at
  BEFORE UPDATE ON company_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE company_settings  ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotations         ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotation_items    ENABLE ROW LEVEL SECURITY;

-- Authenticated users can do everything on all tables
-- (single-org app — all logged-in users share the same data)

-- company_settings
CREATE POLICY "auth_read_company_settings"   ON company_settings FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "auth_insert_company_settings" ON company_settings FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "auth_update_company_settings" ON company_settings FOR UPDATE USING (auth.role() = 'authenticated');

-- customers
CREATE POLICY "auth_read_customers"   ON customers FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "auth_insert_customers" ON customers FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "auth_update_customers" ON customers FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "auth_delete_customers" ON customers FOR DELETE USING (auth.role() = 'authenticated');

-- quotations
CREATE POLICY "auth_read_quotations"   ON quotations FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "auth_insert_quotations" ON quotations FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "auth_update_quotations" ON quotations FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "auth_delete_quotations" ON quotations FOR DELETE USING (auth.role() = 'authenticated');

-- quotation_items
CREATE POLICY "auth_read_quotation_items"   ON quotation_items FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "auth_insert_quotation_items" ON quotation_items FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "auth_update_quotation_items" ON quotation_items FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "auth_delete_quotation_items" ON quotation_items FOR DELETE USING (auth.role() = 'authenticated');

-- ============================================================
-- Done!
-- ============================================================
