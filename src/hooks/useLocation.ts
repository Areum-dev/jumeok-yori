"use client";

import { useCallback, useEffect, useState } from "react";
import { AppConfig } from "@/lib/config";
import { getSavedLocation, saveLocation as persistLocation } from "@/lib/localUser";

export interface LocationState {
  lat: number;
  lng: number;
  label: string;
  isDefault: boolean;
}

const DEFAULT_STATE: LocationState = {
  lat: AppConfig.defaultLat,
  lng: AppConfig.defaultLng,
  label: `${AppConfig.defaultLocationLabel} (기본)`,
  isDefault: true,
};

/**
 * 위치 상태 관리 훅.
 * - 사용자가 직접 지정한 "저장 위치"가 있으면 우선 사용
 * - 없으면 기본 위치(강남역)로 시작하고, 사용자가 명시적으로 요청할 때만 GPS 를 조회
 */
export function useLocation() {
  const [location, setLocation] = useState<LocationState>(DEFAULT_STATE);
  const [requesting, setRequesting] = useState(false);
  const [permissionError, setPermissionError] = useState<string | null>(null);

  useEffect(() => {
    // 서버/클라이언트 첫 렌더는 항상 DEFAULT_STATE 로 맞춰 하이드레이션 불일치를 피하고,
    // 마운트 후에만 localStorage 의 저장 위치를 반영합니다.
    const saved = getSavedLocation();
    if (saved) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setLocation({ ...saved, isDefault: false });
    }
  }, []);

  const requestBrowserLocation = useCallback(() => {
    setPermissionError(null);
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setPermissionError("이 브라우저는 위치 서비스를 지원하지 않습니다.");
      return;
    }
    setRequesting(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLocation({
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
          label: "현재 위치",
          isDefault: false,
        });
        setRequesting(false);
      },
      (err) => {
        setRequesting(false);
        if (err.code === err.PERMISSION_DENIED) {
          setPermissionError("위치 권한이 거부되었습니다. 기준 위치를 직접 선택해주세요.");
        } else {
          setPermissionError("위치를 가져오지 못했습니다. 기준 위치를 직접 선택해주세요.");
        }
      },
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 60_000 },
    );
  }, []);

  const setManualLocation = useCallback((lat: number, lng: number, label: string, persist: boolean) => {
    setLocation({ lat, lng, label, isDefault: false });
    if (persist) persistLocation(lat, lng, label);
  }, []);

  const resetToDefault = useCallback(() => {
    setLocation(DEFAULT_STATE);
  }, []);

  return { location, requesting, permissionError, requestBrowserLocation, setManualLocation, resetToDefault };
}
