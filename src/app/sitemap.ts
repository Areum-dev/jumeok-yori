import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
  const paths = [
    "",
    "/recommend",
    "/map",
    "/restaurants",
    "/owner",
    "/support",
    "/terms",
    "/privacy",
    "/delete-account",
    "/location-policy",
    "/marketing-consent",
    "/business-terms",
    "/community-guidelines",
    "/privacy/children",
    "/login",
    "/signup",
  ];
  return paths.map((path) => ({
    url: `${siteUrl}${path}`,
    lastModified: new Date(),
  }));
}
