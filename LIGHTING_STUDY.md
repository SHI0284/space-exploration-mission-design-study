# Lecture 10 — Lighting / Eclipse MATLAB 실습

자료: `Lec_10_1-2 Lighting Eclipse Condition_F04.pdf`, 26~28쪽.

## 핵심 개념

**위성이 어둡다**는 지구가 위성에서 바라본 태양을 가린다는 뜻입니다. 태양전지 발전과 열환경에 영향을 줍니다. **표적이 어둡다**는 관측할 지표면에서 태양이 보이지 않는다는 뜻입니다. 두 조건을 같은 Boolean으로 취급하면 안 됩니다.

- Sunlight: 태양 원반 전체가 보임, `eclipseStatus = 1`.
- Umbra / Total: 태양 원반 전체가 가려짐, `eclipseStatus = 0`.
- Penumbra / Partial: 일부가 가려짐, `0 < eclipseStatus < 1`.
- Antumbra / Annular: 가림 천체가 태양보다 작게 보여 태양 가장자리가 남는 경우. 이번 600 km 지구 저궤도 사례의 주 관심 상태는 아닙니다.

`status`는 그림자 여부의 Boolean이 아니라 **보이는 태양 원반의 비율**입니다. `1`을 식 발생으로 해석하면 결과가 반대가 됩니다.

## 함수와 예제에서의 역할

| 함수 / 속성 | 하는 일 |
|---|---|
| `satelliteScenario` | 시작·종료 UTC와 시간 간격 설정 |
| `satellite` | 600 km / 55° 원궤도 생성, Toolbox two-body 전파 |
| `states` | 시간별 관성계 위치·속도 이력, 단위 m / m/s |
| `orbitalElements` | 생성한 위성의 궤도요소 확인 |
| `eclipse` | 위성 또는 지상 지점에 태양 차폐 분석 연결 |
| `eclipseStatus` | 태양 원반 가시 비율과 Earth eclipse type 반환 |
| `eclipseIntervals` | 차폐 시작·종료·지속시간·최소 가시 비율 표 |
| `eclipsePercentage` | 분석 시간 중 태양 차폐 발생 비율 (%) |
| `EclipseModel` | `dual-cone` / `cylindrical` 모델 선택 |
| `groundStation`, `access`, `accessStatus`, `accessIntervals` | 서울에서 위성이 고각 10° 이상으로 보이는 구간과 표적 낮 조건 결합 |

`cylindrical`는 태양 광선을 평행하게 보고 원통 그림자를 사용합니다. 가시 비율이 0 또는 1입니다. `dual-cone`는 태양의 유한한 크기를 반영하여 본그림자·반그림자를 구분하므로 식 경계에서 중간값이 나옵니다. `IncludeLunarEclipse=false`로 이번 실험은 지구에 의한 차폐만 계산합니다. 강의 28쪽 표는 달 차폐를 포함한 다른 날짜·궤도 예시이므로 숫자가 같을 필요는 없습니다.

## 실행

### 데이터 패키지 없이 바로 실행하는 학습 예제

```matlab
result = run_shadow_geometry_demo;
```

이 예제는 `satelliteScenario`, `satellite`, `states`, `orbitalElements`를 실제로 사용하고, 22~23쪽의 겉보기 각반경·중심 분리각 판정을 직접 구현합니다. 태양은 **+ICRF X 방향, 1 AU에 고정**한 가상의 학습 조건이며 β=0입니다. 날짜의 실제 태양 위치를 재현하지 않습니다. 부분식 가시 비율은 작은 각도의 평면 원반 중첩 근사입니다. `eclipse` 함수의 실행 결과가 아닙니다.

출력 위치는 `results/shadow_geometry`입니다. 원통 그림자 지속시간을 원궤도 해석식 `T/pi * asin(R/a)`와 비교합니다. 이 실험에서 날짜는 시간표의 기준점 역할만 합니다.

### 공식 eclipse 함수 실습

MATLAB에서 `mission-designer` 폴더를 현재 폴더로 선택하고:

