-- ============================================================================
-- FLASHFIT BY SETMEFIT - DATABASE SCHEMA & SEED DATA
-- Premium Multi-Gym Membership & Slot Booking System
-- ============================================================================

-- 1. GYMS TABLE
CREATE TABLE IF NOT EXISTS flashfit_gyms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    tagline TEXT,
    brand TEXT DEFAULT 'FlashFit Partner',
    description TEXT,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    locality TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    rating NUMERIC(2,1) DEFAULT 4.8,
    review_count INTEGER DEFAULT 120,
    image_urls TEXT[] NOT NULL DEFAULT '{}',
    facilities TEXT[] NOT NULL DEFAULT '{}',
    operating_hours JSONB DEFAULT '{"mon_fri": "5:30 AM - 11:00 PM", "sat_sun": "6:00 AM - 10:00 PM"}'::jsonb,
    contact_phone TEXT,
    tier TEXT DEFAULT 'FlashFit Elite',
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. WORKOUT SLOTS TABLE
CREATE TABLE IF NOT EXISTS flashfit_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID NOT NULL REFERENCES flashfit_gyms(id) ON DELETE CASCADE,
    slot_date DATE NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    session_type TEXT DEFAULT 'General Gym & Cardio',
    total_capacity INTEGER NOT NULL DEFAULT 15,
    booked_count INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT chk_capacity CHECK (booked_count <= total_capacity),
    CONSTRAINT uq_gym_slot UNIQUE (gym_id, slot_date, start_time)
);

-- 3. USER SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS flashfit_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL UNIQUE,
    plan_name TEXT NOT NULL DEFAULT 'SetMeFit All-Access Pass',
    tier TEXT NOT NULL DEFAULT 'ELITE', -- 'ELITE', 'PRO', 'BASIC'
    is_active BOOLEAN NOT NULL DEFAULT true,
    sessions_per_month INTEGER DEFAULT 30,
    sessions_used INTEGER DEFAULT 0,
    valid_until TIMESTAMPTZ DEFAULT (now() + interval '30 days'),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. BOOKINGS TABLE
