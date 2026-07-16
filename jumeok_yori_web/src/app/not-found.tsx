import Link from "next/link";

export default function NotFound() {
  return (
    <div className="mx-auto flex min-h-[60vh] max-w-lg flex-col items-center justify-center px-4 text-center">
      <p className="text-6xl">🔍</p>
      <h1 className="mt-4 text-2xl font-black text-dark-ink">페이지를 찾을 수 없어요</h1>
      <p className="mt-2 text-sm text-text-gray">
        주소가 잘못되었거나 삭제된 페이지일 수 있어요.
      </p>
      <Link
        href="/"
        className="mt-6 rounded-full bg-orange px-6 py-3 text-sm font-bold text-white hover:opacity-90"
      >
        홈으로 가기
      </Link>
    </div>
  );
}
