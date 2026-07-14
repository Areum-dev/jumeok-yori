import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { MenuItem, Restaurant, Profile } from "@/types/database";
import { OwnerStoreDashboard } from "@/components/OwnerStoreDashboard";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function OwnerStorePage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: restaurant } = await supabase.from("restaurants").select("*").eq("id", id).maybeSingle();
  if (!restaurant) notFound();

  const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).maybeSingle();
  const isAdmin = (profile as Profile | null)?.role === "admin";

  if ((restaurant as Restaurant).owner_id !== user.id && !isAdmin) {
    redirect("/owner");
  }

  const { data: menus } = await supabase
    .from("menu_items")
    .select("*")
    .eq("restaurant_id", id)
    .order("created_at", { ascending: false });

  return (
    <OwnerStoreDashboard
      restaurant={restaurant as Restaurant}
      initialMenus={(menus as MenuItem[]) ?? []}
      ownerId={user.id}
    />
  );
}
