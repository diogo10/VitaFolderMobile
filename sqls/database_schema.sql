-- 1. profiles
create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  full_name text,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now(),
  terms_accepted_at timestamp,
  email varchar(255),
  avatar_url text,

  primary key (id)
);

-- Grant the privileges the roles need
GRANT SELECT ON public.profiles TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO service_role;

-- Enable row level security for the table
alter table public.profiles enable row level security;

-- 2. families
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    country_code TEXT,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. family_memberships
CREATE TABLE family_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(family_id, user_id)
);

-- 4. people
CREATE TABLE people (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    date_of_birth DATE,
    relationship TEXT CHECK (relationship IN ('self', 'spouse', 'child', 'parent', 'other')),
    blood_type TEXT,
    allergies TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. documents
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    type TEXT CHECK (type IN ('prescription', 'exam', 'vaccine', 'sick_note', 'insurance', 'appointment', 'other')),
    title TEXT NOT NULL,
    issuer_name TEXT,
    document_date DATE,
    expiry_date DATE,
    status TEXT CHECK (status IN ('active', 'expired', 'archived')),
    notes TEXT,
    country_code TEXT,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. document_files
CREATE TABLE document_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT,
    file_size INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. reminders
CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
    type TEXT CHECK (type IN ('renewal', 'appointment', 'vaccine', 'reimbursement', 'follow_up', 'custom')),
    title TEXT NOT NULL,
    due_at TIMESTAMPTZ,
    remind_before INTERVAL,
    repeat_rule TEXT,
    status TEXT CHECK (status IN ('pending', 'sent', 'done', 'dismissed', 'cancelled')),
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. notification_tokens
CREATE TABLE notification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT CHECK (platform IN ('ios', 'android')),
    last_seen_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. notification_logs
CREATE TABLE notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reminder_id UUID NOT NULL REFERENCES reminders(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT CHECK (status IN ('sent', 'failed')),
    error_message TEXT
);

-- 10. country_pack_rules
CREATE TABLE country_pack_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code TEXT NOT NULL,
    rule_type TEXT CHECK (rule_type IN ('vaccine', 'prescription', 'sick_note', 'insurance')),
    name TEXT NOT NULL,
    description TEXT,
    metadata JSONB,
    active BOOLEAN DEFAULT true
);

--------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) POLICIES
--------------------------------------------------------

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE people ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE country_pack_rules ENABLE ROW LEVEL SECURITY;

-- PROFILES
-- Users can read and update their own profile
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- FAMILIES
-- Users can view families they belong to
CREATE POLICY "Users can view their families" ON families FOR SELECT USING (
    EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = families.id AND fm.user_id = auth.uid())
);
-- Users can create a family (they are assigned as created_by)
CREATE POLICY "Users can create families" ON families FOR INSERT WITH CHECK (auth.uid() = created_by);
-- Only owners/admins can update family details
CREATE POLICY "Admins can update family" ON families FOR UPDATE USING (
    EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = families.id AND fm.user_id = auth.uid() AND fm.role IN ('owner', 'admin'))
);

-- FAMILY MEMBERSHIPS
-- Users can see all members in a family they belong to
CREATE POLICY "Users can view family members" ON family_memberships FOR SELECT USING (
    EXISTS (SELECT 1 FROM family_memberships my_fm WHERE my_fm.family_id = family_memberships.family_id AND my_fm.user_id = auth.uid())
);

-- PEOPLE (Family members details)
CREATE POLICY "Users can view family people" ON people FOR SELECT USING (
    EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = people.family_id AND fm.user_id = auth.uid())
);
CREATE POLICY "Users can manage family people" ON people FOR ALL USING (
    EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = people.family_id AND fm.user_id = auth.uid() AND fm.role IN ('owner', 'admin', 'member'))
);

-- DOCUMENTS
CREATE POLICY "Users can view family documents" ON documents FOR SELECT USING (
    EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = documents.family_id AND fm.user_id = auth.uid())
);
CREATE POLICY "Users can manage family documents" ON documents FOR ALL USING (
    EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = documents.family_id AND fm.user_id = auth.uid() AND fm.role IN ('owner', 'admin', 'member'))
);

-- DOCUMENT FILES
-- Join through documents to check family_id
CREATE POLICY "Users can view family document files" ON document_files FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM documents d
        JOIN family_memberships fm ON fm.family_id = d.family_id
        WHERE d.id = document_files.document_id AND fm.user_id = auth.uid()
    )
);
CREATE POLICY "Users can manage family document files" ON document_files FOR ALL USING (
    EXISTS (
        SELECT 1 FROM documents d
        JOIN family_memberships fm ON fm.family_id = d.family_id
        WHERE d.id = document_files.document_id AND fm.user_id = auth.uid() AND fm.role IN ('owner', 'admin', 'member')
    )
);

-- REMINDERS
CREATE POLICY "Users can view family reminders" ON reminders FOR SELECT USING (
    EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = reminders.family_id AND fm.user_id = auth.uid())
);
CREATE POLICY "Users can manage family reminders" ON reminders FOR ALL USING (
    EXISTS (SELECT 1 FROM family_memberships fm WHERE fm.family_id = reminders.family_id AND fm.user_id = auth.uid() AND fm.role IN ('owner', 'admin', 'member'))
);

-- NOTIFICATION TOKENS
CREATE POLICY "Users can manage own tokens" ON notification_tokens FOR ALL USING (auth.uid() = user_id);

-- NOTIFICATION LOGS
-- Users can view their own notification logs
CREATE POLICY "Users can view own notification logs" ON notification_logs FOR SELECT USING (auth.uid() = user_id);

-- COUNTRY PACK RULES
-- Global read access to active country packs
CREATE POLICY "Public can view active country packs" ON country_pack_rules FOR SELECT USING (active = true);