CREATE TABLE IF NOT EXISTS flashfit_bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    gym_id UUID NOT NULL REFERENCES flashfit_gyms(id) ON DELETE CASCADE,
    slot_id UUID NOT NULL REFERENCES flashfit_slots(id) ON DELETE CASCADE,
    booking_date DATE NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    session_type TEXT NOT NULL DEFAULT 'General Gym & Cardio',
    status TEXT NOT NULL DEFAULT 'upcoming', -- 'upcoming', 'completed', 'cancelled'
    booking_code TEXT NOT NULL,
    gym_name TEXT NOT NULL,
    gym_address TEXT NOT NULL,
    gym_image TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    cancelled_at TIMESTAMPTZ,
    check_in_at TIMESTAMPTZ
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_gyms_city ON flashfit_gyms(city);
CREATE INDEX IF NOT EXISTS idx_slots_gym_date ON flashfit_slots(gym_id, slot_date);
CREATE INDEX IF NOT EXISTS idx_bookings_user_status ON flashfit_bookings(user_id, status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON flashfit_subscriptions(user_id);

-- ============================================================================
-- ATOMIC BOOKING FUNCTION (Validates subscription, capacity & avoids double booking)
-- ============================================================================
CREATE OR REPLACE FUNCTION book_flashfit_slot(
    p_user_id TEXT,
    p_gym_id UUID,
    p_slot_id UUID,
    p_booking_code TEXT,
    p_slot_date DATE DEFAULT NULL,
    p_start_time TEXT DEFAULT NULL,
    p_end_time TEXT DEFAULT NULL,
    p_session_type TEXT DEFAULT 'General Gym & Cardio'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_sub RECORD;
    v_slot RECORD;
    v_existing_booking UUID;
    v_gym RECORD;
    v_booking_id UUID;
    v_target_date DATE;
    v_target_start TEXT;
BEGIN
    -- 1. Check active subscription (or auto-provision for demo/active user)
    SELECT * INTO v_sub FROM flashfit_subscriptions
    WHERE user_id = p_user_id AND is_active = true AND valid_until > now();

    IF NOT FOUND THEN
        -- Auto-provision an active pass for seamless onboarding
        INSERT INTO flashfit_subscriptions (user_id, plan_name, tier, is_active, sessions_per_month, sessions_used, valid_until)
        VALUES (p_user_id, 'FlashFit Elite All-Access Pass', 'ELITE', true, 30, 0, now() + interval '30 days')
        ON CONFLICT (user_id) DO UPDATE SET is_active = true, valid_until = now() + interval '30 days'
        RETURNING * INTO v_sub;
    END IF;

    -- 2. Lock and retrieve slot (by ID or gym + date + start_time)
    SELECT * INTO v_slot FROM flashfit_slots
    WHERE (id = p_slot_id OR (p_slot_date IS NOT NULL AND gym_id = p_gym_id AND slot_date = p_slot_date AND start_time = p_start_time))
      AND is_active = true
    FOR UPDATE;

    -- If slot does not exist yet (e.g. dynamic date), auto-create it
    IF NOT FOUND THEN
        v_target_date := COALESCE(p_slot_date, CURRENT_DATE);
        v_target_start := COALESCE(p_start_time, '06:00 AM');
        
        INSERT INTO flashfit_slots (
            id, gym_id, slot_date, start_time, end_time, session_type, total_capacity, booked_count, is_active
        ) VALUES (
            p_slot_id, p_gym_id, v_target_date, v_target_start,
            COALESCE(p_end_time, '07:30 AM'), COALESCE(p_session_type, 'General Gym & Cardio'), 15, 0, true
        )
        ON CONFLICT (gym_id, slot_date, start_time) DO UPDATE
        SET is_active = true
        RETURNING * INTO v_slot;
    END IF;

    -- 3. Check capacity
    IF v_slot.booked_count >= v_slot.total_capacity THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SLOT_FULL',
            'message', 'Sorry, this workout slot has reached full capacity.'
        );
    END IF;

    -- 4. Check for double booking by same user on the same date/time
    SELECT id INTO v_existing_booking FROM flashfit_bookings
    WHERE user_id = p_user_id
      AND booking_date = v_slot.slot_date
      AND start_time = v_slot.start_time
      AND status = 'upcoming'
    LIMIT 1;

    IF v_existing_booking IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'ALREADY_BOOKED',
            'message', 'You already have an active workout booking scheduled for this time slot.'
        );
    END IF;

    -- 5. Fetch gym details
    SELECT * INTO v_gym FROM flashfit_gyms WHERE id = p_gym_id;

    -- 6. Atomically increment slot count
    UPDATE flashfit_slots
    SET booked_count = booked_count + 1
    WHERE id = v_slot.id;

    -- 7. Insert booking record
    INSERT INTO flashfit_bookings (
        user_id, gym_id, slot_id, booking_date, start_time, end_time,
        session_type, status, booking_code, gym_name, gym_address, gym_image
    ) VALUES (
        p_user_id, p_gym_id, v_slot.id, v_slot.slot_date, v_slot.start_time, v_slot.end_time,
        v_slot.session_type, 'upcoming', p_booking_code,
        COALESCE(v_gym.name, 'FlashFit Partner Gym'),
        COALESCE(v_gym.address, 'Studio Location'),
        CASE WHEN v_gym.image_urls IS NOT NULL AND array_length(v_gym.image_urls, 1) > 0 THEN v_gym.image_urls[1] ELSE NULL END
    ) RETURNING id INTO v_booking_id;

    -- 8. Increment user sessions used
    UPDATE flashfit_subscriptions
    SET sessions_used = sessions_used + 1
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'booking_id', v_booking_id,
        'booking_code', p_booking_code,
        'message', 'Workout session confirmed successfully!'
    );
END;
$$;

