function tests = test_mission
tests=functiontests(localfunctions);
end
function setupOnce(~)
addpath(fileparts(fileparts(mfilename('fullpath'))));
end
function testIntervals(testCase)
t=(0:10:40)';
verifyEqual(testCase,mission.intervals(t,[0 1 1 0 1]),[10 30]);
verifyEqual(testCase,mission.intervals(t,true(5,1)),[0 40]);
verifySize(testCase,mission.intervals(t,false(5,1)),[0 2]);
verifyEqual(testCase,mission.intervals([0 10 15],[0 1 1]),[10 15]);
end
function testSameSatelliteContactBoundary(testCase)
I=[10 20;30 40];
[w,d]=mission.nextContact([0;10;19;20;39;40],I);
verifyEqual(testCase,w(1:5),[10;0;0;10;0]);
verifyTrue(testCase,isnan(w(6))); verifyTrue(testCase,isnan(d(6)));
[w,~]=mission.nextContact(10,zeros(0,2)); verifyTrue(testCase,isnan(w));
end
function testGeometryAnalytic(testCase)
R=6378.137; a=R+600;
[el,off]=mission.geometry([a 0 0],0,0);
verifyEqual(testCase,el,90,'AbsTol',1e-10); verifyEqual(testCase,off,0,'AbsTol',1e-10);
[el,~]=mission.geometry([-a 0 0],0,0); verifyEqual(testCase,el,-90,'AbsTol',1e-10);
psi=acos(R/a); [el,off]=mission.geometry(a*[cos(psi),sin(psi),0],0,0);
verifyEqual(testCase,el,0,'AbsTol',1e-9);
verifyEqual(testCase,off,asind(R/a),'AbsTol',1e-9);
end
function testCircularRadiusAndPeriod(testCase)
c=mission.defaultConfig(); c.satellites=1; c.planes=1;
period=2*pi*sqrt((6378.137+c.altitudeKm)^3/398600.4418);
r=mission.propagate(c,[0;period]);
verifyEqual(testCase,vecnorm(r,2,2),repmat(6978.137,2,1),'AbsTol',1e-8);
% Undo Earth's rotation over one Keplerian orbit.
angle=7.2921151467e-5*period;
rot=[cos(angle),-sin(angle),0;sin(angle),cos(angle),0;0,0,1];
verifyEqual(testCase,(rot*r(2,:)')',r(1,:),'AbsTol',1e-7);
end
function testNeverObservedAndMonotonicFOV(testCase)
c=mission.defaultConfig(); c.durationDays=.1; c.inclinationDeg=0;
c.targets=table({'Pole'},90,0,'VariableNames',c.targets.Properties.VariableNames);
r=mission.analyze(c);
verifyEqual(testCase,height(r.events),0);
verifyEqual(testCase,r.summary.MaxGapHours,2.4,'AbsTol',1e-10);
verifyTrue(testCase,isnan(r.summary.MeanResolvedWaitMinutes));
c=mission.defaultConfig(); c.durationDays=1; c.fovDeg=30;
a=mission.analyze(c); c.fovDeg=90; b=mission.analyze(c);
verifyTrue(testCase,all(~a.observationStatus(:)|b.observationStatus(:)));
verifyTrue(testCase,all(b.summary.MaxGapHours<=a.summary.MaxGapHours+1e-10));
end
function testLatencyUsesOwningSatellite(testCase)
c=mission.defaultConfig(); c.durationDays=1;
c.stations=table({'Perth'},-31.9523,115.8613,'VariableNames',c.stations.Properties.VariableNames);
r=mission.analyze(c);
verifyGreaterThan(testCase,sum(r.events.WaitSeconds>0),0);
for k=1:height(r.events)
    e=r.events(k,:); s=e.Satellite;
    I=mission.intervals(r.timeSeconds,any(r.stationStatus(:,:,s),2));
    [w,d]=mission.nextContact(e.StartSeconds,I);
    verifyEqual(testCase,e.WaitSeconds,w); verifyEqual(testCase,e.ContactSeconds,d);
end
verifyTrue(testCase,all(r.events.WaitSeconds(r.events.Resolved)>=0));
end
function testRejectInvalidPlaneCount(testCase)
c=mission.defaultConfig(); c.satellites=5; c.planes=3;
verifyError(testCase,@()mission.analyze(c),'mission:Input');
end
function testTimeGridConvergence(testCase)
c=mission.defaultConfig(); c.durationDays=1; c.fovDeg=90; c.stepSeconds=20;
a=mission.analyze(c); c.stepSeconds=10; b=mission.analyze(c);
verifyEqual(testCase,a.summary.UnionPasses,b.summary.UnionPasses);
verifyLessThanOrEqual(testCase,max(abs(a.summary.MaxGapHours-b.summary.MaxGapHours))*3600,40+1e-6);
end
function testConfigRoundTrip(testCase)
c=mission.defaultConfig(); f=[tempname '.mat'];
cleanup=onCleanup(@()delete(f)); %#ok<NASGU>
config=c; save(f,'config'); x=load(f); verifyEqual(testCase,x.config,c);
end
