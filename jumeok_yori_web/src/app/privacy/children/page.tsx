import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { getLegalHtml } from "@/lib/legalContent";

export const metadata: Metadata = { title: "청소년 보호 정책" };

export default function PrivacyChildrenPage() {
  return <LegalDocument html={getLegalHtml("youth-protection")} />;
}
