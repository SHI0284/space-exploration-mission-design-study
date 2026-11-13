function evidence=aiEvidence(r,candidates)
% Explicit allowlist: no raw MAT file, filesystem paths, credentials, or code.
if nargin<2,candidates={};end
evidence=struct('schemaVersion',1,'units','seconds, minutes, hours, km and degrees as named');
if isfield(r,'kind')&&strcmp(r.kind,'tle-ground-station-passes')
    evidence.kind=r.kind;evidence.settings=struct();
    keys={'siteName','latitudeDeg','longitudeDeg','altitudeM','minElevationDeg','stepSeconds','startKST'};
    for k=1:numel(keys),evidence.settings.(keys{k})=r.settings.(keys{k});end
    evidence.satellite=struct('name',r.tle.name,'catalogNumber',r.tle.catalogNumber, ...
        'epochUTC',string(r.tle.epochUTC),'retrievedUTC',string(r.tle.retrievedUTC), ...
        'propagator',r.propagator,'ageStartHours',r.tleAgeStartHours,'ageEndHours',r.tleAgeEndHours);
    evidence.schedule=tableRows(r.schedule,100);evidence.totalPasses=height(r.schedule);
    evidence.assumptions=[r.notes,{'KST columns use UTC+09:00. UTC columns use UTC.', ...
        'StartClipped/EndClipped mean the pass extends beyond the prediction window.', ...
        'Geometric radio visibility is not actual reception, transmitter activity, or naked-eye visibility.'}];
elseif isfield(r,'kind')&&strcmp(r.kind,'walker-constellation-study')
    evidence.kind=r.kind;
    c=r.settings;
    keys={'epochUTC','durationHours','stepSeconds','radiusKm','inclinationDeg', ...
        'satellites','planes','phasing','comparePhasing','raanDeg','argumentLatitudeDeg','minElevationDeg'};
    evidence.settings=struct();
    for k=1:numel(keys),evidence.settings.(keys{k})=c.(keys{k});end
    evidence.sites=table2struct(c.sites(:,{'Name','LatitudeDeg','LongitudeDeg','AltitudeM'}));
    evidence.comparison=table2struct(r.comparison);
    evidence.baselineElements=tableRows(r.baseline.elements,100);
    evidence.assumptions={ ...
        'Ideal Walker-Delta, two-body orbits; not live Galileo ephemerides or actual service availability.', ...
        'radiusKm is geocentric orbital radius, NOT altitude.', ...
        'Official access and accessStatus, independently checked using ECEF-to-NED elevation.', ...
        'AtLeast4Percent is geometric visibility only, NOT navigation accuracy, DOP, or a position solution.', ...
        'No terrain, buildings, weather, antenna/link budget, satellite failures or signal errors.', ...
        'Summary uses left-held samples excluding final endpoint. Short gaps may be missed.', ...
        'Gaps touching analysis boundaries are truncated to this window. Locations are not global coverage.'};
    evidence.longestGapSamples=cell(numel(r.runs),1);
    for k=1:numel(r.runs)
        T=sortrows(r.runs{k}.gaps,'DurationMinutes','descend');
        evidence.longestGapSamples{k}=struct('phasing',r.runs{k}.config.phasing, ...
            'totalGapCount',height(T),'top20',tableRows(T,20));
    end
elseif isfield(r,'config')&&isfield(r,'summary')
    evidence.kind='observation-and-ground-contact';
    evidence.assumptions={ ...
        'Circular orbit, spherical Earth, nadir cone. No terrain/cloud/illumination/slew constraints.', ...
        'MaxGapHours includes both analysis-window boundaries; it is not a guaranteed periodic revisit.', ...
        'One instantaneous acquisition per satellite-target pass start. Access is not completed imaging.', ...
        'WaitSeconds is to same satellite ground contact, NOT data delivery completion.', ...
        'Unresolved waits are right-censored at simulation end. null means unavailable, never zero.', ...
        'Time-grid sampling may miss short passes. A single run does not establish causality.'};
    evidence.current=pack(r,'S0');
    count=numel(candidates); first=max(1,count-6);
    evidence.comparisonTotal=count;evidence.comparisonIncluded=min(count,7);
    evidence.comparisons=cell(1,min(count,7));
    for k=first:count
        evidence.comparisons{k-first+1}=pack(candidates{k},sprintf('S%d',k));
    end
