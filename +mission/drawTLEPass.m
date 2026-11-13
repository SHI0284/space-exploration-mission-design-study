function drawTLEPass(sky,profile,r,index)
% Sky projection: north at top, azimuth clockwise, zenith at center.
cla(sky);legend(sky,'off');cla(profile);sky.ThetaZeroLocation='top';sky.ThetaDir='clockwise';
sky.RLim=[0 90];sky.RTick=[0 30 60 90];sky.RTickLabel={'90°','60°','30°','0°'};
sky.ThetaTick=0:45:315;sky.ThetaTickLabel={'N','NE','E','SE','S','SW','W','NW'};
hold(sky,'on');polarplot(sky,linspace(0,2*pi,361),repmat(90-r.settings.minElevationDeg,1,361),'k:');
if isempty(r.tracks)
    title(sky,'24시간 내 최소 고각 이상 패스 없음');
    t=r.history.TimeUTC;t.TimeZone='Asia/Seoul';
    plot(profile,t,r.history.ElevationDeg);title(profile,'24시간 고각 (KST)');
else
    T=r.tracks{index};rho=90-T.ElevationDeg;theta=deg2rad(T.AzimuthDeg);
    polarplot(sky,theta,rho,'Color',[.05 .4 .7],'LineWidth',2);
    p1=polarplot(sky,theta(1),rho(1),'go','MarkerFaceColor',[.1 .65 .2]);
    p2=polarplot(sky,theta(end),rho(end),'rs','MarkerFaceColor',[.9 .2 .2]);
    legend(sky,[p1 p2],{'구간 시작','구간 종료'},'Location','southoutside');
    title(sky,sprintf('%s | 패스 %d',r.tle.name,index),'Interpreter','none');
    t=T.TimeUTC;t.TimeZone='Asia/Seoul';plot(profile,t,T.ElevationDeg,'LineWidth',1.7);
    title(profile,sprintf('최대 고각 %.1f° | %.1f분',r.schedule.MaxElevationDeg(index),r.schedule.DurationMinutes(index)));
end
hold(profile,'on');yline(profile,r.settings.minElevationDeg,'k:');
ylabel(profile,'Elevation (deg)');xlabel(profile,'KST (UTC+09:00)');grid(profile,'on');
end
