# Space Exploration Mission Design Study

우주탐사임무 설계 과목의 개념을 MATLAB으로 계산하고 비교하는 학습 프로젝트입니다. 원궤도 전파, 지상 가시성, 관측 후 접속 대기시간, 식 조건, Walker-Delta 위성군을 다룹니다.

## 실행 환경

- MATLAB R2025b에서 확인했습니다.
- 기본 OrbitLab 앱과 관측 분석: 추가 Toolbox 없이 실행.
- 3D 뷰어, 그림자·Walker 실습: Aerospace Toolbox 필요.
- 공식 `eclipse` 실습: Aerospace Ephemeris Data 추가 설치 필요.
- AI 결과 해석: 선택 기능. OpenAI API 키와 별도 API 이용 요금이 필요합니다.

## 시작

저장소를 내려받고 MATLAB 현재 폴더를 저장소 루트로 설정합니다.

```matlab
app = launch_mission_designer;
```

**분석 실행**을 누르면 기본 600 km / 55° / 3기 시나리오를 계산합니다. 관심 지점은 서울·부산·제주, 지상국은 대전이며 분석 기간은 3일, 시간 간격은 20초입니다.

- 지도·타임라인에서 위성 궤적과 센서 범위를 확인합니다.
- 관측 성능·전달 대기 탭에서 지점별 공백과 접속 대기를 확인합니다.
- 비교 후보를 추가한 뒤 고도·경사각·위성 수 등을 바꿔 비교합니다.
- 내보내기는 CSV, MAT, PNG와 설정을 저장합니다.

## 실습 순서

| 주제 | 실행 | 확인할 내용 |
|---|---|---|
| 원궤도·관측·접속 | `run_demo` | 1/3/6기 비교와 원격 지상국 접속 대기 |
| 시간 간격 수렴 | `run_convergence` | 20/10/5초 표본에 따른 관측 공백 차이 |
| 그림자 기하 | `run_shadow_geometry_demo` | 고정 태양의 원통·유한 원반 그림자 비교 |
| 공식 식·낮 조건 | `run_lighting_demo` | Toolbox eclipse 모델과 지상 낮 조건 |
| Walker-Delta | `run_walker_demo(true,true)` | 24기·3면, F=0/1/2 비교와 3D 뷰어 |
| 실제 TLE·지상국 | `run_tle_demo` 또는 앱의 실제 위성 · TLE 탭 | 국제캠퍼스 기준 24시간 패스 시간표와 하늘 경로 |

실행 결과는 `results/`에 생성되며 Git으로 관리하지 않습니다. 예제를 다시 실행하면 같은 이름의 결과를 갱신합니다. 기본 관측 사례는 지점과 지상국이 가까워 접속 대기가 0일 수 있습니다. `run_demo`의 Perth 사례로 원격 지상국 조건을 확인할 수 있습니다.

## 코드 읽는 순서

처음 TLE를 공부한다면 앱의 **실제 위성 · TLE → 단계별 실습** 또는 `edit study_tle`로 시작합니다. 구역별로 예상 질문 → 계산 → 확인을 진행하고, 최소 고각·시간 간격 실험은 직접 활성화합니다.

1. `+mission/defaultConfig.m`, `validateConfig.m`: 입력 조건과 단위.
2. `+mission/propagate.m`: 원궤도·평균 J2 전파, ECI→ECEF 변환.
3. `+mission/geometry.m`: 최소 고각, nadir 센서 FOV.
4. `+mission/intervals.m`, `nextContact.m`: 관측 구간과 같은 위성의 다음 접속.
5. `+mission/analyze.m`: 지점별 요약과 관측 이벤트.
6. `+mission/walkerScenario.m`, `analyzeWalker.m`: Toolbox 위성군·가시성·지역 좌표 검산.
7. `MissionDesignerApp.m`: 계산 모듈과 UI 연결.

`Contents.m`에는 실행 함수 목록이 있습니다. `assets/`는 지도 표시용 해안선, `tests/`는 수치·경계·API 구성 테스트입니다.

## 학습 노트

- [계산 가정과 결과 열](STUDY_NOTES.md)
- [Lighting / Eclipse](LIGHTING_STUDY.md)
- [Walker-Delta와 Toolbox 함수별 역할](WALKER_STUDY.md)
- [실제 위성 TLE·학교 지상국 패스 예측](TLE_STUDY.md)
- [AI 결과 해석 설정](AI_SETUP.md)
- [검증 범위](VALIDATION.md)

AI 기능은 계산된 요약과 근거를 외부 API에 전달해 설명하는 보조 기능입니다. API 키는 현재 MATLAB 세션에서 등록하며 저장소에 넣지 않습니다. 실행할 분석을 직접 고른 뒤 근거 미리보기로 전송 내용을 확인할 수 있습니다.

## 테스트

기본 계산과 API 구성 테스트는 결과 파일이나 API 키 없이 실행합니다.

```matlab
addpath(pwd);
t = runtests({'tests/test_mission.m','tests/test_ai.m'});
assertSuccess(t);
```

Aerospace Toolbox가 있으면 Walker 테스트도 실행합니다. 테스트 안에서 시나리오를 생성하므로 기존 MAT 파일은 필요하지 않습니다.

```matlab
t = runtests({'tests/test_walker.m','tests/test_tle.m'});
assertSuccess(t);
```

UI 확인은 `addpath('tests'); smoke_app;`으로 실행합니다. 식 결과 전환까지 확인하는 `smoke_ai`는 먼저 `run_shadow_geometry_demo(false)`로 결과를 준비합니다. 테스트는 유료 API를 호출하지 않습니다.

## 모델의 범위

기본 앱은 구형 지구·원궤도·고정 nadir 센서를 사용합니다. 지상 접속 대기는 **전송 완료시간이 아니며**, 미확인 접속은 0이 아닌 NaN으로 남깁니다. 관측 공백에는 분석 시작·종료 경계가 포함됩니다.

Walker 실습은 타원체 기반 지상 좌표와 Toolbox의 이상적인 두 물체 궤도를 사용합니다. 실제 Galileo 운용 궤도가 아니며 4기 이상 가시성이 항법 정확도를 보장하지 않습니다. 조명 실습의 고정 태양 모델도 실제 날짜의 태양 천체력과 구분합니다.

수업 원본 PDF와 로컬 로그는 저장소에 포함하지 않습니다. 해안선 데이터 출처와 이용 조건은 [assets/README.md](assets/README.md)에 있습니다.
