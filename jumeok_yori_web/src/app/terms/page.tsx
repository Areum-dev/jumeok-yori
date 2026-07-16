import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { getLegalHtml } from "@/lib/legalContent";

export const metadata: Metadata = { title: "이용약관" };

export default function TermsPage() {
  return <LegalDocument html={getLegalHtml("terms")} />;
}
