function result=run_tle_demo(tleFile,c,showFigure)
% Empty file queries ISS from CelesTrak (two-hour cache); otherwise one local TLE.
if nargin<1,tleFile='';end
if nargin<2,c=mission.tleConfig();end
if nargin<3,showFigure=true;end
if isempty(tleFile),tle=mission.fetchTLE(25544);else,tle=mission.parseTLE(fileread(tleFile));end
result=mission.analyzeTLE(tle,c);
folder=fullfile(fileparts(mfilename('fullpath')),'results','tle_passes');
mission.exportTLE(result,folder);
visible='off';if showFigure,visible='on';end
fig=figure('Name','KHU | TLE pass prediction','Visible',visible,'Color','w','Position',[80 80 1100 550]);
lay=tiledlayout(fig,1,2);sky=polaraxes(lay);sky.Layout.Tile=1;
profile=nexttile(lay,2);mission.drawTLEPass(sky,profile,result,1);
exportgraphics(fig,fullfile(folder,'first_pass.png'),'Resolution',150);
if ~showFigure,close(fig);end
disp(result.schedule);disp(strjoin(result.notes,newline));
end
