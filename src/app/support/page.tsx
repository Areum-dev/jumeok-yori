import type { Metadata } from "next";
import { LegalDocument } from "@/components/LegalDocument";
import { getLegalHtml } from "@/lib/legalContent";
import { AppConfig } from "@/lib/config";

export const metadata: Metadata = { title: "고객지원" };

function mailto(subject: string) {
  return `mailto:${AppConfig.supportEmail}?subject=${encodeURIComponent(subject)}`;
}

const CONTACT_TYPES = [
  { label: "일반 문의", subject: "[주먹요리 문의] 일반 문의" },
  { label: "개인정보 관련 문의", subject: "[주먹요리 문의] 개인정보 문의" },
  { label: "계정 삭제 문의", subject: "[주먹요리 문의] 계정 삭제 문의" },
];

const FAQS = [
  {
    q: "위치 권한을 허용했는데 추천이 이상해요.",
    a: "브라우저 설정 또는 기기 설정에서 위치 권한이 허용되어 있는지 확인해주세요. 권한을 거부한 경우 기본 위치(강남역)를 기준으로 추천되며, 화면에서 기준 위치를 직접 선택할 수도 있습니다.",
  },
  {
    q: "로그인이 안 돼요.",
    a: "이메일과 비밀번호를 다시 확인해주세요. 회원가입 시 이메일 인증이 필요한 경우, 인증 메일함(스팸함 포함)을 확인해주세요. 비밀번호를 잊으셨다면 로그인 화면의 '비밀번호를 잊으셨나요?'를 이용해주세요.",
  },
  {
    q: "가게 등록은 어떻게 하나요?",
    a: "로그인 후 '사장님' 메뉴에서 가게 등록을 신청할 수 있습니다. 신청 후 관리자 검토를 거쳐 승인되면 지도와 추천 결과에 노출됩니다.",
  },
  {
    q: "메뉴 등록/수정이 반영되지 않아요.",
    a: "메뉴는 등록 또는 수정 후 승인 절차를 거칠 수 있습니다. 가게가 아직 승인되지 않았다면 메뉴도 노출되지 않습니다. 사장님 대시보드에서 승인 상태를 확인해주세요.",
  },
  {
    q: "계정을 삭제하고 싶어요.",
    a: "마이페이지 또는 /delete-account 페이지에서 본인 확인 후 직접 삭제할 수 있습니다. 로그인이 어려운 경우 이메일로 삭제를 요청할 수 있습니다.",
  },
];

export default function SupportPage() {
  return (
    <div className="mx-auto max-w-3xl px-4 py-12 sm:px-6">
      <h1 className="text-2xl font-black text-dark-ink sm:text-3xl">주먹요리 고객지원</h1>
      <p className="mt-3 text-sm text-text-gray">문의 유형에 맞는 버튼을 눌러 이메일로 문의해주세요.</p>

      <div className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-3">
        {CONTACT_TYPES.map((c) => (
          <a
            key={c.label}
            href={mailto(c.subject)}
            className="rounded-2xl border border-soft-gray bg-white p-5 text-center transition hover:border-orange"
          >
            <p className="text-sm font-bold text-dark-ink">{c.label}</p>
            <p className="mt-2 text-xs text-orange">메일 작성하기 →</p>
          </a>
        ))}
      </div>

      <p className="mt-4 text-sm text-text-gray">
        직접 메일을 작성하시려면{" "}
        <a href={`mailto:${AppConfig.supportEmail}`} className="font-semibold text-orange hover:underline">
          {AppConfig.supportEmail}
        </a>
        로 보내주세요.
      </p>

      <div className="mt-12">
        <h2 className="mb-4 text-lg font-extrabold text-dark-ink">자주 묻는 질문</h2>
        <div className="divide-y divide-soft-gray rounded-2xl border border-soft-gray bg-white">
          {FAQS.map((f) => (
            <details key={f.q} className="group p-5">
              <summary className="cursor-pointer list-none text-sm font-bold text-dark-ink marker:content-none">
                <span className="mr-2 text-orange">Q.</span>
                {f.q}
              </summary>
              <p className="mt-3 text-sm leading-relaxed text-text-gray">
                <span className="mr-2 font-bold text-mid-gray">A.</span>
                {f.a}
              </p>
            </details>
          ))}
        </div>
      </div>

      <div className="mt-12">
        <LegalDocument html={getLegalHtml("customer-support")} />
      </div>
    </div>
  );
}
