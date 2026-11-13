function results = run_demo()
% Reproducible three-candidate comparison without opening the app.
root=fileparts(mfilename('fullpath')); addpath(root);
c=mission.defaultConfig(); results=cell(3,1); rows=cell(3,6);
counts=[1 3 6];
for k=1:3
    c.name=sprintf('Candidate_%d',k);
    c.satellites=counts(k);
    c.planes=min(c.satellites,3);
    results{k}=mission.analyze(c); r=results{k};
    mission.exportResult(r,fullfile(root,'results',c.name));
    w=r.events.WaitSeconds; w=w(isfinite(w)); meanWait=NaN;
    if ~isempty(w), meanWait=mean(w)/60; end
    rows(k,:)={c.name,c.satellites,max(r.summary.MaxGapHours), ...
        height(r.events),meanWait,sum(~r.events.Resolved)};
end
T=cell2table(rows,'VariableNames',{'Candidate','Satellites','WorstGapHours', ...
    'Acquisitions','MeanResolvedWaitMinutes','Unresolved'});
disp(T); writetable(T,fullfile(root,'results','comparison.csv'));
% Separate experiment: remote station makes store-and-forward waiting visible.
c=mission.defaultConfig(); c.name='Remote_downlink_Perth';
c.stations=table({'Perth'},-31.9523,115.8613,'VariableNames',c.stations.Properties.VariableNames);
remote=mission.analyze(c);
mission.exportResult(remote,fullfile(root,'results',c.name));
disp('Remote downlink experiment (different station; separate from constellation comparison):');
disp(remote.summary);
end
