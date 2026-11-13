# Walker-Delta 위성군 실습

첨부 슬라이드의 위성군 생성·가시성 분석을 실행하는 실습입니다. MATLAB Aerospace Toolbox가 필요합니다. 태양 천체력을 계산하지 않아 조명 실습용 Ephemeris Data 패키지는 필요하지 않습니다.

## 실행

MATLAB 현재 폴더를 `mission-designer`로 설정합니다.

```matlab
result = run_walker_demo;             % 계산 + 결과 그래프
mission.openWalkerViewer(result.settings); % 슬라이드처럼 3D 궤도 보기
```

한 번에 그래프와 3D 보기를 열려면 `result = run_walker_demo(true,true);`를 실행합니다. Viewer의 재생 버튼으로 시간에 따른 위성 배치를 확인할 수 있습니다.

기본값은 **56° : 24 / 3 / 1**, 궤도반경 29,599.8 km, 초기 위도인수 15°, 2026-11-10 UTC부터 24시간, 60초 간격, 최소 고각 10°입니다. 서울·부산·제주에서 분석하며 F=0,1,2를 같은 조건에서 비교합니다. Galileo와 비슷한 이상적 배치이지 현재 운용 위성의 궤도 자료가 아닙니다.

## i : T / P / F의 뜻

- i: 궤도 경사각. T: 전체 위성 수. P: 궤도면 수. 각 궤도면에는 T/P기가 들어갑니다.
- 궤도면 RAAN 간격: 360/P. 같은 궤도면 위성 간격: 360/(T/P).
- F: 인접 궤도면의 대응 위성 위상 차이를 정하는 정수. 범위는 0 ≤ F < P, 위상 차이는 F×360/T 도입니다.
- 기본값에서는 궤도면 간격 120°, 면당 8기, 면내 간격 45°, 인접 면 위상 차이 15°입니다.
- `walkerDelta`에 넣는 radius는 **지구 중심으로부터의 반경(m)**입니다. 고도가 아닙니다. 기본 반경에서 적도반경 6,378.137 km를 빼면 약 23,221.663 km입니다.

근거: [MathWorks walkerDelta 공식 문서](https://www.mathworks.com/help/aerotbx/ug/satellitescenario.walkerdelta.html).

## Toolbox 함수를 사용한 위치

| 함수 | 파일 | 실제 용도 |
|---|---|---|
| satelliteScenario | +mission/walkerScenario.m | UTC 분석기간과 표본 간격 설정 |
| walkerDelta | +mission/walkerScenario.m | T/P/F 배치의 위성군 생성 |
| groundStation | +mission/walkerScenario.m | 사용자 위치·고도·최소 고각 설정 |
| orbitalElements | +mission/analyzeWalker.m | 각 위성의 초기 궤도요소 조회 |
| states | +mission/analyzeWalker.m | 모든 위성의 ECEF 위치 계산 |
| access, accessStatus | +mission/analyzeWalker.m | 위성별 가시성 및 동시 가시 위성 수 |
| accessIntervals, accessPercentage | +mission/analyzeWalker.m | 위성별 접속 구간·가용 비율 내보내기 |
| lla2ecef, dcmecef2ned | +mission/analyzeWalker.m | 사용자 ECEF 좌표와 지역 NED 시선벡터를 계산하여 공식 access와 교차 확인 |
| satelliteScenarioViewer | +mission/openWalkerViewer.m | 같은 설정의 위성군 3D 표시 |

지역 NED에서 고각은 `atan2d(-Down, hypot(North,East))`입니다. 지구 타원체의 측지 좌표를 사용합니다. [좌표변환 공식 문서](https://www.mathworks.com/help/aerotbx/ug/dcmecef2ned.html).

## 결과 읽기

`results/walker/`에 실행할 때마다 최신 결과를 저장합니다. 보관할 실험이 있으면 다음 실행 전에 이 폴더를 복사하세요.

- `walker_overview.png`: 지점별 동시 가시 수, 첫 지점의 위성별 가시성, F 비교, 초기 위성 배치.
- `comparison.csv`: F·지점별 최소/평균/최대 가시 수, 1기/4기 이상 가시 비율, 최대 서비스 공백.
- `orbital_elements.csv`: 기본 F의 초기 궤도요소. MAT에는 비교 F의 요소도 있습니다.
- `F*_site*_counts.csv`: 동시 가시 수 시계열. site 번호는 설정 표 순서입니다.
- `F*_site*_access_intervals.csv`, `satellite_access.csv`: Toolbox 공식 위성별 접속 결과.
- `F*_service_gaps.csv`: 1기 미만/4기 미만인 구간. 분석 경계에서 잘린 구간은 TouchesBoundary=true.
- `result.mat`: 설정과 비교 실험 전체 배열.

**4기 이상 가시 비율은 위치해 정확도나 실제 항법 서비스 가용도가 아닙니다.** DOP, 측정 오차, 위성 시계, 전리층, 신호 세기, 건물 등은 계산하지 않습니다. 지점 세 곳의 결과를 전 지구 성능으로 일반화할 수도 없습니다.

요약 비율은 각 표본이 다음 표본까지 유지된다고 가정하며 마지막 시각은 지속시간에 포함하지 않습니다. 공백 길이는 표본 해상도에 의존합니다. `accessPercentage`는 위성별 공식 지표로 별도 저장하며 합산해서 위성군 가용도로 사용하지 않습니다.

## 설정을 바꾸는 실험

기본 조건의 실제 실행 결과: F=1에서 세 지점 모두 최소 5기, 최대 9기이며, 평균은 서울 6.9562기·부산 6.9806기·제주 6.9799기입니다. F=0에서는 제주 최소값이 4기로 내려갑니다. 세 F 모두 세 지점에서 4기 이상 가시 비율은 100%였습니다. 이는 해당 24시간·60초 표본 조건의 결과입니다.

```matlab
c = mission.walkerConfig;
c.minElevationDeg = 20;               % 고각 조건만 강화해 비교
r20 = run_walker_demo(true,false,c);

c = mission.walkerConfig;
c.radiusKm = 6378.137 + 600;          % 600 km 저궤도
c.stepSeconds = 10;                   % 짧은 가시 구간 해상도 개선
rLEO = run_walker_demo(true,false,c);
```

T는 P로 나누어떨어져야 하며 P를 바꾸면 `phasing`과 `comparePhasing`도 유효 범위로 바꿉니다. 기본값을 복원하려면 `run_walker_demo`를 다시 실행합니다.

## AI 결과 해석 연결

실습을 실행한 다음 앱을 열고 **AI 결과 해석 → Walker 위성군 실습 → 근거 미리보기**를 선택합니다. API 키 등록 후 질문할 수 있습니다.

- “F가 바뀌면 서울의 최소 가시 위성 수와 평균은 어떻게 달라져?”
- “4기 이상 가시 비율이 100%인데도 항법 정확도를 보장하지 못하는 이유는?”
- “관측한 세 지점의 차이를 설명하고 다음 비교 실험을 제안해줘.”

AI에는 설정, 비교 요약, 기본 궤도요소, 최대 공백 표본이 전달됩니다. 전체 시계열이나 그림을 본 것처럼 답하지 않도록 근거 범위를 명시했습니다. API 호출은 질문 버튼을 누를 때만 이루어집니다.
