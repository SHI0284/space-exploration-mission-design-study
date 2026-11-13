function smoke_app()
% Run in a MATLAB session that supports uifigure.
addpath(fileparts(fileparts(mfilename('fullpath'))));
app=launch_mission_designer(); cleanup=onCleanup(@()delete(app.Figure)); %#ok<NASGU>
app.run(); assert(~isempty(app.Result));
app.addCandidate(); assert(numel(app.Candidates)==1);
assert(~startsWith(string(app.Status.Text),"오류:"));
assert(height(app.CompareTable.Data)==1);
app.TimeSlider.Value=1; app.updateMap(); drawnow;
folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'results');
if ~isfolder(folder), mkdir(folder); end
exportapp(app.Figure,fullfile(folder,'app_preview.png'));
app.clearCandidates(); assert(isempty(app.Candidates));
disp('PASS: app construction, analysis, map, candidate add/clear');
end
