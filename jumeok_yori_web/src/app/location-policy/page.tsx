import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { getLegalHtml } from "@/lib/legalContent";

export const metadata: Metadata = { title: "위치정보 이용약관" };

export default function LocationPolicyPage() {
  return <LegalDocument html={getLegalHtml("location-policy")} />;
}
