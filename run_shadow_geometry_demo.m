function result=run_shadow_geometry_demo(showFigure)
% Runnable study experiment without the optional Ephemeris Data package.
% Aerospace Toolbox supplies the orbit. Shadow geometry is our lecture code.
% The Sun is FIXED on +ICRF X at 1 AU: NOT the real Sun on the epoch date.
if nargin<1, showFigure=true; end
root=fileparts(mfilename('fullpath')); addpath(root);
folder=fullfile(root,'results','shadow_geometry'); if ~isfolder(folder), mkdir(folder); end
epoch=datetime(2026,11,5,'TimeZone','UTC'); dt=1;
sc=satelliteScenario(epoch,epoch+hours(3),dt);
R=6378137; a=R+600000; mu=3.986004418e14;
sat=satellite(sc,a,0,55,0,0,0,'OrbitPropagator','two-body-keplerian','Name','StudySat');
[r,~,utc]=states(sat,'CoordinateFrame','inertial'); r=squeeze(r)';
elements=orbitalElements(sat);
t=seconds(utc(:)-epoch); sun=repmat([149597870700,0,0],size(r,1),1);
Ds=sun-r; Dp=-r; Rs=695700000;
rhoS=asin(Rs./vecnorm(Ds,2,2)); rhoP=asin(R./vecnorm(Dp,2,2));
eta=acos(max(-1,min(1,sum(Ds.*Dp,2)./(vecnorm(Ds,2,2).*vecnorm(Dp,2,2)))));
total=eta<=rhoP-rhoS & rhoP>=rhoS;
annular=eta<=rhoS-rhoP & rhoS>rhoP;
partial=eta<rhoP+rhoS & ~total & ~annular;
fraction=ones(size(t)); fraction(total)=0;
fraction(annular)=1-(rhoP(annular)./rhoS(annular)).^2;
% Apparent angular disk overlap (small-angle planar disk approximation).
d=eta(partial); x=rhoS(partial); y=rhoP(partial);
clamp=@(v)max(-1,min(1,v));
overlap=x.^2.*acos(clamp((d.^2+x.^2-y.^2)./(2*d.*x)))+ ...
    y.^2.*acos(clamp((d.^2+y.^2-x.^2)./(2*d.*y)))- ...
    .5*sqrt(max(0,(-d+x+y).*(d+x-y).*(d-x+y).*(d+x+y)));
fraction(partial)=max(0,min(1,1-overlap./(pi*x.^2)));
cylinder=r(:,1)<0 & hypot(r(:,2),r(:,3))<R;
shadow=total|partial|annular;
I=mission.intervals(t,shadow); C=mission.intervals(t,cylinder);
period=2*pi*sqrt(a^3/mu);
theorySeconds=period*asin(R/a)/pi; % beta=0, circular orbit, cylindrical shadow.
assert(~isempty(C)&&abs((C(1,2)-C(1,1))-theorySeconds)<=2*dt, ...
    'Cylindrical duration must agree with the analytic circular-orbit solution.');
assert(any(partial)&&any(total)&&any(~shadow));
assert(all(fraction>=0&fraction<=1));
assert(all(abs(vecnorm(r,2,2)-a)<1),'Circular radius check failed.');
history=table(utc(:),fraction,double(~cylinder),rad2deg(eta),rad2deg(rhoS),rad2deg(rhoP), ...
    'VariableNames',{'TimeUTC','AngularDiskSunFraction','CylindricalSunFraction','SeparationDeg','SunRadiusDeg','EarthRadiusDeg'});
intervals=table(epoch+seconds(I(:,1)),epoch+seconds(I(:,2)),I(:,2)-I(:,1), ...
    'VariableNames',{'StartUTC','EndUTC','DurationSeconds'});
summary=table(period/60,theorySeconds/60,(C(1,2)-C(1,1))/60, ...
    (I(1,2)-I(1,1))/60,sum(partial(1:end-1))*dt,100*(I(1,2)-I(1,1))/3600, ...
    'VariableNames',{'PeriodMinutes','TheoryCylinderMinutes','SampledCylinderMinutes', ...
    'FirstAnyEclipseMinutes','PartialSecondsIn3Hours','Ideal100WFirstEclipseWh'});
result=struct('history',history,'intervals',intervals,'summary',summary,'elements',elements, ...
    'assumption','Fixed Sun on +ICRF X at 1 AU, beta=0; not actual-date ephemeris');
writetable(history,fullfile(folder,'history.csv')); writetable(intervals,fullfile(folder,'intervals.csv'));
writetable(summary,fullfile(folder,'summary.csv')); save(fullfile(folder,'result.mat'),'result');
visible='off'; if showFigure,visible='on';end
fig=figure('Name','Lecture 10 | Shadow geometry study','Visible',visible,'Color','w','Position',[80 80 1100 750]);
lay=tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax=nexttile(lay); plot(ax,t/60,fraction,'LineWidth',1.7); hold(ax,'on');
plot(ax,t/60,double(~cylinder),'--','LineWidth',1.2); grid(ax,'on'); ylim(ax,[-.05 1.05]);
xlabel(ax,'Elapsed time (minutes)'); ylabel(ax,'Visible solar disk fraction');
title(ax,{'600 km circular orbit | Aerospace Toolbox states + lecture shadow geometry', ...
    'Fixed Sun along +X, beta = 0 (not real-date solar ephemeris)'});
legend(ax,{'Finite Sun: angular-disk approximation','Cylindrical shadow'},'Location','southoutside');
idx=find(partial,1); ax=nexttile(lay);
plot(ax,t-t(idx),fraction,'-o','MarkerSize',3,'LineWidth',1.5); hold(ax,'on');
plot(ax,t-t(idx),double(~cylinder),'--','LineWidth',1.2);
xlim(ax,[-25 25]); ylim(ax,[-.05 1.05]); grid(ax,'on');
xlabel(ax,'Seconds relative to first partial-eclipse sample'); ylabel(ax,'Visible solar disk fraction');
title(ax,'Shadow entry: the finite Sun produces a penumbra transition');
exportgraphics(fig,fullfile(folder,'shadow_comparison.png'),'Resolution',150);
if ~showFigure,close(fig);end
disp(summary); disp(intervals);
fprintf('PASS: circular radius, analytic eclipse duration, sunlight/penumbra/umbra, fraction bounds.\n');
end
