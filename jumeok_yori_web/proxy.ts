import { type NextRequest } from "next/server";
import { updateSession } from "@/lib/supabase/middleware";

// Next.js 16: `middleware.ts` 는 `proxy.ts` 로 대체되었습니다.
export async function proxy(request: NextRequest) {
  return await updateSession(request);
}

export const config = {
  matcher: [
    /*
     * 다음을 제외한 모든 요청 경로에 매치:
     * - _next/static, _next/image (정적 파일)
     * - favicon.ico
     * - app-ads.txt (AdMob 앱 인증 크롤러가 로그인/세션 처리 없이 그대로 읽어야 함)
     * - 이미지 파일 확장자
     */
    "/((?!_next/static|_next/image|favicon.ico|app-ads\\.txt|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
