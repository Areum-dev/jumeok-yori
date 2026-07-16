export function LegalDocument({ html }: { html: string }) {
  return (
    <div className="mx-auto max-w-3xl px-4 py-12 sm:px-6">
      <div
        className="legal-content"
        // 콘텐츠는 저장소 내 신뢰된 마크다운 파일(src/content/legal)에서만 생성됩니다.
        dangerouslySetInnerHTML={{ __html: html }}
      />
    </div>
  );
}
