function result = analyze(c)
c=mission.validateConfig(c);
H=c.durationDays*86400;
t=(0:c.stepSeconds:H)';
if t(end)<H, t(end+1)=H; end
[r,elements]=mission.propagate(c,t);
nt=height(c.targets); ng=height(c.stations); ns=c.satellites;
obs=false(numel(t),nt,ns); gs=false(numel(t),ng,ns);
events=cell(0,7); contacts=cell(0,4);
for s=1:ns
    for g=1:ng
        el=mission.geometry(r(:,:,s),c.stations.LatitudeDeg(g),c.stations.LongitudeDeg(g));
        gs(:,g,s)=el>=c.minElevationDeg;
        I=mission.intervals(t,gs(:,g,s));
        for j=1:size(I,1)
            contacts(end+1,:)={s,string(c.stations.Name(g)),I(j,1),I(j,2)}; %#ok<AGROW>
        end
    end
    downlink=mission.intervals(t,any(gs(:,:,s),2));
    for k=1:nt
        [el,off]=mission.geometry(r(:,:,s),c.targets.LatitudeDeg(k),c.targets.LongitudeDeg(k));
        obs(:,k,s)=el>0 & off<=c.fovDeg/2;
        I=mission.intervals(t,obs(:,k,s));
        [wait,contact]=mission.nextContact(I(:,1),downlink);
        for j=1:size(I,1)
            events(end+1,:)={s,string(c.targets.Name(k)),I(j,1),I(j,2), ...
                wait(j),contact(j),~isnan(wait(j))}; %#ok<AGROW>
        end
    end
end
E=cell2table(events,'VariableNames',{'Satellite','Target','StartSeconds','EndSeconds', ...
    'WaitSeconds','ContactSeconds','Resolved'});
G=cell2table(contacts,'VariableNames',{'Satellite','Station','StartSeconds','EndSeconds'});
% Empty cell2table columns need explicit types for downstream operations.
if isempty(events)
    E=table(zeros(0,1),strings(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),false(0,1), ...
        'VariableNames',E.Properties.VariableNames);
end
if isempty(contacts)
    G=table(zeros(0,1),strings(0,1),zeros(0,1),zeros(0,1),'VariableNames',G.Properties.VariableNames);
end
E=sortrows(E,{'StartSeconds','Satellite'}); G=sortrows(G,{'StartSeconds','Satellite'});
unionObs=any(obs,3); unionGS=any(gs,3);
rows=cell(nt,8);
for k=1:nt
    I=mission.intervals(t,unionObs(:,k));
    gaps=[I(:,1);H]-[0;I(:,2)]; % Includes both analysis-window boundaries.
    chosen=E.Target==string(c.targets.Name(k));
    w=E.WaitSeconds(chosen); finite=w(isfinite(w));
    avg=NaN; worst=NaN;
    if ~isempty(finite), avg=mean(finite)/60; worst=max(finite)/60; end
    rows(k,:)={string(c.targets.Name(k)),size(I,1),sum(I(:,2)-I(:,1))/60, ...
        max(gaps)/3600,avg,worst,sum(chosen),sum(isnan(w))};
end
summary=cell2table(rows,'VariableNames',{'Target','UnionPasses','AccessMinutes', ...
    'MaxGapHours','MeanResolvedWaitMinutes','MaxResolvedWaitMinutes','Acquisitions','Unresolved'});
result=struct('config',c,'timeSeconds',t,'positionECEFKm',r,'elements',elements, ...
    'observationStatus',obs,'stationStatus',gs,'unionObservation',unionObs, ...
    'unionStation',unionGS,'events',E,'contacts',G,'summary',summary);
end
