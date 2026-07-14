import type { SupabaseClient } from "@supabase/supabase-js";

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];
const MAX_SIZE_BYTES = 5 * 1024 * 1024; // 5MB

export function validateImageFile(file: File): string | null {
  if (!ALLOWED_TYPES.includes(file.type)) {
    return "jpg, png, webp, gif 형식의 이미지만 업로드할 수 있습니다.";
  }
  if (file.size > MAX_SIZE_BYTES) {
    return "이미지 크기는 5MB 이하여야 합니다.";
  }
  return null;
}

/**
 * Supabase Storage 에 이미지를 업로드합니다.
 * 파일명은 `${userId}/${crypto.randomUUID()}.${ext}` 형태로 사용자별 경로에 저장해
 * 다른 사용자의 파일과 충돌/덮어쓰기를 방지합니다.
 */
export async function uploadImage(
  supabase: SupabaseClient,
  bucket: "menu-images" | "business-licenses",
  userId: string,
  file: File,
): Promise<{ url: string | null; error: string | null }> {
  const validationError = validateImageFile(file);
  if (validationError) return { url: null, error: validationError };

  const ext = file.name.split(".").pop()?.toLowerCase() || "jpg";
  const path = `${userId}/${crypto.randomUUID()}.${ext}`;

  const { error: uploadError } = await supabase.storage.from(bucket).upload(path, file, {
    contentType: file.type,
    upsert: false,
  });

  if (uploadError) {
    return { url: null, error: `이미지 업로드에 실패했습니다: ${uploadError.message}` };
  }

  if (bucket === "menu-images") {
    const { data } = supabase.storage.from(bucket).getPublicUrl(path);
    return { url: data.publicUrl, error: null };
  }

  const { data, error } = await supabase.storage.from(bucket).createSignedUrl(path, 60 * 60 * 24 * 365);
  if (error || !data) {
    return { url: null, error: "비공개 이미지 URL 생성에 실패했습니다." };
  }
  return { url: data.signedUrl, error: null };
}
