# Pantry

A Swift iOS app for managing pantry ingredients and meal planning, powered by Supabase.

## Setup

### 1. Configure Supabase Credentials

Copy the configuration template:
```bash
cp Config.xcconfig.template Config.xcconfig
```

Edit `Config.xcconfig` and replace the placeholder values with your actual Supabase credentials:
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

**Note:** `Config.xcconfig` is gitignored to keep your credentials secure.

### 2. Install Dependencies

Open `Pantry-UI/Pantry-UI.xcodeproj` in Xcode and let Swift Package Manager install the dependencies.

### 3. Setup Supabase Backend (Optional for local development)

```bash
cd supabase
supabase start
```

## Project Structure

- `Pantry-UI/` - iOS Swift app
- `supabase/` - Supabase configuration, migrations, and edge functions
# Pantry
