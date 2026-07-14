import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { getLegalHtml } from "@/lib/legalContent";

export const metadata: Metadata = { title: "커뮤니티 운영 정책" };

export default function CommunityGuidelinesPage() {
  return <LegalDocument html={getLegalHtml("community-policy")} />;
}