```matlab
result = run_lighting_demo;
```

필수 조건: Aerospace Toolbox와 **Ephemeris Data for Aerospace Toolbox** 데이터 패키지. 데이터가 없다는 오류가 나면 다음 명령으로 공식 설치 화면을 엽니다.

```matlab
aeroDataPackage
```

날짜 2026-11-05 UTC부터 24시간, 5초 간격, 600 km / 55° / RAAN 0° / 초기 진근점이각 0°를 사용합니다. `results/lighting` 아래에 비교 그림, 상태 이력, 식 구간, 서울 가시성·낮 조건 표, MAT 결과가 저장됩니다. 동일 예제 재실행 시 이 폴더의 예제 결과를 갱신합니다.

## 결과를 읽는 순서

1. 첫 번째 그래프: 위성이 햇빛을 받다가 그림자로 들어가는 반복을 봅니다.
2. 두 번째 그래프: 경계를 확대해 원통형의 급격한 0/1 변화와 dual-cone의 부분 차폐를 비교합니다.
3. 세 번째 그래프: 서울의 낮 조건과 위성의 기하학적 가시 구간을 따로 봅니다. 둘의 교집합이 단순 낮 관측 후보입니다.
4. 비교표에서 가장 긴 식 구간을 확인합니다. 100 W 부하가 35분 동안 계속된다면 부하 에너지는 `100 * 35/60 = 58.33 Wh`입니다. 이는 설명용 예이며 실제 계산값은 결과표에서 확인해야 합니다.

`Ideal100WLoadEnergyWh`는 반그림자까지 발전 0으로 가정한 식 1회 부하 에너지입니다. 배터리 방전심도, 효율, 노화, 여유율을 반영한 정격 용량이 아닙니다.

표적 낮 조건은 태양 원반 전체가 보이는 단순 기준입니다. 실제 카메라 FOV, 해상도, 최소 태양고각, 위상각, 구름·자세·촬영 스케줄은 포함하지 않습니다. `access`는 여기서 고각 10° 이상의 기하학적 가시성입니다.

## 직접 바꿔볼 항목

- 고도: `6978137`(지구 반지름 + 600 km)을 바꿔 식 시간 변화를 비교.
- RAAN: `satellite` 입력의 0°를 90°로 바꿔 태양과 궤도면의 관계 변화 관찰.
- 날짜: 11월과 5월을 비교하여 태양 방향의 계절 변화 관찰.
- 시간 간격: `dt=5`를 1초 또는 20초로 바꾸어 짧은 반그림자 포착과 경계시각 차이 관찰.

## 고정 태양 실험 결과

`run_shadow_geometry_demo` 수치 검사: 원궤도 반지름 유지, 태양 가시 비율 0~1, Sunlight/Penumbra/Umbra 존재, 원통 그림자 지속시간과 해석식의 차이 2초 이내를 확인했습니다.

- 궤도 주기: 96.6872분.
- 원통 그림자 이론값: 35.4877분, 1초 표본 계산: 35.5000분.
- 유한 태양 각원반 모델의 첫 식(부분식 포함): 35.6333분.
- 첫 식 동안 100 W 부하 에너지: 59.3889 Wh (발전 0, 이상적 부하 에너지 가정).
- 3시간 중 부분식으로 분류된 표본 구간 합계: 35초.

공식 `eclipse` 예제에는 Aerospace Ephemeris Data가 필요합니다. 해당 예제는 구문 검사만 완료했으며, 공식 식·낮 관측 결과는 실행 검증 전입니다. 위 수치는 `run_shadow_geometry_demo`의 고정 태양 모델 결과입니다.

## 공식 문서 링크

- https://www.mathworks.com/help/aerotbx/ug/matlabshared.satellitescenario.eclipse.eclipsestatus.html
- https://www.mathworks.com/help/aerotbx/ug/matlabshared.satellitescenario.eclipse.html
- https://www.mathworks.com/help/aerotbx/ug/install-data-for-aerospace-products.html
