function tests=test_tle
tests=functiontests(localfunctions);
end
function setupOnce(tc)
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);
tc.TestData.tle=mission.parseTLE(fileread(fullfile(root,'tests','fixtures','iss_20261113.tle')));
end
function testParsingAndEpoch(tc)
tle=tc.TestData.tle;verifyEqual(tc,tle.catalogNumber,25544);
expected=datetime(2026,11,13,'TimeZone','UTC')+days(.40012392);
verifyLessThan(tc,abs(seconds(tle.epochUTC-expected)),1e-6);
plain=mission.parseTLE(sprintf('%s\n%s',tle.line1,tle.line2));
verifyEqual(tc,plain.catalogNumber,25544);
verifyEqual(tc,plain.name,'NORAD 25544');
end
function testBadInput(tc)
tle=tc.TestData.tle;bad=tle.line1;bad(69)=char('0'+mod(str2double(bad(69))+1,10));
verifyError(tc,@()mission.parseTLE(sprintf('%s\n%s',bad,tle.line2)),'mission:TLEChecksum');
verifyError(tc,@()mission.parseTLE('<html>Error</html>'),'mission:TLEFormat');
verifyError(tc,@()mission.parseTLE([tle.text newline tle.text]),'mission:TLEFormat');
end
function testCrossingAndAzimuthWrap(tc)
utc=datetime(2026,11,14,'TimeZone','UTC')+seconds((0:10:40)');
[T,tracks]=mission.passSchedule(utc,[350;355;0;5;10],[0;20;40;20;0],ones(5,1)*1000,10);
verifyEqual(tc,height(T),1);verifyEqual(tc,seconds(T.StartUTC-utc(1)),5);
verifyEqual(tc,seconds(T.EndUTC-utc(1)),35);
verifyEqual(tc,T.StartAzimuthDeg,352.5,'AbsTol',1e-9);
verifyEqual(tc,T.EndAzimuthDeg,7.5,'AbsTol',1e-9);
verifyEqual(tc,T.StartKST.TimeZone,'Asia/Seoul');verifyEqual(tc,hour(T.StartKST),9);
verifyEqual(tc,tracks{1}.ElevationDeg([1 end]),[10;10]);
verifyFalse(tc,T.StartClipped||T.EndClipped);
end
function testEmptyAndClippedWindows(tc)
utc=datetime(2026,11,14,'TimeZone','UTC')+seconds((0:10:40)');
[T,tracks]=mission.passSchedule(utc,zeros(5,1),zeros(5,1),ones(5,1),10);
verifyEqual(tc,height(T),0);verifyEmpty(tc,tracks);verifyEqual(tc,width(T),13);
[T,~]=mission.passSchedule(utc,zeros(5,1),ones(5,1)*30,ones(5,1),10);
verifyTrue(tc,T.StartClipped&&T.EndClipped);verifyEqual(tc,T.DurationMinutes,40/60,'AbsTol',1e-12);
[T,~]=mission.passSchedule(utc,zeros(5,1),[0;0;0;0;10],ones(5,1),10);
verifyEmpty(tc,T); % A single final endpoint contributes zero duration.
end
function testActualTLEGeometryAndExports(tc)
c=mission.tleConfig();c.startKST='2026-11-14 09:00:00';
r=mission.analyzeTLE(tc.TestData.tle,c);
verifyEqual(tc,r.propagator,'sgp4');verifyEqual(tc,height(r.history),8641);
verifyEqual(tc,hour(r.startUTC),0);verifyEqual(tc,hours(r.endUTC-r.startUTC),24);
verifyGreaterThan(tc,height(r.schedule),0);
verifyGreaterThanOrEqual(tc,r.schedule.MaxElevationDeg,repmat(c.minElevationDeg,height(r.schedule),1));
verifyGreaterThanOrEqual(tc,r.schedule.StartUTC,repmat(r.startUTC,height(r.schedule),1));
verifyLessThanOrEqual(tc,r.schedule.EndUTC,repmat(r.endUTC,height(r.schedule),1));
% Independent local-vertical calculation at a sample near the first peak.
sc=satelliteScenario(r.startUTC,r.endUTC,c.stepSeconds);
path=[tempname '.tle'];fid=fopen(path,'w');fprintf(fid,'%s\n',tc.TestData.tle.text);fclose(fid);
cleanup=onCleanup(@()delete(path)); %#ok<NASGU>
sat=satellite(sc,path,'OrbitPropagator','sgp4');
peakUTC=r.schedule.PeakKST(1);peakUTC.TimeZone='UTC';
pos=states(sat,peakUTC,'CoordinateFrame','ecef');
xyz=lla2ecef([c.latitudeDeg c.longitudeDeg c.altitudeM]);ned=dcmecef2ned(c.latitudeDeg,c.longitudeDeg)*(pos(:)-xyz');
el=atan2d(-ned(3),hypot(ned(1),ned(2)));
verifyEqual(tc,el,r.schedule.MaxElevationDeg(1),'AbsTol',1e-5);
e=mission.aiEvidence(r);verifyEqual(tc,e.kind,'tle-ground-station-passes');
verifyEqual(tc,e.totalPasses,height(r.schedule));verifyFalse(tc,isfield(e,'history'));
folder=tempname;mkdir(folder);cleanup2=onCleanup(@()rmdir(folder,'s')); %#ok<NASGU>
mission.exportTLE(r,folder);csv=readtable(fullfile(folder,'passes.csv'));
verifyEqual(tc,height(csv),height(r.schedule));verifyTrue(tc,isfile(fullfile(folder,'source.tle')));
end
