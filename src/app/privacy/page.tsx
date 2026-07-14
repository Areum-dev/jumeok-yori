import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { getLegalHtml } from "@/lib/legalContent";

export const metadata: Metadata = { title: "개인정보처리방침" };

export default function PrivacyPage() {
  return <LegalDocument html={getLegalHtml("privacy")} />;
}
