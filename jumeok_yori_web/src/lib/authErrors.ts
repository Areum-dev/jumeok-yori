/** Supabase Auth 오류 메시지를 한글로 변환. jumeok_yori(Flutter) auth_service.dart 와 동일 매핑. */
export function toKoreanAuthError(message: string): string {
  const m = message.toLowerCase();
  if (m.includes("invalid login") || m.includes("invalid credentials")) {
    return "이메일 또는 비밀번호가 올바르지 않습니다.";
  }
  if (m.includes("already registered") || m.includes("already been registered")) {
    return "이미 가입된 이메일입니다.";
  }
  if (m.includes("password") && m.includes("6")) {
    return "비밀번호는 6자 이상이어야 합니다.";
  }
  if (m.includes("email") && m.includes("confirm")) {
    return "이메일 인증이 필요합니다. 메일함을 확인해주세요.";
  }
  if (m.includes("rate limit")) {
    return "잠시 후 다시 시도해주세요.";
  }
  return "인증 오류가 발생했습니다. 다시 시도해주세요.";
}
