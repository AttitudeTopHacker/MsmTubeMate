# Product Requirements Document (PRD)
## Project: Msm TubeMate
* **Application Name:** Msm TubeMate
* **Organization:** ORG: msm.movin 2022
* **Copyright Claim (Exact Required String):** `ORG: msm.movin 2022`
* **Target Platform:** Android Mobile Application (`.apk`)
* **Frontend Framework:** Flutter (Dart)
* **Backend & Extraction Engine:** Python (FastAPI + `yt-dlp` + `ffmpeg`)
* **Authentication & Cloud Database:** Supabase (PostgreSQL + Google OAuth Sign-In)

---

## 1. Product Overview & Vision
**Msm TubeMate** is an all-in-one media discovery, video/audio downloader, and WhatsApp status saver Android application. Inspired functionally by comprehensive media downloaders (supporting multi-format audio/video extraction, batch playlist downloads, in-app sharing intents, and offline vault management), **Msm TubeMate** differentiates itself through a **next-generation Frosted Glassmorphism UI**, cloud-synced history via **Supabase**, seamless **Google Sign-In**, and a high-speed **Python FastAPI** media extraction backend.

### 1.1 Mandatory Branding & Copyright Rules
* The official app name displayed in the launcher, splash screen, headers, and share sheets MUST be **Msm TubeMate**.
* The organization and copyright string **`ORG: msm.movin 2022`** MUST remain exact (case-sensitive and spacing-identical) and be visibly rendered in:
  1. Splash Screen bottom footer
  2. Login / Google Sign-In screen footer
  3. Settings & About screen legal section
  4. Navigation Drawer / Profile header subtitle

---

## 2. UI/UX Design System (Frosted Glassmorphism)
**CRITICAL DESIGN RULE:** Do **NOT** copy Snaptube's flat black-and-yellow theme. Implement a translucent, layered **Frosted Glassmorphism** aesthetic.

### 2.1 Color Palette & Ambient Canvas
* **Base Canvas Background:** Deep Midnight Mesh Gradient (`#090D16` $\rightarrow$ `#111827` $\rightarrow$ `#1E1B4B`) with subtle, soft-blurred ambient radial orbs in Electric Cyan (`#00F5D4`), Neon Violet (`#7B2CBF`), and Azure Blue (`#3A86FF`).
* **Primary Glass Surface:** `Colors.white.withOpacity(0.08)` with `BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18))`.
* **Elevated Modal / Sheet Glass Surface:** `Color(0xFF131A2B).withOpacity(0.75)` with `sigmaX: 24, sigmaY: 24` blur.
* **Glass Border:** `1.0px` solid gradient stroke (`Colors.white.withOpacity(0.22)` top-left to `Colors.white.withOpacity(0.05)` bottom-right).
* **Primary Accent Color:** Cyan-Blue Gradient (`#00F5D4` $\rightarrow$ `#3A86FF`) for active tabs, download triggers, and progress bars.
* **Typography:** `Plus Jakarta Sans` or `Outfit` (Clean, modern geometric sans-serif; `#F8FAFC` primary text, `#94A3B8` secondary metadata).

### 2.2 Navigation Architecture
* **Floating Glass Bottom Navigation Bar:** Pill-shaped translucent dock floating `16px` above the bottom safe area with 3 core destinations:
  1. **Explore (Search & Discover)**
  2. **Downloads (Active & Offline Media)**
  3. **Tools (Status Saver, Vault & Utilities)**

---

## 3. System Architecture & Tech Stack

### 3.1 Architecture Flow
```text
[Flutter Android App]
       │
       ├──► [Supabase Auth & PostgreSQL] (Google Sign-In, User Profile, Cloud Download History, Bookmarks)
       │
       ├──► [Python FastAPI Server] (Search Query, Metadata Extraction, Stream URLs, Audio/Video Muxing)
       │
       └──► [Android Native Layer] (SAF WhatsApp Status Reader, Share Intent Receiver, Encrypted PIN Vault, Local Storage)
```

### 3.2 Recommended Flutter Packages
* `supabase_flutter` & `google_sign_in` (Authentication & Database)
* `dio` & `flutter_downloader` (Chunked background file downloads with notification progress)
* `receive_sharing_intent` (Receive "Share" links directly from YouTube, Instagram, X, Facebook)
* `just_audio` & `video_player` / `chewie` (Built-in offline audio/video player)
* `permission_handler` & `saf` / `file_picker` (Android 11–15 Scoped Storage & WhatsApp `.Statuses` access)
* `flutter_secure_storage` & `local_auth` (PIN & Biometric protection for Private Vault)
* `flutter_riverpod` (State management)

---

## 4. Detailed Functional Requirements

