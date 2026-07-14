/**
 * 주먹요리 Supabase 스키마 타입 정의.
 * jumeok_yori(Flutter)/supabase/schema.sql, migrations.sql 을 기준으로 작성했습니다.
 * DB 컬럼명은 snake_case 그대로 유지합니다 (Flutter 앱과 동일 규약).
 */

export type UserRole = "user" | "owner" | "admin";
export type VerificationStatus = "pending" | "approved" | "rejected" | "suspended";
export type DisplayStatus = "hidden" | "approved" | "suspended";
export type ApprovalStatus = "pending" | "approved" | "rejected";
export type RecommendationType = "registered" | "starter";
export type ReportStatus = "pending" | "reviewed" | "resolved";

export interface Profile {
  id: string;
  email: string | null;
  display_name: string | null;
  role: UserRole;
  created_at: string;
  updated_at: string;
}

export interface Restaurant {
  id: string;
  owner_id: string | null;
  business_number: string | null;
  name: string;
  owner_name: string | null;
  phone: string | null;
  address: string | null;
  detail_address: string | null;
  lat: number | null;
  lng: number | null;
  image_url: string | null;
  category: string | null;
  description: string | null;
  opening_hours: string | null;
  is_takeout_available: boolean;
  is_delivery_available: boolean;
  source: string;
  verification_status: VerificationStatus;
  display_status: DisplayStatus;
  created_at: string;
  updated_at: string;
}

export interface OwnerStoreApplication {
  id: string;
  user_id: string | null;
  business_number: string;
  store_name: string;
  owner_name: string | null;
  phone: string | null;
  address: string | null;
  detail_address: string | null;
  category: string | null;
  description: string | null;
  opening_hours: string | null;
  is_takeout_available: boolean;
  is_delivery_available: boolean;
  business_license_image_url: string | null;
  lat: number | null;
  lng: number | null;
  geocoding_status: string | null;
  geocoding_error: string | null;
  status: VerificationStatus;
  admin_note: string | null;
  restaurant_id: string | null;
  created_at: string;
  reviewed_at: string | null;
}

export interface MenuItem {
  id: string;
  restaurant_id: string;
  owner_id: string | null;
  name: string;
  description: string | null;
  price: number;
  category: string | null;
  image_url: string | null;
  is_available: boolean;
  is_takeout_available: boolean;
  is_delivery_available: boolean;
  is_solo_friendly: boolean;
  is_vegan_option: boolean;
  spicy_level: number | null;
  source: string;
  approval_status: ApprovalStatus;
  display_status: DisplayStatus;
  created_at: string;
  updated_at: string;
}

export interface StarterMenu {
  id: string;
  name: string;
  description: string | null;
  category: string | null;
  expected_min_price: number | null;
  expected_max_price: number | null;
  image_url: string | null;
  is_solo_friendly: boolean;
  is_takeout_friendly: boolean;
  is_delivery_friendly: boolean;
  is_vegan_option: boolean;
  search_keyword: string | null;
  source: string;
  display_status: string;
  created_at: string;
  updated_at: string;
}

export interface RecommendationLog {
  id: string;
  user_id: string | null;
  anonymous_user_id: string | null;
  recommendation_type: RecommendationType;
  menu_item_id: string | null;
  starter_menu_id: string | null;
  restaurant_id: string | null;
  filters_json: Record<string, unknown> | null;
  user_lat: number | null;
  user_lng: number | null;
  created_at: string;
}

export interface SavedMenuItem {
  id: string;
  user_id: string;
  recommendation_type: RecommendationType;
  menu_item_id: string | null;
  starter_menu_id: string | null;
  created_at: string;
}

export interface Report {
  id: string;
  user_id: string | null;
  anonymous_user_id: string | null;
  recommendation_type: string | null;
  menu_item_id: string | null;
  starter_menu_id: string | null;
  restaurant_id: string | null;
  reason: string;
  detail: string | null;
  status: ReportStatus;
  created_at: string;
}

export interface AnalyticsEvent {
  id: string;
  user_id: string | null;
  anonymous_user_id: string | null;
  owner_id: string | null;
  restaurant_id: string | null;
  menu_item_id: string | null;
  starter_menu_id: string | null;
  recommendation_type: string | null;
  event_type: string;
  metadata: Record<string, unknown> | null;
  created_at: string;
}

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: Partial<Profile> & { id: string };
        Update: Partial<Profile>;
        Relationships: [];
      };
      restaurants: {
        Row: Restaurant;
        Insert: Partial<Restaurant> & { name: string };
        Update: Partial<Restaurant>;
        Relationships: [];
      };
      owner_store_applications: {
        Row: OwnerStoreApplication;
        Insert: Partial<OwnerStoreApplication> & { business_number: string; store_name: string };
        Update: Partial<OwnerStoreApplication>;
        Relationships: [];
      };
      menu_items: {
        Row: MenuItem;
        Insert: Partial<MenuItem> & { restaurant_id: string; name: string; price: number };
        Update: Partial<MenuItem>;
        Relationships: [];
      };
      starter_menus: {
        Row: StarterMenu;
        Insert: Partial<StarterMenu> & { name: string };
        Update: Partial<StarterMenu>;
        Relationships: [];
      };
      recommendation_logs: {
        Row: RecommendationLog;
        Insert: Partial<RecommendationLog> & { recommendation_type: RecommendationType };
        Update: Partial<RecommendationLog>;
        Relationships: [];
      };
      saved_menu_items: {
        Row: SavedMenuItem;
        Insert: Partial<SavedMenuItem> & { user_id: string; recommendation_type: RecommendationType };
        Update: Partial<SavedMenuItem>;
        Relationships: [];
      };
      reports: {
        Row: Report;
        Insert: Partial<Report> & { reason: string };
        Update: Partial<Report>;
        Relationships: [];
      };
      analytics_events: {
        Row: AnalyticsEvent;
        Insert: Partial<AnalyticsEvent> & { event_type: string };
        Update: Partial<AnalyticsEvent>;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
}

/** UI 런타임에서 사용하는 조인된 메뉴 아이템 (restaurant 포함) */
export interface MenuItemWithRestaurant extends MenuItem {
  restaurants: Restaurant | null;
}
