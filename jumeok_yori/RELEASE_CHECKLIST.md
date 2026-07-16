# 주먹요리 출시 체크리스트

## Supabase 설정
- [ ] schema.sql 실행
- [ ] seed.sql 실행  
- [ ] storage.sql 실행
- [ ] Auth → Email Provider → "Confirm email" ON
- [ ] SMTP 설정 (Resend 추천: smtp.resend.com)
- [ ] 관리자 계정 생성 (1vpsrnls@gmail.com)
- [ ] profiles 테이블에서 해당 유저 role = 'admin' 설정

## Android 출시 준비
- [ ] 서명 키스토어 생성 (keytool 사용)
- [ ] android/key.properties 파일 생성 (Git 제외)
- [ ] build.gradle에 signingConfigs 설정
- [ ] flutter build appbundle --release 실행
- [ ] Google Play Console에 앱 등록

### 서명 키스토어 생성 명령어
```
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### android/key.properties 내용 (절대 Git에 올리지 말 것)
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

## Google Play Console 입력 정보
- 앱 이름: 주먹요리
- 짧은 설명: 고민 끝. 오늘은 이거. 조건만 정하면 메뉴를 골라주는 앱
- 자세한 설명: 매일 반복되는 점심/저녁 고민, 이제 주먹요리에게 맡겨보세요. 거리, 가격, 카테고리만 정하면 오늘의 메뉴를 골라드립니다.
- 카테고리: 음식 및 음료 / 라이프스타일
- 콘텐츠 등급: 전체이용가

## 개인정보 수집 항목 (Data Safety)
수집 데이터:
- 이메일 주소 (회원 가입/인증)
- 위치 정보 (위치 기반 메뉴 추천)
- 추천 기록 (맞춤 추천 개선)
- 저장한 메뉴 (개인화)
- 가게 등록 정보, 사업자등록번호, 사업자등록증 이미지 (사장님 기능)
- 메뉴 사진 (사장님 기능)
- 신고 내용 (서비스 개선)

사용 목적:
- 회원 관리
- 위치 기반 메뉴 추천
- 사장님 가게/메뉴 등록
- 관리자 승인
- 신고 처리

공유 여부:
- 제3자 공유 없음
- 결제/배달 기능 없음

## 개인정보처리방침
- [ ] 개인정보처리방침 페이지 필요 (URL 필요)
- [ ] 약관 페이지 필요 (URL 필요)

## 앱 아이콘
- [x] assets/images/logo-square.png 파일 배치 (2026-07-14 교체됨, 웹(jumeok_yori_web)과 동일 로고 사용)
- [ ] flutter pub run flutter_launcher_icons 실행

## 출시 전 최종 확인
- [ ] .env 파일 Git에 올라가지 않음
- [ ] key.properties Git에 올라가지 않음
- [ ] 관리자 비밀번호 코드에 없음
- [ ] API 키 코드에 없음
- [ ] starter_menu에 가짜 식당 정보 없음
- [ ] 미승인 가게/메뉴 추천 안 됨
- [ ] flutter analyze 0 issues
- [ ] release build 성공
