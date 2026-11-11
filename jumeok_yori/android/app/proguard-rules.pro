# 릴리스 빌드 R8 규칙 (Flutter Gradle 플러그인이 이 파일이 있으면 자동으로 적용한다).

# ── Room / WorkManager ───────────────────────────────────────────────
# 광고 SDK(Google Mobile Ads)가 WorkManager 를 끌어오고, WorkManager 는 앱 시작 시
# (androidx.startup InitializationProvider) Room 이 생성한 WorkDatabase_Impl 을
# 리플렉션으로, 즉 "기본 생성자"를 통해 만든다.
#
# R8 full mode(AGP 8+ 기본값)에서는 `-keep class ...` 만으로는 기본 생성자가
# 보존되지 않는다. 그래서 1.4.0(26) 릴리스는 광고 SDK 추가 직후 앱이 시작되자마자
#   "Failed to create an instance of androidx.work.impl.WorkDatabase"
# 로 크래시해 아예 켜지지 않았다. 기본 생성자까지 명시적으로 보존한다.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
