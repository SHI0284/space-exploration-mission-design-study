%% 0. 실습 방법: 한 구역씩 실행하기
% MATLAB 편집기에서 이 파일을 열고 이 0번 구역부터 순서대로 실행한다.
% 구역 안에 커서를 두고 Ctrl+Enter를 누르면 해당 구역만 실행된다.
% 목표: '왜 이 시간에 위성이 보이는가?'를 TLE, 고각, 시간표로 설명하기.
% 재현 가능한 실습을 위해 실제 ISS의 보관 TLE와 고정된 날짜를 사용한다.
% 현재 교신 예측에는 앱에서 새 TLE를 받고 '현재 시각'을 설정해야 한다.
studyRoot=fileparts(mfilename('fullpath'));addpath(studyRoot);

%% 1. TLE에서 위성 번호와 기준시각 찾기
% 먼저 예상: 아래 첫 데이터 줄의 25544, 26317.40012392는 각각 무엇일까?
studyText=fileread(fullfile(studyRoot,'tests','fixtures','iss_20261113.tle'));
disp(studyText);
studyTLE=mission.parseTLE(studyText);
disp(studyTLE.name);
disp(studyTLE.catalogNumber);
disp(studyTLE.epochUTC);
% 확인: 25544는 카탈로그 번호, 26은 2026년, 317은 그해의 317번째 날.
% 소수 부분은 UTC 하루의 비율이다. 다운로드 시각과 구분한다.
% 코드 위치: +mission/parseTLE.m, line1의 19:32 문자 처리.

%% 2. 평균 운동에서 궤도 주기 계산하기
% 먼저 예상: 하루 약 15.5바퀴면 한 바퀴는 몇 분일까?
studyPeriodMinutes=1440/studyTLE.meanMotionRevPerDay;
fprintf('평균 운동 %.6f rev/day -> 주기 약 %.2f min\n', ...
    studyTLE.meanMotionRevPerDay,studyPeriodMinutes);
% 확인: 분/일 ÷ 회전/일 = 분/회전. 이 위성은 SGP4로 전파한다.
% 주기가 곧 다음 지상국 접속까지의 시간은 아니다. 그 사이 지구도 자전한다.

