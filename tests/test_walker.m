function tests=test_walker
tests=functiontests(localfunctions);
end
function setupOnce(tc)
addpath(fileparts(fileparts(mfilename('fullpath'))));
c=mission.walkerConfig();c.durationHours=2;
runs=cell(3,1);comparison=table();phases=[1 0 2];
for k=1:3
    cfg=c;cfg.phasing=phases(k);runs{k}=mission.analyzeWalker(cfg);
    comparison=[comparison;runs{k}.summary]; %#ok<AGROW>
end
tc.TestData.result=struct('kind','walker-constellation-study','settings',c, ...
    'baseline',runs{1},'runs',{runs},'comparison',comparison);
end
function testDefaultLayoutAndEvidence(tc)
r=tc.TestData.result;
verifyEqual(tc,height(r.comparison),9);
verifyEqual(tc,sort(unique(r.comparison.Phasing)),[0;1;2]);
E=r.baseline.elements;raan=E.RightAscensionOfAscendingNode;
verifyEqual(tc,sort(unique(round(raan,6))),[0;120;240],'AbsTol',1e-5);
for node=[0 120 240]
    u=sort(mod(E.ArgumentOfPeriapsis(abs(raan-node)<1e-5)+E.TrueAnomaly(abs(raan-node)<1e-5),360));
    verifyEqual(tc,numel(u),8);
    verifyEqual(tc,diff([u;u(1)+360]),45*ones(8,1),'AbsTol',1e-5);
end
u0=mod(E.ArgumentOfPeriapsis+E.TrueAnomaly,45);
verifyEqual(tc,u0(abs(raan)<1e-5),15*ones(8,1),'AbsTol',1e-5);
verifyEqual(tc,u0(abs(raan-120)<1e-5),30*ones(8,1),'AbsTol',1e-5);
verifyGreaterThanOrEqual(tc,r.comparison.AtLeast1Percent,r.comparison.AtLeast4Percent);
e=mission.aiEvidence(r);verifyEqual(tc,e.kind,'walker-constellation-study');
b=mission.aiRequest(e,'F별 차이를 설명해줘.');verifyFalse(tc,b.store);
verifyLessThan(tc,strlength(string(jsonencode(e))),180000);
end
function testNoAccessAndBoundary(tc)
c=mission.walkerConfig();c.satellites=3;c.planes=3;
c.durationHours=1;c.stepSeconds=60;c.minElevationDeg=90;
c.sites=c.sites(1,:);
r=mission.analyzeWalker(c);
verifyEqual(tc,r.counts,zeros(61,1));
verifyEqual(tc,r.summary.AtLeast1Percent,0);
verifyEqual(tc,r.summary.MaxNoAccessMinutes,60);
verifyEqual(tc,r.gaps.DurationMinutes,[60;60]);
verifyTrue(tc,all(r.gaps.TouchesBoundary));
end
function testAppSource(tc)
app=MissionDesignerApp();cleanup=onCleanup(@()delete(app.Figure)); %#ok<NASGU>
verifyTrue(tc,any(strcmp(app.AISource.Items,'Walker 위성군 실습')));
e=mission.aiEvidence(tc.TestData.result);
verifyEqual(tc,e.kind,'walker-constellation-study');
end
