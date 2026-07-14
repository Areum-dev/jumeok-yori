import { createBrowserClient } from "@supabase/ssr";

/**
 * 브라우저(클라이언트 컴포넌트)에서 사용하는 Supabase 클라이언트.
 * Flutter 앱과 동일한 Supabase 프로젝트(anon/publishable key)를 사용합니다.
 *
 * 참고: @supabase/supabase-js 최신 버전의 Database 제네릭 타입 추론이
 * 불안정하여(테이블 Update 파라미터가 never 로 좁혀지는 이슈) 제네릭을 붙이지 않고,
 * 각 호출부에서 src/types/database.ts 의 타입으로 명시적으로 캐스팅합니다.
 */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
