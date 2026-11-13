function smoke_tle()
% Exercise the TLE tab without network or paid AI requests.
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);
app=launch_mission_designer();cleanup=onCleanup(@()delete(app.Figure)); %#ok<NASGU>
p=app.TLEPanel;tle=mission.parseTLE(fileread(fullfile(root,'tests','fixtures','iss_20261113.tle')));
p.setTLE(tle);p.Fields.startKST.Value='2026-11-14 09:00:00';p.run();
assert(~isempty(p.Result)&&height(p.Result.schedule)>0);
app.AISource.Value='실제 TLE 교신 예측';e=app.getAIEvidence();assert(e.totalPasses==height(p.Result.schedule));
[~,best]=max(p.Result.schedule.MaxElevationDeg);p.Choice.Value=best;p.draw();
p.Parent.Parent.SelectedTab=p.Parent;drawnow;
folder=fullfile(root,'results','tle_passes');if ~isfolder(folder),mkdir(folder);end
exportapp(app.Figure,fullfile(folder,'app_preview.png'));
p.Fields.minElevationDeg.Value=90;p.run();assert(~isempty(p.Result)&&isempty(p.Result.schedule));
assert(strcmp(p.Choice.Enable,'off'));
p.Fields.latitudeDeg.Value=0;p.invalidate();assert(isempty(p.Result));
disp('PASS: TLE tab, pass selection, AI evidence, empty schedule and input invalidation.');
end
