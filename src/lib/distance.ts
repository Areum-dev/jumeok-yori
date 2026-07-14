/** Haversine 공식으로 두 좌표 간 거리 계산 (km). jumeok_yori distance_service.dart 와 동일 로직. */
export function calculateKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const r = 6371.0;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return r * c;
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

export function formatDistance(km: number): string {
  if (km < 1.0) return `${Math.round(km * 1000)}m`;
  return `${km.toFixed(1)}km`;
}

export function walkingMinutes(km: number): number {
  return Math.round((km / 4.0) * 60);
}
