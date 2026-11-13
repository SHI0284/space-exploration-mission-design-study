function drawMap(ax,r,secondsNow)
c=r.config; [~,idx]=min(abs(r.timeSeconds-secondsNow));
cla(ax); hold(ax,'on');
ax.Color=[.04 .08 .14]; ax.XColor=[.55 .65 .77]; ax.YColor=ax.XColor;
persistent coast
if isempty(coast)
    coast=readmatrix(fullfile(fileparts(fileparts(mfilename('fullpath'))),'assets','coastline.csv'));
end
plot(ax,coast(:,1),coast(:,2),'Color',[.35 .47 .55],'LineWidth',.7);
colors=lines(c.satellites);
for s=1:c.satellites
    p=r.positionECEFKm(:,:,s); lat=asind(p(:,3)./vecnorm(p,2,2)); lon=atan2d(p(:,2),p(:,1));
    % Show one orbit around the selected time to keep long runs legible.
    keep=abs(r.timeSeconds-r.timeSeconds(idx))<=3000;
    lo=lon(keep); la=lat(keep); jumps=[false;abs(diff(lo))>180]; lo(jumps)=NaN;
    plot(ax,lo,la,'Color',colors(s,:),'LineWidth',1.1);
    scatter(ax,lon(idx),lat(idx),45,colors(s,:),'filled');
    alpha=deg2rad(c.fovDeg/2); a=6378.137+c.altitudeKm;
    if alpha>=asin(6378.137/a)
        psi=acos(6378.137/a);
    else
        psi=asin(a/6378.137*sin(alpha))-alpha;
    end
    bearing=linspace(0,2*pi,100)'; la0=deg2rad(lat(idx)); lo0=deg2rad(lon(idx));
    fl=asin(sin(la0)*cos(psi)+cos(la0)*sin(psi)*cos(bearing));
    fo=lo0+atan2(sin(bearing)*sin(psi)*cos(la0),cos(psi)-sin(la0)*sin(fl));
    fo=mod(rad2deg(fo)+180,360)-180; fl=rad2deg(fl);
    fo([false;abs(diff(fo))>180])=NaN;
    plot(ax,fo,fl,':','Color',colors(s,:),'LineWidth',1.2);
end
targets=scatter(ax,c.targets.LongitudeDeg,c.targets.LatitudeDeg,70,[1 .7 .25],'p','filled');
stations=scatter(ax,c.stations.LongitudeDeg,c.stations.LatitudeDeg,55,[.25 .9 .7],'^','filled');
targets.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Target',string(c.targets.Name));
stations.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Station',string(c.stations.Name));
legend(ax,[targets stations],{'Targets','Ground stations'},'Location','southwest', ...
    'TextColor',[.85 .9 .95],'Color',[.04 .08 .14],'EdgeColor',[.2 .3 .4]);
xlim(ax,[-180 180]); ylim(ax,[-90 90]); grid(ax,'on');
xlabel(ax,'Longitude (deg)'); ylabel(ax,'Latitude (deg)');
title(ax,sprintf('%s | +%.2f h | dotted: sensor footprint',c.name,r.timeSeconds(idx)/3600), ...
    'Interpreter','none','FontSize',12);
hold(ax,'off');
end