### 4.1 Authentication & Cloud Sync (Supabase + Google Sign-In)
* **Google Sign-In Flow:**
  * Users sign in using native Google OAuth (`google_sign_in`) linked to Supabase Auth (`supabase.auth.signInWithIdToken`).
  * Option for "Skip / Guest Mode" (local-only mode) while prompting Google Sign-In to sync download history and bookmarks across devices.
* **Supabase Database Schema (PostgreSQL):**
  ```sql
  -- 1. User Profiles
  create table public.profiles (
    id uuid references auth.users on delete cascade primary key,
    email text,
    full_name text,
    avatar_url text,
    updated_at timestamp with time zone default timezone('utc'::text, now())
  );

  -- 2. Cloud Download History
  create table public.download_history (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users on delete cascade not null,
    title text not null,
    platform text not null, -- 'YouTube', 'Instagram', 'Facebook', 'X', 'WhatsApp'
    media_type text not null, -- 'audio' or 'video'
    format_label text not null, -- e.g., '1080p MP4', '320K MP3'
    file_size text,
    thumbnail_url text,
    source_url text not null,
    created_at timestamp with time zone default timezone('utc'::text, now())
  );

  -- 3. Custom Saved Sites / Bookmarks
  create table public.saved_sites (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references auth.users on delete cascade not null,
    site_name text not null,
    site_url text not null,
    icon_name text,
    created_at timestamp with time zone default timezone('utc'::text, now())
  );

  -- Enable Row Level Security (RLS)
  alter table public.profiles enable row level security;
  alter table public.download_history enable row level security;
  alter table public.saved_sites enable row level security;

  create policy "Users manage own profile" on public.profiles for all using (auth.uid() = id);
  create policy "Users manage own history" on public.download_history for all using (auth.uid() = user_id);
  create policy "Users manage own sites" on public.saved_sites for all using (auth.uid() = user_id);
  ```

---

### 4.2 Python Backend API Specification (FastAPI + `yt-dlp`)
Build a Python FastAPI backend (`main.py`) with CORS enabled to handle search, link parsing, and stream extraction.

* **Endpoint 1: `GET /api/search?q={query}&limit=20`**
  * Uses `yt-dlp` (`ytsearch20:{query}`) to fetch video metadata without downloading: `id`, `title`, `channel`, `duration`, `view_count`, `thumbnail`, `webpage_url`.
* **Endpoint 2: `POST /api/extract`**
  * **Request Body:** `{ "url": "https://..." }`
  * **Supported Platforms:** YouTube (Videos, Shorts, Music, Playlists), Instagram (Reels, Posts, Stories), Facebook Videos, Twitter/X Media.
  * **Response Structure:**
    * Basic metadata (`title`, `thumbnail`, `duration`, `uploader`, `is_playlist`).
    * If `is_playlist == true`: Returns list of playlist items (`index`, `title`, `duration`, `thumbnail`, `url`) for batch selection.
    * **Categorized Formats Array** (matching multi-tier quality selection):
      * **Music / Audio Formats:**
        * `Fast M4A (128K)` — Best for mobile play (with estimated MB size)
        * `Classic MP3 (70K)` — Low data mode
        * `Classic MP3 (128K)` — Standard compatibility
        * `Classic MP3 (160K)` — Balanced quality
        * `Classic MP3 (320K)` — High fidelity audio
      * **Video Formats:**
        * `144p` (Data Saver)
        * `240p` (Low Quality)
        * `360p` (Standard Quick Play)
        * `480p` (SD Quality)
        * `720p HD` (High Definition)
        * `1080p Full HD` (High Details)
* **Endpoint 3: `GET /api/download-stream`**
  * Streams or merges high-definition video + audio (`ffmpeg`) on the fly and serves direct downloadable bytes with `Content-Length` header so Flutter displays accurate progress `%` and download speed.

---

### 4.3 Screen-by-Screen Feature Breakdown

#### Screen 1: Splash & Auth Screen
* Centered glowing glass emblem for **Msm TubeMate**.
* One-tap **Sign in with Google** glass button + **Continue as Guest** link.
* Bottom fixed footer: `ORG: msm.movin 2022`.

#### Screen 2: Explore Tab (Home, Search & Platforms)
* **Top Glass Search Bar:**
  * Accepts keywords OR direct pasted URLs.
  * Auto-detects URLs copied to clipboard and shows a floating glass banner: *"Link detected! Tap to Download"*.
  * Real-time search autocomplete suggestions (`song`, `trending`, etc.) and search history with clear-history button.
* **Sub-Navigation Glass Chips:**
  * `Discover` | `Trending Videos` | `Music Mixes` | `Sites`
