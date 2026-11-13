function result = run_lighting_demo(showFigure)
% Lecture 10: REAL Aerospace Toolbox eclipse analysis, not a custom shadow model.
% Run: result = run_lighting_demo;  Outputs: results/lighting/
% Spacecraft illumination and target daylight are deliberately kept separate.
if nargin<1, showFigure=true; end
root=fileparts(mfilename('fullpath')); addpath(root);
assert(exist('ephConstants405.mat','file')~=0,'mission:EphemerisMissing', ...
    ['Ephemeris Data for Aerospace Toolbox is missing. Run aeroDataPackage to install it. ' ...
    'For a fixed-Sun lecture experiment that runs without this data, use run_shadow_geometry_demo.']);

folder=fullfile(root,'results','lighting'); if ~isfolder(folder), mkdir(folder); end
epoch=datetime(2026,11,5,0,0,0,'TimeZone','UTC');
dt=5; stop=epoch+days(1); models={'dual-cone','cylindrical'};
rows=cell(2,7); runs=cell(2,1);
for k=1:2
    % 1. Build the orbit directly with Aerospace Toolbox (SI units).
    sc=satelliteScenario(epoch,stop,dt);
    sat=satellite(sc,6978137,0,55,0,0,0, ...
        'OrbitPropagator','two-body-keplerian','Name','StudySat600');
    [position,velocity,time]=states(sat,'CoordinateFrame','inertial');
    elements=orbitalElements(sat);

    % 2. Attach the shadow model. Lunar occultation is excluded for this lesson.
    ecl=eclipse(sat,'EclipseModel',models{k},'IncludeLunarEclipse',false);
    [fraction,time,eclipseType]=eclipseStatus(ecl);
    I=eclipseIntervals(ecl);
    percentage=eclipsePercentage(ecl);
    t=seconds(time(:)-epoch); f=fraction(:); step=diff(t);
    assert(all(isfinite(f)&f>=0&f<=1),'Solar fraction must be in [0,1].');
    full=f<=1e-10; partial=f>1e-10&f<1-1e-10;
    fullMinutes=sum(step.*full(1:end-1))/60;
    partialMinutes=sum(step.*partial(1:end-1))/60;
    longest=0; if height(I)>0, longest=max(I.Duration)/60; end

    % 3. Simple battery lesson: 100 W load, no solar input during any eclipse.
    % Conservative ideal load energy, not flight battery nameplate sizing.
    idealWh=100*longest/60;
    rows(k,:)={string(models{k}),percentage,height(I),fullMinutes,partialMinutes,longest,idealWh};
    history=table(time(:),f,string(eclipseType(:)), ...
        'VariableNames',{'TimeUTC','VisibleSolarDiskFraction','EarthEclipseType'});
    writetable(history,fullfile(folder,[models{k} '_history.csv']));
    writetable(I,fullfile(folder,[models{k} '_intervals.csv']));
    runs{k}=struct('model',models{k},'timeUTC',time(:),'fraction',f, ...
        'intervals',I,'percentage',percentage,'history',history, ...
        'positionInertialM',position,'velocityInertialMps',velocity,'elements',elements);
    if k==1

        % 4. Target daylight is a separate eclipse analysis at the ground site.
        gs=groundStation(sc,37.5665,126.978,'Name','Seoul','MinElevationAngle',10);
        siteEclipse=eclipse(gs,'EclipseModel','dual-cone','IncludeLunarEclipse',false);
        siteFraction=eclipseStatus(siteEclipse); siteFraction=siteFraction(:);
        ac=access(sat,gs); geometric=accessStatus(ac); geometric=geometric(:);
        % This is a daylight gate on geometric visibility, not a camera scheduler.
        daylight=siteFraction>=1-1e-10;
        usable=geometric&daylight;
        target=table(time(:),siteFraction,geometric,usable, ...
            'VariableNames',{'TimeUTC','TargetVisibleSolarDiskFraction', ...
            'GeometricAccessAbove10Deg','AccessAndTargetDaylight'});
        writetable(target,fullfile(folder,'seoul_daylight_access.csv'));
        accessTable=accessIntervals(ac);
        writetable(accessTable,fullfile(folder,'seoul_geometric_access.csv'));
        lit=mission.intervals(t,usable);
        litTable=table(epoch+seconds(lit(:,1)),epoch+seconds(lit(:,2)), ...
            lit(:,2)-lit(:,1),'VariableNames',{'StartUTC','EndUTC','DurationSeconds'});
        writetable(litTable,fullfile(folder,'seoul_daylight_access_intervals.csv'));
        assert(all(~usable|geometric),'Daylight access must be a subset of geometric access.');
        targetSummary=table(sum(step.*geometric(1:end-1))/60,sum(step.*usable(1:end-1))/60, ...
            'VariableNames',{'GeometricAccessMinutes','DaylightAccessMinutes'});
    else
        assert(all(f==0|f==1),'Cylindrical model should be binary.');
    end
