import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { getLegalHtml } from "@/lib/legalContent";

export const metadata: Metadata = { title: "마케팅 정보 수신 동의" };

export default function MarketingConsentPage() {
  return <LegalDocument html={getLegalHtml("marketing")} />;
}
