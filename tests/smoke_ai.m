function smoke_ai()
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);
app=launch_mission_designer();cleanup=onCleanup(@()delete(app.Figure)); %#ok<NASGU>
app.Fields.durationDays.Value=.1;app.run();assert(~isempty(app.Result));
app.previewAI();assert(contains(strjoin(string(app.AIPreview.Value)),'observation-and-ground-contact'));
app.AISource.Value='고정 태양 식 실습';app.resetAI();app.previewAI();
assert(contains(strjoin(string(app.AIPreview.Value)),'fixed-sun-shadow-study'));
app.AITab.Parent.SelectedTab=app.AITab;
app.AIInfo.Text='UI 검증: 근거 미리보기 확인 · 실제 API는 아직 호출하지 않았습니다.';
drawnow;exportapp(app.Figure,fullfile(root,'results','ai_tab_preview.png'));
assert(isempty(app.AIHistory));
disp('PASS: AI tab, simulation reset, evidence preview, source switch. No API request made.');
end