elseif isfield(r,'assumption')&&isfield(r,'history')
    evidence.kind='fixed-sun-shadow-study';evidence.assumptions={r.assumption, ...
        'Aerospace Toolbox orbit states + custom angular-disk shadow approximation; NOT official eclipse output.', ...
        'Fixed Sun at +ICRF X, beta=0. Epoch does not imply actual-date Sun position.', ...
        'Ideal100WFirstEclipseWh is load energy with zero generation, not battery nameplate capacity.'};
    evidence.summary=table2struct(r.summary); evidence.intervals=tableRows(r.intervals,20);
elseif isfield(r,'runs')&&isfield(r,'targetSummary')
    evidence.kind='toolbox-eclipse-study';evidence.summary=table2struct(r.summary);
    evidence.targetSummary=table2struct(r.targetSummary);evidence.sampleSeconds=r.sampleSeconds;
    evidence.assumptions={'Official eclipse models, 600 km / 55 deg, Earth occultation only.', ...
        'Spacecraft illumination and target daylight are different conditions.', ...
        'Daylight + geometric access is not camera FOV, cloud clearance, or a completed observation.', ...
        '100 W energy is ideal load energy assuming no generation throughout eclipse.'};
    evidence.modelIntervals=cell(size(r.runs));
    for k=1:numel(r.runs)
        evidence.modelIntervals{k}=struct('model',r.runs{k}.model,'intervals',tableRows(r.runs{k}.intervals,20));
    end
else
    error('mission:AIInput','지원하지 않는 분석 결과 형식입니다.');
end
end
function p=pack(r,id)
c=r.config;
keys={'name','epochUTC','durationDays','stepSeconds','model','altitudeKm','inclinationDeg', ...
    'satellites','planes','raanDeg','phaseDeg','fovDeg','minElevationDeg'};
p=struct('id',id,'config',struct());
for k=1:numel(keys),p.config.(keys{k})=c.(keys{k});end
p.locations=table2struct(c.targets);p.stations=table2struct(c.stations);
p.summary=table2struct(r.summary);p.orbitLayout=table2struct(r.elements);
E=r.events;p.eventCount=height(E);p.unresolvedCount=sum(~E.Resolved);
p.resolvedCount=sum(E.Resolved);p.zeroWaitCount=sum(E.Resolved&E.WaitSeconds==0);
w=E.WaitSeconds(E.Resolved);p.meanResolvedWaitMinutes=NaN;
if ~isempty(w),p.meanResolvedWaitMinutes=mean(w)/60;end
[~,order]=sort(E.WaitSeconds,'descend','MissingPlacement','last');
ix=unique([1:min(5,height(E)),order(1:min(5,height(E)))',find(~E.Resolved,5)']);
p.eventSample=table2struct(E(ix,:));p.eventSampleIsComplete=numel(ix)==height(E);
p.eventSampleRule='First five, largest five finite waits, first five unresolved; deduplicated. Not all events.';
gaps=cell(1,height(c.targets)); H=r.timeSeconds(end);
for k=1:height(c.targets)
    I=mission.intervals(r.timeSeconds,r.unionObservation(:,k));
    starts=[0;I(:,2)]; ends=[I(:,1);H]; [gap,j]=max(ends-starts);
    gaps{k}=struct('target',string(c.targets.Name(k)),'startSeconds',starts(j), ...
        'endSeconds',ends(j),'hours',gap/3600,'touchesAnalysisBoundary',starts(j)==0||ends(j)==H);
end
p.longestGaps=gaps;
end
function s=tableRows(T,n)
T=T(1:min(height(T),n),:);
for k=1:width(T)
    key=T.Properties.VariableNames{k};
    if isdatetime(T.(key)),T.(key)=string(T.(key),'yyyy-MM-dd HH:mm:ss');end
end
s=table2struct(T);
end
