function r=analyzeWalker(c)
% Official Toolbox access, checked independently with ECEF -> local NED LOS.
[sc,sat,gs]=mission.walkerScenario(c);
S=numel(sat); G=numel(gs);
% Read before states/access advance AutoSimulate to the stop time.
elementRows=cell(S,1);
for s=1:S,elementRows{s}=orbitalElements(sat(s));end
elements=vertcat(elementRows{:}); elementsTable=struct2table(elements);
[pos,~,utc]=states(sat,'CoordinateFrame','ecef');
t=seconds(utc(:)-sc.StartTime); n=numel(t);
assert(all(abs(vecnorm(pos,2,1)-c.radiusKm*1000)<1,'all'),'Circular radius check failed.');
visible=false(n,S,G); elevation=zeros(n,S,G); perSatellite=cell(G,1); rawIntervals=cell(G,1);
summary=table(); gaps=table();
for g=1:G
    ac=access(sat,gs(g));
    [status,at]=accessStatus(ac);
    assert(isequal(at(:),utc(:)),'Access and states time grids differ.');
    visible(:,:,g)=reshape(status,S,n)';
    pct=accessPercentage(ac);rawIntervals{g}=accessIntervals(ac);
    perSatellite{g}=table((1:S)',pct(:),'VariableNames',{'SatelliteIndex','ToolboxAccessPercent'});
    xyz=lla2ecef([c.sites.LatitudeDeg(g),c.sites.LongitudeDeg(g),c.sites.AltitudeM(g)]);
    R=dcmecef2ned(c.sites.LatitudeDeg(g),c.sites.LongitudeDeg(g));
    for s=1:S
        ned=R*(pos(:,:,s)-xyz');
        el=atan2d(-ned(3,:),hypot(ned(1,:),ned(2,:)))';
        elevation(:,s,g)=el;
        away=abs(el-c.minElevationDeg)>1e-6;
        assert(isequal(el(away)>=c.minElevationDeg,visible(away,s,g)), ...
            'ECEF/NED elevation disagrees with Toolbox access.');
    end
    count=sum(visible(:,:,g),2); weight=diff(t); H=t(end);
    outage=mission.intervals(t,count<1); below4=mission.intervals(t,count<4);
    one=100*sum(weight.*(count(1:end-1)>=1))/H;
    four=100*sum(weight.*(count(1:end-1)>=4))/H;
    avg=sum(weight.*count(1:end-1))/H;
    summary=[summary;table(c.phasing,c.sites.Name(g),min(count(1:end-1)),avg,max(count(1:end-1)), ...
        one,four,max([0;diff(outage,1,2)])/60,max([0;diff(below4,1,2)])/60, ...
        'VariableNames',{'Phasing','Site','MinVisible','MeanVisible','MaxVisible', ...
        'AtLeast1Percent','AtLeast4Percent','MaxNoAccessMinutes','MaxBelow4Minutes'})]; %#ok<AGROW>
    for threshold=[1 4]
        I=mission.intervals(t,count<threshold);m=size(I,1);
        gaps=[gaps;table(repmat(c.phasing,m,1),repmat(c.sites.Name(g),m,1),repmat(threshold,m,1), ...
            I(:,1),I(:,2),(I(:,2)-I(:,1))/60,I(:,1)==0|I(:,2)==H, ...
            'VariableNames',{'Phasing','Site','RequiredVisible','StartSeconds','EndSeconds','DurationMinutes','TouchesBoundary'})]; %#ok<AGROW>
    end
end
r=struct('config',c,'summary',summary,'elements',elementsTable,'timeUTC',utc(:), ...
    'timeSeconds',t,'visible',visible,'elevationDeg',elevation,'counts',reshape(sum(visible,2),n,G), ...
    'perSatellite',{perSatellite},'accessIntervals',{rawIntervals},'gaps',gaps);
end