%% 3. 학교 위치와 KST/UTC 구분하기
studyConfig=mission.tleConfig();
studyConfig.startKST='2026-11-14 09:00:00';
disp(studyConfig);
studyStart=datetime(studyConfig.startKST,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','Asia/Seoul');
fprintf('KST: %s\n',string(studyStart,'yyyy-MM-dd HH:mm:ss'));
studyStart.TimeZone='UTC';fprintf('UTC: %s\n',string(studyStart,'yyyy-MM-dd HH:mm:ss'));
% 확인: 같은 순간이 KST 09:00 / UTC 00:00으로 표시되는가?
% 주의: 위도·경도는 캠퍼스 대표 근삿값, 타원체고 0 m도 학습용 가정이다.
% 문제: 고각 10도와 위도 37.2456도는 무엇을 기준으로 측정하는 각도일까?

%% 4. 24시간 궤도를 계산하고 교신 후보 찾기
% 먼저 예상: 매 공전마다 학교에서 위성이 보일까?
studyResult=mission.analyzeTLE(studyTLE,studyConfig);
disp(studyResult.schedule(:,{'Pass','StartKST','EndKST','DurationMinutes','MaxElevationDeg'}));
fprintf('총 %d개 패스, %d개 시각 표본\n',height(studyResult.schedule),height(studyResult.history));
% 확인: 기본 실습에서는 6개 패스. 이것은 실제 수신 성공 횟수가 아니다.
% 각 시각의 AER: Azimuth=방위각, Elevation=고각, Range=사거리.
% 코드 위치: +mission/analyzeTLE.m의 aer(gs,sat).
% 판정의 핵심: Elevation >= 최소 고각. 이 판정이 이어지는 구간이 패스다.

%% 5. 가장 높이 지나가는 패스의 하늘 경로 읽기
[~,studyPassIndex]=max(studyResult.schedule.MaxElevationDeg);
studyPass=studyResult.schedule(studyPassIndex,:);disp(studyPass);
studyFigure=figure('Name','TLE learning | one pass','Color','w');
studyLayout=tiledlayout(studyFigure,1,2);
studySky=polaraxes(studyLayout);studySky.Layout.Tile=1;
studyProfile=nexttile(studyLayout,2);
mission.drawTLEPass(studySky,studyProfile,studyResult,studyPassIndex);
% 먼저 읽기: 시작 방위각은 어느 방향인가? 종료 방향은? 천정을 지나는가?
% 확인: N=0, E=90, S=180, W=270도. 중심=고각 90도, 바깥 원=0도.
% 초록 원이 시작, 빨강 사각형이 종료. 69도는 90도 천정 통과가 아니다.

%% 6. 최소 고각을 바꾸기: 예상 -> 실행 -> 비교
% 질문: 10도를 20도로 올리면 패스 수/지속시간이 늘어날까, 줄어들까?
% 아래 값을 true로 바꾼 뒤 이 구역을 실행한다 (추가 계산 시간 필요).
runMaskExperiment=false;
if runMaskExperiment
    studyHigherMask=studyConfig;studyHigherMask.minElevationDeg=20;
    studyHigherResult=mission.analyzeTLE(studyTLE,studyHigherMask);
    studyComparison=table([10;20], ...
        [height(studyResult.schedule);height(studyHigherResult.schedule)], ...
        [sum(studyResult.schedule.DurationMinutes);sum(studyHigherResult.schedule.DurationMinutes)], ...
        'VariableNames',{'MinimumElevationDeg','PassCount','TotalCandidateMinutes'});
    disp(studyComparison);
end
% 설명해보기: 같은 궤도에서 20도 이상인 시각은 10도 이상인 시각의 부분집합.
% 따라서 총 기하학적 가시 시간은 늘어나지 않는다. 경계가 약간 보간된다.
% 기본 첫 패스의 최고 고각은 약 10.09도. 20도 조건에서는 남을 수 있을까?

%% 7. 시간 간격을 바꾸기: 계산 결과의 정밀도 생각하기
% 질문: 60초 간격이면 약 37초짜리 첫 패스를 항상 찾을 수 있을까?
% 아래 값을 true로 바꾼 뒤 비교한다. '찾았다'가 '항상 찾는다'는 뜻은 아니다.
runSamplingExperiment=false;
if runSamplingExperiment
    studyCoarse=studyConfig;studyCoarse.stepSeconds=60;
    studyCoarseResult=mission.analyzeTLE(studyTLE,studyCoarse);
    disp(studyCoarseResult.schedule(:,{'Pass','StartKST','EndKST','MaxElevationDeg'}));
    disp(studyResult.schedule(:,{'Pass','StartKST','EndKST','MaxElevationDeg'}));
end
% 코드 위치: +mission/passSchedule.m. 경계는 두 고각 표본 사이 선형 보간.
% 최대 고각은 표본 최대값이므로 시간 간격에 따라 조금 달라진다.

%% 8. 스스로 설명할 수 있는지 확인하기
% 1) 지금 시간표가 KST인지 UTC인지 어디서 확인하는가?
% 2) 위성이 기하학적으로 보여도 무선 신호가 안 잡힐 수 있는 이유는?
% 3) 24시간 시작부터 위성이 보였다면 표의 시작은 진짜 AOS인가?
%    힌트: StartClipped / EndClipped 열.
% 4) TLE를 오늘 내려받았는데 epoch가 일주일 전이라면 최신 궤도인가?
% 5) 구름 없는 밤에 이 표만으로 ISS를 육안 관측할 수 있다고 결론낼 수 있는가?
%    힌트: 태양 조명, 지상 어둠, 최소 고각과 무선 가시성은 별개다.
%
% AI는 답을 대신 받기보다 내 설명을 검토하는 데 사용한다.
% 예: '나는 최소 고각을 높이면 총 가시 시간이 줄어든다고 예상했다.
%      이 결과로 내 설명을 검토하고, 빠진 가정 하나를 질문해줘.'
