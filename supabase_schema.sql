-- Enable PostGIS Extension for Geospatial Queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- ─── PROFILES (extends Supabase auth.users) ───────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  phone_number TEXT UNIQUE,
  full_name TEXT,
  nin TEXT,
  nin_verified BOOLEAN DEFAULT FALSE,
  role TEXT DEFAULT 'citizen',
  community_id TEXT,
  lga TEXT,
  state TEXT,
  location GEOGRAPHY(POINT, 4326),
  emergency_contacts JSONB DEFAULT '[]'::jsonb,
  fcm_token TEXT,
  is_subscribed BOOLEAN DEFAULT FALSE,
  subscription_plan TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own profile" ON public.profiles;
CREATE POLICY "Users manage own profile"
  ON public.profiles FOR ALL USING (auth.uid() = id);

-- ─── COMMUNITIES (Pre-seeded with 774 LGAs from GADM) ─────────────────────
CREATE TABLE IF NOT EXISTS public.communities (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  level TEXT NOT NULL,
  parent_id TEXT REFERENCES public.communities(id),
  state TEXT,
  lga TEXT,
  boundary GEOGRAPHY(POLYGON, 4326),
  leader_user_id UUID REFERENCES public.profiles(id),
  leader_name TEXT,
  leader_role TEXT,
  member_count INTEGER DEFAULT 0,
  active_vigilantes INTEGER DEFAULT 0,
  safety_score INTEGER DEFAULT 75,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS communities_boundary_idx ON public.communities USING GIST(boundary);

-- PostGIS function: find community from GPS coordinates
CREATE OR REPLACE FUNCTION find_community_at_location(lat FLOAT, lng FLOAT)
RETURNS JSONB AS $$
  SELECT row_to_json(c)::jsonb FROM public.communities c
  WHERE ST_Contains(c.boundary::geometry, ST_SetSRID(ST_MakePoint(lng, lat), 4326))
  ORDER BY level ASC LIMIT 1;
$$ LANGUAGE sql STABLE;

-- PostGIS function: expand boundary to include new member's house
CREATE OR REPLACE FUNCTION expand_community_boundary_for_member(
  community_id_param TEXT, member_lat FLOAT, member_lng FLOAT
) RETURNS VOID AS $$
BEGIN
  UPDATE public.communities SET
    boundary = ST_Multi(ST_Buffer(
      ST_ConvexHull(ST_Collect(
        boundary::geometry,
        ST_SetSRID(ST_MakePoint(member_lng, member_lat), 4326)
      )), 0.0001))::geography
  WHERE id = community_id_param;
END;
$$ LANGUAGE plpgsql;

-- ─── INCIDENTS ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.incidents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id UUID REFERENCES public.profiles(id),
  type TEXT NOT NULL,
  severity INTEGER DEFAULT 50,
  description TEXT,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  location_name TEXT,
  community_id TEXT,
  lga TEXT,
  state TEXT DEFAULT 'Nigeria',
  media_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
  is_verified BOOLEAN DEFAULT FALSE,
  verification_count INTEGER DEFAULT 0,
  is_anonymous BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS incidents_location_idx ON public.incidents USING GIST(location);
CREATE INDEX IF NOT EXISTS incidents_time_idx ON public.incidents(created_at DESC);

-- ─── MISSING PERSONS ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.missing_persons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id UUID REFERENCES public.profiles(id),
  full_name TEXT NOT NULL,
  age INTEGER,
  gender TEXT,
  last_seen_location GEOGRAPHY(POINT, 4326),
  last_seen_location_name TEXT,
  last_seen_date TIMESTAMPTZ,
  description TEXT,
  photo_url TEXT,
  contact_name TEXT,
  contact_phone TEXT,
  case_status TEXT DEFAULT 'active',
  community_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── SOS EVENTS ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sos_events (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id),
  mode TEXT,
  category TEXT,
  location GEOGRAPHY(POINT, 4326),
  address TEXT,
  battery_level INTEGER,
  targets JSONB,
  status TEXT DEFAULT 'dispatched',
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Live location stream during active SOS
CREATE TABLE IF NOT EXISTS public.sos_location_stream (
  sos_id TEXT PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id),
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.sos_location_stream ENABLE ROW LEVEL SECURITY;

-- ─── VIGILANTE IDs ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vigilante_ids (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) UNIQUE,
  badge_number TEXT UNIQUE,
  rank_title TEXT,
  group_name TEXT,
  community_id TEXT REFERENCES public.communities(id),
  qr_signature TEXT,
  is_patrol_active BOOLEAN DEFAULT FALSE,
  is_revoked BOOLEAN DEFAULT FALSE,
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

-- ─── ANNOUNCEMENTS ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  community_id TEXT REFERENCES public.communities(id),
  author_id UUID REFERENCES public.profiles(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  priority TEXT DEFAULT 'normal',
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── JOURNEYS ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.journeys (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id),
  origin_name TEXT,
  destination_name TEXT,
  origin_lat DOUBLE PRECISION,
  origin_lng DOUBLE PRECISION,
  dest_lat DOUBLE PRECISION,
  dest_lng DOUBLE PRECISION,
  start_time TIMESTAMPTZ DEFAULT NOW(),
  estimated_arrival TIMESTAMPTZ,
  total_distance_km INTEGER,
  status TEXT DEFAULT 'active',
  last_checkin TIMESTAMPTZ,
  current_lat DOUBLE PRECISION,
  current_lng DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── ZONE MESSAGES (Neighbourhood Chat) ─────────────────────────────────────
-- Each neighbourhood zone has its own chat channel.
-- Residents of the same zone see each other's messages.
-- Messages older than 7 days can be cleaned up via a scheduled function.
CREATE TABLE IF NOT EXISTS public.zone_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  zone_id TEXT NOT NULL REFERENCES public.communities(id),
  sender_id TEXT NOT NULL,
  sender_name TEXT NOT NULL,
  message TEXT NOT NULL,
  is_leader BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS zone_messages_zone_idx ON public.zone_messages(zone_id, created_at DESC);

ALTER TABLE public.zone_messages ENABLE ROW LEVEL SECURITY;

-- Allow any authenticated user to read messages in their zone
DROP POLICY IF EXISTS "Read zone messages" ON public.zone_messages;
CREATE POLICY "Read zone messages"
  ON public.zone_messages FOR SELECT USING (true);

-- Allow any authenticated user to insert messages
DROP POLICY IF EXISTS "Send zone messages" ON public.zone_messages;
CREATE POLICY "Send zone messages"
  ON public.zone_messages FOR INSERT WITH CHECK (true);

-- Enable Realtime on zone_messages (run once in Supabase dashboard > Database > Replication)
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.zone_messages;

-- ─── ZONE EVENTS (Geofence Entry/Exit Log) ──────────────────────────────────
-- Silent background log of all zone boundary crossing events.
-- is_night_time = true when event occurs between 12:00AM and 5:00AM.
-- is_resident = true when the user's registered home zone matches this zone.
CREATE TABLE IF NOT EXISTS public.zone_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  zone_id TEXT NOT NULL,
  zone_name TEXT,
  user_id TEXT,
  event_type TEXT NOT NULL CHECK (event_type IN ('enter', 'exit')),
  is_resident BOOLEAN DEFAULT FALSE,
  is_night_time BOOLEAN DEFAULT FALSE,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  device_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS zone_events_zone_idx ON public.zone_events(zone_id, created_at DESC);
CREATE INDEX IF NOT EXISTS zone_events_night_idx ON public.zone_events(is_night_time, is_resident, created_at DESC);

ALTER TABLE public.zone_events ENABLE ROW LEVEL SECURITY;

-- Allow inserts from any user (background geofence logging)
DROP POLICY IF EXISTS "Log zone events" ON public.zone_events;
CREATE POLICY "Log zone events"
  ON public.zone_events FOR INSERT WITH CHECK (true);

-- Allow community leaders to read events for their zone
DROP POLICY IF EXISTS "Read zone events" ON public.zone_events;
CREATE POLICY "Read zone events"
  ON public.zone_events FOR SELECT USING (true);

-- Helper view: suspicious night events in last 24 hours
CREATE OR REPLACE VIEW public.night_alerts AS
  SELECT * FROM public.zone_events
  WHERE is_night_time = TRUE
    AND is_resident = FALSE
    AND created_at >= NOW() - INTERVAL '24 hours'
  ORDER BY created_at DESC;

