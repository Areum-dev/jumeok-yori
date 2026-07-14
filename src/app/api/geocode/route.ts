import { NextResponse } from "next/server";

/**
 * 주소 → 좌표 변환 (Naver Geocoding API 프록시).
 * Client Secret 을 서버에만 보관하기 위해 브라우저가 직접 호출하지 않고 이 라우트를 거칩니다.
 * jumeok_yori(Flutter) naver_geocoding_service.dart 와 동일한 엔드포인트를 사용합니다.
 */
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get("query");
  if (!query) {
    return NextResponse.json({ success: false, error: "주소를 입력해주세요." }, { status: 400 });
  }

  const clientId = process.env.NEXT_PUBLIC_NAVER_MAP_CLIENT_ID;
  const clientSecret = process.env.NAVER_MAP_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    return NextResponse.json(
      { success: false, error: "지오코딩 API 키가 설정되지 않았습니다." },
      { status: 503 },
    );
  }

  try {
    const url = `https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=${encodeURIComponent(query)}`;
    const res = await fetch(url, {
      headers: {
        "X-NCP-APIGW-API-KEY-ID": clientId,
        "X-NCP-APIGW-API-KEY": clientSecret,
      },
      cache: "no-store",
    });

    if (!res.ok) {
      return NextResponse.json(
        { success: false, error: `지오코딩 API 오류 (${res.status})` },
        { status: 502 },
      );
    }

    const data = await res.json();
    const first = data?.addresses?.[0];
    if (!first) {
      return NextResponse.json({ success: false, error: "주소를 찾을 수 없어요." }, { status: 404 });
    }

    const lat = Number(first.y);
    const lng = Number(first.x);
    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      return NextResponse.json({ success: false, error: "좌표 변환에 실패했어요." }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      lat,
      lng,
      roadAddress: first.roadAddress ?? null,
      jibunAddress: first.jibunAddress ?? null,
    });
  } catch {
    return NextResponse.json({ success: false, error: "지오코딩 요청 중 오류가 발생했습니다." }, { status: 500 });
  }
}
