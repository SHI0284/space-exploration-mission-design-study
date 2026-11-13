function r=analyzeTLE(tle,c)
% Ground station AER and access from actual TLE, with SGP4/SDP4 propagation.
checked=mission.parseTLE(tle.text);
assert(strcmp(checked.line1,tle.line1)&&strcmp(checked.line2,tle.line2),'TLE metadata mismatch.');
validateattributes(c.latitudeDeg,{'numeric'},{'scalar','finite','>=',-90,'<=',90});
validateattributes(c.longitudeDeg,{'numeric'},{'scalar','finite','>=',-180,'<=',180});
validateattributes(c.altitudeM,{'numeric'},{'scalar','finite','>=',-500,'<=',10000});
validateattributes(c.minElevationDeg,{'numeric'},{'scalar','finite','>=',0,'<=',90});
validateattributes(c.stepSeconds,{'numeric'},{'scalar','integer','>=',1,'<=',60});
assert(mod(86400,c.stepSeconds)==0,'시간 간격은 86400초를 나눌 수 있는 정수여야 합니다.');
start=datetime(c.startKST,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','Asia/Seoul');
assert(~isnat(start),'시작 KST를 yyyy-MM-dd HH:mm:ss로 입력하세요.');start.TimeZone='UTC';
sc=satelliteScenario(start,start+hours(24),c.stepSeconds);
path=[tempname '.tle'];fid=fopen(path,'w');assert(fid>=0,'임시 TLE 파일 생성 실패');
fprintf(fid,'%s\n',tle.text);fclose(fid);cleanup=onCleanup(@()delete(path)); %#ok<NASGU>
propagator='sgp4';if 1440/checked.meanMotionRevPerDay>=225,propagator='sdp4';end
sat=satellite(sc,path,'OrbitPropagator',propagator);
gs=groundStation(sc,c.latitudeDeg,c.longitudeDeg,'Altitude',c.altitudeM, ...
    'Name',c.siteName,'MinElevationAngle',c.minElevationDeg);
ac=access(gs,sat);
% gs must come first: these angles describe the satellite in the station sky.
[az,el,range,utc]=aer(gs,sat);[status,accessTime]=accessStatus(ac);
assert(isequal(utc(:),accessTime(:)),'Access time grid mismatch.');
away=abs(el(:)-c.minElevationDeg)>1e-6;
assert(isequal(logical(status(away)),el(away)>=c.minElevationDeg),'Access/elevation mismatch.');
% aer returns metres; the study tables and plots use kilometres.
[schedule,tracks]=mission.passSchedule(utc,az,el,range/1000,c.minElevationDeg);
ageStart=hours(start-checked.epochUTC);ageEnd=hours(start+hours(24)-checked.epochUTC);
notes={'기하학적 교신 후보이며 실제 신호 수신·송신 가능 여부는 포함하지 않습니다.', ...
    '학교 근삿값 좌표, 기본 타원체고 0 m. 실제 안테나 측량값과 지형·건물은 미반영입니다.', ...
    '고각 경계는 표본 사이 선형 보간, 최대 고각은 표본 최대값입니다. 짧은 패스는 놓칠 수 있습니다.'};
if max(abs([ageStart ageEnd]))>48
    notes{end+1}='주의: 분석 기간에 TLE 기준시각과 48시간 이상 떨어진 시점이 있습니다. 새 TLE로 확인하세요 (학습용 경고 기준).';
end
if ageStart<0,notes{end+1}='분석 시작이 TLE 기준시각보다 이릅니다. 과거 방향 전파가 포함됩니다.';end
r=struct('kind','tle-ground-station-passes','settings',c,'tle',tle,'propagator',propagator, ...
    'schedule',schedule,'tracks',{tracks},'startUTC',start,'endUTC',start+hours(24), ...
    'tleAgeStartHours',ageStart,'tleAgeEndHours',ageEnd,'notes',{notes}, ...
    'toolboxIntervals',accessIntervals(ac));
r.history=table(utc(:),az(:),el(:),range(:)/1000,logical(status(:)), ...
    'VariableNames',{'TimeUTC','AzimuthDeg','ElevationDeg','RangeKm','AboveMask'});
end
