create table public.ingredients (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text not null,
  category text, 
  quantity text, 
  is_available boolean default true
);

create table public.meal_plans (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  recipe text not null,
  missing_ingredients text[]
);