-- ============================================================================
-- CANCELLATION FUNCTION
-- ============================================================================
CREATE OR REPLACE FUNCTION cancel_flashfit_booking(
    p_booking_id UUID,
    p_user_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_booking RECORD;
BEGIN
    SELECT * INTO v_booking FROM flashfit_bookings
    WHERE id = p_booking_id AND user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Booking not found.');
    END IF;

    IF v_booking.status = 'cancelled' THEN
        RETURN jsonb_build_object('success', false, 'message', 'Booking is already cancelled.');
    END IF;

    -- Mark as cancelled
    UPDATE flashfit_bookings
    SET status = 'cancelled', cancelled_at = now()
    WHERE id = p_booking_id;

    -- Restore slot count
    UPDATE flashfit_slots
    SET booked_count = GREATEST(0, booked_count - 1)
    WHERE id = v_booking.slot_id;

    -- Decrement user sessions used
    UPDATE flashfit_subscriptions
    SET sessions_used = GREATEST(0, sessions_used - 1)
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object('success', true, 'message', 'Booking cancelled successfully.');
END;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE flashfit_gyms ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashfit_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashfit_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashfit_bookings ENABLE ROW LEVEL SECURITY;

-- Gyms & Slots are publicly accessible
CREATE POLICY "Public gyms accessible by all" ON flashfit_gyms FOR ALL USING (true);
CREATE POLICY "Public slots accessible by all" ON flashfit_slots FOR ALL USING (true);

-- Subscriptions viewable and manageable by user
CREATE POLICY "Users can manage their subscriptions" ON flashfit_subscriptions FOR ALL USING (true);

-- Bookings viewable and manageable by user
CREATE POLICY "Users can manage their bookings" ON flashfit_bookings FOR ALL USING (true);

-- ============================================================================
-- SEED DATA: PREMIER PARTNER GYMS
-- ============================================================================
INSERT INTO flashfit_gyms (id, name, tagline, brand, description, address, city, locality, latitude, longitude, rating, review_count, image_urls, facilities, operating_hours, contact_phone, tier, is_featured)
VALUES
(
    'a1111111-1111-1111-1111-111111111111',
    'Volt Arena Performance Gym',
    'Elite Olympic Lifting & Hypertrophy Hub',
    'FlashFit Signature',
    'Volt Arena is an elite 12,000 sq ft conditioning center equipped with Eleiko barbell stations, Hammer Strength plate-loaded machines, Olympic turf, and bio-recovery steam chambers.',
    '42, 100 Feet Rd, Indiranagar, Bengaluru, Karnataka 560038',
    'Bangalore',
    'Indiranagar',
    12.9784,
    77.6408,
    4.9,
    342,
    ARRAY[
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=1200&auto=format&fit=crop'
    ],
    ARRAY['Heavy Weights', 'Cardio Deck', 'Olympic Turf', 'Steam Bath', 'Lockers', 'Shower', 'Personal Trainers', 'Protein Bar'],
    '{"mon_fri": "5:30 AM - 11:00 PM", "sat_sun": "6:00 AM - 10:00 PM"}'::jsonb,
    '+91 98801 23456',
    'FlashFit Elite',
    true
),
(
    'b2222222-2222-2222-2222-222222222222',
    'Titan Hydro & Strength Club',
    'Dual-Zone Lifting & Heated Lap Pool',
    'FlashFit Signature',
    'Featuring an indoor semi-Olympic heated pool, dedicated CrossFit rig, specialized glute and leg builder zones, and certified physical therapy support.',
    '7th Main Rd, 4th Block, Koramangala, Bengaluru, Karnataka 560034',
    'Bangalore',
    'Koramangala',
    12.9352,
    77.6245,
    4.8,
    289,
    ARRAY[
        'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?q=80&w=1200&auto=format&fit=crop'
    ],
    ARRAY['Swimming Pool', 'Heavy Weights', 'CrossFit', 'Sauna', 'Lockers', 'Shower', 'Physiotherapy'],
    '{"mon_fri": "6:00 AM - 10:30 PM", "sat_sun": "6:30 AM - 9:30 PM"}'::jsonb,
    '+91 98802 34567',
    'FlashFit Elite',
    true
),
(
    'c3333333-3333-3333-3333-333333333333',
    'Iron Vault Fitness Studio',
    'Old-School Powerlifting & Modern Bio-Tracking',
    'FlashFit Partner',
    'Built for pure grit and biomechanics. Features calibrated competition plates, custom cable machinery, heavy dumbbells up to 70kg, and dedicated stretching pods.',
    '24th Main, HSR Layout Sector 2, Bengaluru, Karnataka 560102',
    'Bangalore',
    'HSR Layout',
    12.9116,
    77.6474,
    4.7,
    195,
    ARRAY[
        'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1200&auto=format&fit=crop'
    ],
    ARRAY['Heavy Weights', 'Cardio Deck', 'Lockers', 'Shower', 'Personal Trainers'],
    '{"mon_fri": "5:00 AM - 11:00 PM", "sat_sun": "6:00 AM - 10:00 PM"}'::jsonb,
    '+91 98803 45678',
    'FlashFit Pro',
    false
),
(
    'd4444444-4444-4444-4444-444444444444',
    'Aura Wellness & Functional Fitness',
    'Mindful Strength, Calisthenics & Hot Yoga',
    'FlashFit Signature',
    'A breathtaking sanctuary integrating high-intensity functional training with infrared sauna, sound-bath yoga studio, and restorative vitality baths.',
    'Linking Road, Bandra West, Mumbai, Maharashtra 400050',
    'Mumbai',
    'Bandra West',
    19.0607,
    72.8362,
    4.9,
    412,
    ARRAY[
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=1200&auto=format&fit=crop'
    ],
    ARRAY['Yoga', 'Sauna', 'Cardio Deck', 'Lockers', 'Shower', 'Smoothie Bar', 'Steam Bath'],
    '{"mon_fri": "6:00 AM - 10:00 PM", "sat_sun": "7:00 AM - 9:00 PM"}'::jsonb,
    '+91 98201 98765',
    'FlashFit Elite',
    true
),
(
    'e5555555-5555-5555-5555-555555555555',
    'Krypton 24/7 Athletic Club',
    'Round-the-Clock Biomechanical Training',
    'FlashFit Partner',
    'Never miss a workout. 24-hour smart access, cardio cinematic theater, pin-loaded resistance towers, and kettlebell combat zone.',
    'Cyber City Phase 2, Gurugram, Delhi NCR 122002',
    'Delhi NCR',
    'Gurugram',
    28.4907,
    77.0892,
    4.8,
    260,
    ARRAY[
        'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1534367507873-d2d7e24c797f?q=80&w=1200&auto=format&fit=crop'
    ],
    ARRAY['24/7 Access', 'Heavy Weights', 'Cardio Deck', 'Lockers', 'Shower'],
    '{"mon_fri": "Open 24 Hours", "sat_sun": "Open 24 Hours"}'::jsonb,
    '+91 98111 54321',
    'FlashFit Pro',
    false
)
ON CONFLICT (id) DO NOTHING;

-- SEED WORKOUT SLOTS FOR TODAY & UPCOMING DAYS
DO $$
DECLARE
    gym_rec RECORD;
    d DATE;
BEGIN
    FOR gym_rec IN SELECT id FROM flashfit_gyms LOOP
        FOR i IN 0..4 LOOP
            d := CURRENT_DATE + i;
            
            INSERT INTO flashfit_slots (gym_id, slot_date, start_time, end_time, session_type, total_capacity, booked_count)
            VALUES
            (gym_rec.id, d, '06:00 AM', '07:30 AM', 'Morning Power Conditioning', 15, CASE WHEN i = 0 THEN 14 ELSE 8 END),
            (gym_rec.id, d, '07:30 AM', '09:00 AM', 'Peak Hypertrophy & Cardio', 15, CASE WHEN i = 0 THEN 15 ELSE 12 END),
            (gym_rec.id, d, '09:00 AM', '10:30 AM', 'General Open Gym', 15, 6),
            (gym_rec.id, d, '11:00 AM', '12:30 PM', 'Midday Functional Strength', 12, 4),
            (gym_rec.id, d, '04:00 PM', '05:30 PM', 'Afternoon Performance Lift', 15, 7),
            (gym_rec.id, d, '05:30 PM', '07:00 PM', 'Evening Prime Strength', 18, CASE WHEN i = 0 THEN 17 ELSE 10 END),
            (gym_rec.id, d, '07:00 PM', '08:30 PM', 'Night Rush HIIT & Lift', 18, CASE WHEN i = 0 THEN 18 ELSE 13 END),
            (gym_rec.id, d, '08:30 PM', '10:00 PM', 'Late Night Recovery & Weights', 15, 3)
            ON CONFLICT (gym_id, slot_date, start_time) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;
