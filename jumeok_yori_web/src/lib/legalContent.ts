import fs from "node:fs";
import path from "node:path";
import { marked } from "marked";

/** src/content/legal/*.md 파일을 읽어 HTML로 변환합니다 (서버 전용). */
export function getLegalHtml(slug: string): string {
  const filePath = path.join(process.cwd(), "src/content/legal", `${slug}.md`);
  const raw = fs.readFileSync(filePath, "utf-8");
  return marked.parse(raw, { async: false }) as string;
}
