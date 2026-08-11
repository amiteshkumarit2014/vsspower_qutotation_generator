# VSS Power Quotation Generator — Supabase Setup Guide

## Overview

This application uses **Supabase** (PostgreSQL) as the backend database.

Architecture:
```
GitHub Pages (index.html)
       ↓
Supabase JavaScript Client (CDN)
       ↓
Supabase REST API / Auth
       ↓
PostgreSQL (Supabase hosted)
```

---

## Step 1 — Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click **New project**
3. Choose your organisation
4. Enter a project name (e.g. `vss-power-quotations`)
5. Set a strong database password (save it somewhere safe)
6. Choose a region closest to you (e.g. `eu-west-2` for UK)
7. Click **Create new project**
8. Wait ~2 minutes for the project to be ready

---

## Step 2 — Run the Schema SQL

1. In your Supabase project, go to **SQL Editor** (left sidebar)
2. Click **New query**
3. Open the file `supabase/schema.sql` from this project
4. Copy all of it and paste it into the SQL Editor
5. Click **Run**
6. You should see: *"Success. No rows returned."*

This creates:
- `company_settings` table
- `customers` table
- `quotations` table (with `payload` column that stores the full quotation JSON)
- `quotation_items` table
- Triggers for `updated_at`
- Row Level Security policies

---

## Step 3 — Enable Email Authentication

1. In Supabase, go to **Authentication → Providers**
2. Make sure **Email** is enabled (it is by default)
3. Optionally disable **Confirm email** for testing:
   - Go to **Authentication → Settings**
   - Toggle off "Enable email confirmations" (easier for initial testing)
   - Re-enable it later for production

---

## Step 4 — Get Your Supabase Keys

1. In your Supabase project, go to **Settings → API**
2. Copy:
   - **Project URL** (e.g. `https://xxxxxxxxxxxx.supabase.co`)
   - **anon / public key** (the long `eyJ...` string — this is safe for frontend)
3. ⚠️ **NEVER** use the `service_role` key in the frontend

These values are already configured in `index.html`:
```js
const SUPABASE_URL = 'https://mrrbmaeuvleikyzczzkr.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_4sGVEj-rWlO7kE-3fIqFzw_xSM4oOUQ';
```

If you ever need to change them, update those two lines in `index.html` (inside the `<script type="text/babel">` block).

---

## Step 5 — Run the Application Locally

Simply open `index.html` in a browser.

Or serve it locally:
```bash
# Python
python -m http.server 8080

# Node.js (npx)
npx serve .
```

Then go to: `http://localhost:8080`

---

## Step 6 — Create Your First User Account

1. Open the app
2. Click **Sign Up** on the login screen
3. Enter your email and a password (minimum 6 characters)
4. If email confirmation is enabled: check your email and confirm
5. Sign in

---

## Step 7 — Test the Full Flow

### Test 1 — Login
- Open the app
- Sign in with your email/password
- You should see the Dashboard

### Test 2 — Create a Customer
- Go to **Clients** in the sidebar
- Click **+ Add Client**
- Fill in company name and details
- Click **Save Client**
- Check Supabase → Table Editor → `customers` — the row should appear

### Test 3 — Create a Quotation (single item)
- Click **+ New Quotation**
- Step 1: Enter client company name
- Step 2: Enter project name
- Step 3: Click "Add from Catalogue", pick a service
- Click through to the end and **Save & Close**
- Check Supabase → `quotations` table

### Test 4 — Create a Quotation (multiple items)
- Repeat Test 3 with 3+ service line items

### Test 5 — Verify Calculations
- Open a quotation in the wizard
- Step 3: Check subtotal, VAT, grand total match expected values

### Test 6 — Refresh Browser
- Refresh the page
- The quotation should still be present (loaded from Supabase)

### Test 7 — Edit a Quotation
- Click ✎ on any quotation
- Change a line item rate
- Click **Save & Close**
- Refresh — confirm the change persisted

### Test 8 — Generate PDF
- Click ⭳ (PDF icon) on any quotation
- A PDF should download

### Test 9 — Change Status
- In the Quotations list, open a quotation
- The status badge shows the current status
- (Status can be changed from within the quotation wizard — currently by editing in Step 1 area or via Supabase Table Editor directly for now)

### Test 10 — Search Quotation
- On the Dashboard or Quotations page, type in the search box
- Filter by client or quotation number

### Test 11 — Logout
- Click **Sign Out** at the bottom of the sidebar
- You are redirected to the login screen

### Test 12 — Unauthenticated Access
- Without logging in, try accessing Supabase directly via the anon key — RLS blocks all reads/writes

### Test 13 — Delete Quotation
- Click ✕ on a quotation
- Confirm deletion
- The quotation and its items are deleted from Supabase (CASCADE)

---

## Step 8 — Configure Company Settings

1. Sign in to the app
2. Click **Settings** in the sidebar
3. Update company name, address, phone, email, VAT number etc.
4. Click **Save Settings**
5. These values now persist in Supabase `company_settings` table
6. PDFs will use these company details

---

## Step 9 — Deploy to GitHub Pages

```bash
# In the project folder:
git add .
git commit -m "Add Supabase integration"
git push origin main
```

Then in GitHub:
1. Go to your repo → **Settings → Pages**
2. Source: **Deploy from branch**
3. Branch: `main`, Folder: `/ (root)`
4. Save

Your app will be live at:
`https://<your-github-username>.github.io/vsspower_qutotation_generator/`

---

## Database Tables Summary

| Table | Purpose |
|---|---|
| `company_settings` | VSS Power company info (name, address, VAT, etc.) |
| `customers` | Client/customer database |
| `quotations` | Quotation header + full JSON payload |
| `quotation_items` | Individual line items per quotation |

---

## RLS Policies Summary

All four tables have Row Level Security enabled.

**Policy:** Any authenticated user (logged in via Supabase Auth) can:
- SELECT (read) all rows
- INSERT new rows
- UPDATE existing rows
- DELETE rows (customers, quotations, quotation_items)

**Unauthenticated users cannot access any data** — all queries via the anon key are blocked by RLS unless the user has a valid session token.

---

## Environment Variables

This is a static HTML application with no build step.

The Supabase URL and anon key are configured directly in `index.html`:

```js
const SUPABASE_URL = 'https://mrrbmaeuvleikyzczzkr.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_4sGVEj-rWlO7kE-3fIqFzw_xSM4oOUQ';
```

The **anon/publishable key is safe to include in frontend code** — it is a public key.  
The RLS policies ensure only authenticated users can read/write data.

⚠️ Never put the `service_role` key in frontend code.

---

## Remaining Limitations / Manual Steps

1. **Email confirmation**: Supabase sends confirmation emails. For internal-only use, disable this in Authentication → Settings.
2. **Quotation status change UI**: Currently status is stored but can only be changed by editing the quotation wizard (Step 1 doesn't have a status dropdown). You can change it directly in Supabase Table Editor if needed until a dedicated status-change button is added.
3. **Logo upload**: The `logo_url` field in `company_settings` accepts a URL. Direct file upload to Supabase Storage is not yet wired up — host the logo externally and paste the URL.
4. **Multi-user isolation**: Currently all authenticated users share all data. If you need per-user isolation, the RLS policies need `auth.uid()` filters added.
5. **Demo seed data**: The original demo data seeding is removed — start fresh by creating quotations after logging in.
