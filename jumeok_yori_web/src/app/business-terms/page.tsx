import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { getLegalHtml } from "@/lib/legalContent";

export const metadata: Metadata = { title: "사장님 이용약관" };

export default function BusinessTermsPage() {
  return <LegalDocument html={getLegalHtml("merchant-policy")} />;
}
