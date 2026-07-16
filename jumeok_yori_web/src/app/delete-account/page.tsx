import type { Metadata } from "next";
import { DeleteAccountAction } from "@/components/DeleteAccountAction";
import { LegalDocument } from "@/components/LegalDocument";
import { getLegalHtml } from "@/lib/legalContent";
import { AppConfig } from "@/lib/config";

export const metadata: Metadata = { title: "주먹요리 계정 삭제 요청" };

const mailtoHref = `mailto:${AppConfig.supportEmail}?subject=${encodeURIComponent(
  "주먹요리 계정 삭제 요청",
)}&body=${encodeURIComponent(
  "가입한 이메일 주소: (여기에 가입 시 사용한 이메일을 입력해주세요)\n삭제 요청 사유(선택):\n\n본인 확인을 위해 가입 이메일과 동일한 주소로 문의해주시면 처리가 빠릅니다.",
)}`;

export default function DeleteAccountPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 py-12 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">주먹요리 계정 삭제 요청</h1>
      <p className="mt-3 text-sm leading-relaxed text-text-gray">
        이 페이지는 계정을 <strong className="text-dark-ink">일시 비활성화</strong>하는 것이 아니라{" "}
        <strong className="text-error">실제로 영구 삭제</strong>하는 절차를 안내합니다. 삭제 후에는 복구가
        불가능합니다.
      </p>

      <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2">
        <div className="rounded-2xl border border-soft-gray bg-white p-6">
          <h2 className="text-base font-bold text-dark-ink">방법 1. 웹에서 직접 삭제</h2>
          <p className="mt-2 text-sm text-text-gray">로그인 후 아래에서 본인 확인 절차를 거쳐 바로 삭제할 수 있습니다.</p>
        </div>
        <div className="rounded-2xl border border-soft-gray bg-white p-6">
          <h2 className="text-base font-bold text-dark-ink">방법 2. 모바일 앱에서 삭제</h2>
          <p className="mt-2 text-sm text-text-gray">
            주먹요리 앱 &gt; 마이페이지 &gt; 설정 &gt; 회원탈퇴 메뉴에서도 동일하게 삭제할 수 있습니다.
          </p>
        </div>
      </div>

      <div className="mt-6 rounded-2xl border border-soft-gray bg-white p-6">
        <h2 className="text-base font-bold text-dark-ink">방법 3. 이메일로 삭제 요청</h2>
        <p className="mt-2 text-sm leading-relaxed text-text-gray">
          로그인이 어려운 경우 아래 버튼으로 삭제 요청 메일을 보내주세요. 가입 시 사용한 이메일 주소를
          본문에 반드시 기재해주시면 본인 확인 후 처리해드립니다.
        </p>
        <a
          href={mailtoHref}
          className="mt-4 inline-flex items-center gap-2 rounded-full bg-orange px-6 py-3 text-sm font-bold text-white hover:opacity-90"
        >
          ✉️ 계정 삭제 요청 메일 보내기 ({AppConfig.supportEmail})
        </a>
        <p className="mt-3 text-xs text-mid-gray">이메일 요청은 접수 확인 후 영업일 기준 10일 이내에 처리됩니다.</p>
      </div>

      <div className="mt-8">
        <h2 className="mb-3 text-lg font-extrabold text-dark-ink">지금 바로 웹에서 삭제하기</h2>
        <DeleteAccountAction />
      </div>

      <div className="mt-12">
        <LegalDocument html={getLegalHtml("withdrawal")} />
      </div>
    </div>
  );
}