end
summary=cell2table(rows,'VariableNames',{'Model','ToolboxEclipsePercentage','EclipseIntervals', ...
    'SampledUmbraMinutes','SampledPenumbraMinutes','LongestEclipseMinutes','Ideal100WLoadEnergyWh'});
assert(any(runs{1}.fraction>0 & runs{1}.fraction<1),'Expected penumbra samples in this scenario.');
writetable(summary,fullfile(folder,'model_comparison.csv'));
writetable(targetSummary,fullfile(folder,'daylight_access_summary.csv'));
result=struct('runs',{runs},'summary',summary,'target',target,'targetSummary',targetSummary,'sampleSeconds',dt);
save(fullfile(folder,'lighting_result.mat'),'result');
% 5. Visual comparison: full orbit, short boundary transition, ground daylight.
visible='off'; if showFigure, visible='on'; end
fig=figure('Name','OrbitLab | Lighting and Eclipse','Visible',visible, ...
    'Color','w','Position',[80 80 1200 900]);
layout=tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
h=seconds(runs{1}.timeUTC-epoch)/3600;
ax=nexttile(layout); plot(ax,h,runs{1}.fraction,'LineWidth',1.5); hold(ax,'on');
plot(ax,h,runs{2}.fraction,'--','LineWidth',1); xlim(ax,[0 6]); ylim(ax,[-.05 1.05]); grid(ax,'on');
title(ax,'Spacecraft illumination | 600 km, 55 deg | first 6 hours');
ylabel(ax,'Visible Sun fraction'); legend(ax,models,'Location','eastoutside');
ax=nexttile(layout); idx=find(runs{1}.fraction>0 & runs{1}.fraction<1,1);
relative=seconds(runs{1}.timeUTC-runs{1}.timeUTC(idx));
plot(ax,relative,runs{1}.fraction,'-o','MarkerSize',3,'LineWidth',1.5); hold(ax,'on');
plot(ax,relative,runs{2}.fraction,'--','LineWidth',1); xlim(ax,[-60 60]); ylim(ax,[-.05 1.05]); grid(ax,'on');
title(ax,'One shadow boundary: dual-cone resolves partial occultation');
xlabel(ax,'Seconds relative to first partial-eclipse sample'); ylabel(ax,'Visible Sun fraction');
ax=nexttile(layout); stairs(ax,h,target.TargetVisibleSolarDiskFraction,'Color',[.85 .55 .05],'LineWidth',1.3); hold(ax,'on');
stairs(ax,h,double(target.GeometricAccessAbove10Deg)*.8,'Color',[.15 .45 .85],'LineWidth',1.2);
stairs(ax,h,double(target.AccessAndTargetDaylight)*.6,'Color',[.1 .65 .35],'LineWidth',1.5);
ylim(ax,[-.05 1.1]); xlim(ax,[0 24]); grid(ax,'on');
title(ax,'Seoul: ground illumination and visibility are separate conditions');
xlabel(ax,'Hours since 2026-11-05 00:00 UTC'); ylabel(ax,'Fraction / scaled flags');
legend(ax,{'Target Sun fraction','Geometric access (0.8)','Access + target daylight (0.6)'},'Location','eastoutside');
exportgraphics(fig,fullfile(folder,'lighting_comparison.png'),'Resolution',150);
if ~showFigure, close(fig); end
disp(summary); disp(targetSummary);
fprintf('PASS: solar fraction range, cylindrical binary status, penumbra samples, daylight subset.\n');
fprintf('Outputs: %s\n',folder);
end
