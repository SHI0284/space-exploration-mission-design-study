function T = run_convergence()
% Repeat the default scenario at 20/10/5 s and record resolution sensitivity.
root=fileparts(mfilename('fullpath')); addpath(root);
c=mission.defaultConfig(); steps=[20 10 5]; rows=cell(0,6);
for dt=steps
    c.stepSeconds=dt; r=mission.analyze(c);
    for k=1:height(r.summary)
        s=r.summary(k,:);
        rows(end+1,:)={dt,string(s.Target),s.UnionPasses,s.MaxGapHours, ...
            s.MeanResolvedWaitMinutes,s.Unresolved}; %#ok<AGROW>
    end
end
T=cell2table(rows,'VariableNames',{'StepSeconds','Target','UnionPasses','MaxGapHours', ...
    'MeanResolvedWaitMinutes','Unresolved'});
folder=fullfile(root,'results'); if ~isfolder(folder), mkdir(folder); end
writetable(T,fullfile(folder,'time_step_convergence.csv')); disp(T);
end
