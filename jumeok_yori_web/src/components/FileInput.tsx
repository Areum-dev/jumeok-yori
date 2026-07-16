"use client";

import { useId, useState } from "react";

/**
 * 브라우저 기본 <input type="file"> 은 텍스트/버튼이 겹쳐 보이는 등 스타일링이
 * 어려워 커스텀 버튼 + 숨겨진 input 조합으로 대체한 컴포넌트.
 */
export function FileInput({
  label,
  onChange,
  accept = "image/*",
}: {
  label: string;
  onChange: (file: File | null) => void;
  accept?: string;
}) {
  const id = useId();
  const [fileName, setFileName] = useState<string | null>(null);

  return (
    <label htmlFor={id} className="block">
      <span className="mb-1.5 block text-sm font-semibold text-dark-ink">{label}</span>
      <div className="flex items-center gap-3 rounded-xl border border-dashed border-soft-gray bg-ivory px-4 py-3">
        <span className="shrink-0 rounded-lg bg-white px-3 py-1.5 text-xs font-bold text-dark-ink shadow-sm">
          파일 선택
        </span>
        <span className="truncate text-xs text-text-gray">{fileName ?? "선택된 파일 없음"}</span>
      </div>
      <input
        id={id}
        type="file"
        accept={accept}
        className="sr-only"
        onChange={(e) => {
          const file = e.target.files?.[0] ?? null;
          setFileName(file?.name ?? null);
          onChange(file);
        }}
      />
    </label>
  );
}