* **Quick Sites Grid (Glass Cards):**
  * Pre-configured shortcuts: **YouTube**, **Instagram**, **WhatsApp Status**, **Twitter/X**, **Facebook**, plus a `+ Add Site` glass button to bookmark custom URLs (synced with Supabase `saved_sites`).
* **Platform "How to Download" Interactive Guide:**
  * Step-by-step visual glass cards showing users how to tap **Share $\rightarrow$ More $\rightarrow$ Msm TubeMate** from external apps.

#### Screen 3: Format Selection Glass Bottom Sheet (Core Download Trigger)
* Triggered whenever a user taps the download icon on any search card, pastes a URL, or shares a link from an external app.
* Displays media thumbnail, title, and two clean glass sections:
  * **Music Section:** `Fast (M4A 128K)`, `Classic MP3 (128K)` + **`More formats >`** expandable drawer revealing `70K`, `160K`, and `320K MP3` with exact file sizes (e.g., `12.9 MB`, `24.2 MB`, `50.4 MB`).
  * **Video Section:** `Fast (360p)`, `High Quality (720p)` + **`More formats >`** expandable drawer revealing `144p`, `240p`, `480p`, and `1080p` with exact file sizes.
* **Playlist Batch Selector Screen:**
  * When a playlist link or music album is opened, displays a **"Select All"** toggle and individual checkboxes next to each track, with a floating glass CTA button: **`Download (N)`**.

#### Screen 4: Downloads & Built-in Media Player Tab
* **Segmented Glass Toggle:** `Downloading (Active)` | `Downloaded (Completed)`
* **Active Queue:** Shows live progress bar, download speed (`MB/s`), pause/resume, and cancel controls.
* **Offline Library:** Filterable by `All`, `Video`, `Music`. Tapping any item opens the built-in glass Audio/Video player (with background audio playback support).
* Automatically logs completed downloads to Supabase `download_history` when signed in.

#### Screen 5: Tools, WhatsApp Status Saver & Vault Tab
* **Storage & Cache Glass Overview Cards:**
  * Displays App Cache size with one-tap **Clean Cache** button and Device Available Storage indicator.
* **WhatsApp Status Saver:**
  * Uses Android Storage Access Framework (SAF) to read WhatsApp & WhatsApp Business `.Statuses` folder.
  * Grid view of recent Image & Video statuses with full-screen preview and one-tap **Save to Gallery** button.
* **Private PIN Vault:**
  * 4-digit PIN / Fingerprint locked glass container. Users can move sensitive downloaded videos/audios into the Vault, hiding them from public phone galleries.
* **Settings & Legal Info:**
  * Connected Google Account profile card (Sign Out / Sync Now).
  * Default Download Path & Quality preferences.
  * Language selector & Share App button.
  * **About Section:** Displays App Version, Developer Info, and exact copyright string: **`ORG: msm.movin 2022`**.

---

## 5. Android Manifest & Build Configuration
* **Application ID / Package Name:** `com.msmmovin.tubemate`
* **App Label (`AndroidManifest.xml`):** `Msm TubeMate`
* **Intent Filters (`AndroidManifest.xml`):**
  * Register `android.intent.action.SEND` for `text/plain` so **Msm TubeMate** appears in the Android system Share sheet for URLs.
* **Permissions:**
  * `INTERNET`, `ACCESS_NETWORK_STATE`
  * `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`, `READ_MEDIA_IMAGES` (Android 13+)
  * `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` (Android 12 and below)
  * `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS` (Background downloads)
  * `USE_BIOMETRIC` (Vault unlock)

---

## 6. Agent Implementation Roadmap (Execution Order)
1. **Step 1 — Python Backend (`/backend`):** Create `main.py` with FastAPI, `yt-dlp`, and `requirements.txt` implementing `/api/search`, `/api/extract`, and `/api/download-stream`.
2. **Step 2 — Supabase Setup (`/supabase`):** Generate `schema.sql` with tables, triggers for `profiles`, and RLS policies.
3. **Step 3 — Flutter Design System (`/lib/theme`):** Build `GlassContainer`, `AmbientBackground`, `GlassBottomNav`, and typography constants enforcing `ORG: msm.movin 2022`.
4. **Step 4 — Auth & State (`/lib/features/auth`):** Implement Google Sign-In + Supabase session persistence.
5. **Step 5 — Core Media & Download Engine (`/lib/features/downloader`):** Build Search, URL parser, Format Selection Bottom Sheet, Playlist Batch Selector, and `dio` background downloader.
6. **Step 6 — Native Tools (`/lib/features/tools`):** Implement Share Intent listener, WhatsApp Status Saver (SAF), PIN Vault, and Offline Media Player.
7. **Step 7 — Final QA & APK Build:** Verify all screens display `Msm TubeMate` and `ORG: msm.movin 2022` accurately, and run `flutter build apk --release`.