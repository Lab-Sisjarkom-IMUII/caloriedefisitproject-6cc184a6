-- ====================================
-- SUPABASE TABLES FOR HEALTH TRACKER APP
-- Run this in Supabase SQL Editor
-- ====================================

-- ====================================
-- TABLE: user_activities
-- Menyimpan semua data aktivitas user (steps, running, water, gym, sleep, food)
-- ====================================
CREATE TABLE IF NOT EXISTS user_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    activity_data JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint: one record per user
    CONSTRAINT user_activities_user_id_unique UNIQUE (user_id)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_activities_user_id ON user_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activities_email ON user_activities(email);

-- Enable RLS (Row Level Security)
ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own data
CREATE POLICY "Users can view own activities" ON user_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activities" ON user_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own activities" ON user_activities
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own activities" ON user_activities
    FOR DELETE USING (auth.uid() = user_id);

-- ====================================
-- TABLE: weight_tracking
-- Menyimpan data berat badan (terpisah untuk performa)
-- ====================================
CREATE TABLE IF NOT EXISTS weight_tracking (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    weight DECIMAL(5,2) NOT NULL,
    date DATE NOT NULL,
    time TIME,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint: one weight entry per user per date
    CONSTRAINT weight_tracking_user_date_unique UNIQUE (user_id, date)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_weight_tracking_user_id ON weight_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_weight_tracking_date ON weight_tracking(date DESC);

-- Enable RLS
ALTER TABLE weight_tracking ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own weight data
CREATE POLICY "Users can view own weight" ON weight_tracking
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own weight" ON weight_tracking
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own weight" ON weight_tracking
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own weight" ON weight_tracking
    FOR DELETE USING (auth.uid() = user_id);

-- ====================================
-- TABLE: users (if not exists)
-- Profile data untuk user
-- ====================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    nama_lengkap TEXT,
    jenis_kelamin TEXT,
    tempat_lahir TEXT,
    tanggal_lahir DATE,
    golongan_darah TEXT,
    tinggi_badan DECIMAL(5,2),
    berat_badan DECIMAL(5,2),
    berat_badan_target DECIMAL(5,2),
    nomor_wa TEXT,
    goal TEXT,
    has_completed_data BOOLEAN DEFAULT FALSE,
    is_google_user BOOLEAN DEFAULT FALSE,
    picture_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- ====================================
-- FUNCTION: Update timestamp
-- ====================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for user_activities
DROP TRIGGER IF EXISTS update_user_activities_updated_at ON user_activities;
CREATE TRIGGER update_user_activities_updated_at
    BEFORE UPDATE ON user_activities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for users
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ====================================
-- DONE!
-- ====================================
-- Setelah menjalankan script ini, tabel akan otomatis:
-- 1. Menyimpan data aktivitas per user (user_activities)
-- 2. Menyimpan data berat badan (weight_tracking)
-- 3. Menyimpan profile user (users)
-- 4. Row Level Security aktif - user hanya bisa akses data sendiri
-- ====================================