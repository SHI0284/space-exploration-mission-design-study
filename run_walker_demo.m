function result=run_walker_demo(showFigure,showViewer,c)
% Lecture 11: Walker-Delta, native Toolbox access, local LOS, phasing comparison.
% run_walker_demo(true,true) opens plots and the native 3D scenario viewer.
if nargin<1,showFigure=true;end
if nargin<2,showViewer=false;end
if nargin<3,c=mission.walkerConfig();end
root=fileparts(mfilename('fullpath'));folder=fullfile(root,'results','walker');
if ~isfolder(folder),mkdir(folder);end
phases=unique([c.phasing,c.comparePhasing(:)'],'stable');
assert(all(isfinite(phases)&phases>=0&phases<c.planes&phases==floor(phases)), ...
    'Every comparison F must be an integer in [0, planes-1].');
runs=cell(numel(phases),1);comparison=table();
for k=1:numel(phases)
    cfg=c;cfg.phasing=phases(k);
    fprintf('Walker %g:%d/%d/%d, %g h, step %g s\n',cfg.inclinationDeg,cfg.satellites,cfg.planes,cfg.phasing,cfg.durationHours,cfg.stepSeconds);
    runs{k}=mission.analyzeWalker(cfg);comparison=[comparison;runs{k}.summary]; %#ok<AGROW>
end
result=struct('kind','walker-constellation-study','settings',c,'baseline',runs{1}, ...
    'runs',{runs},'comparison',comparison);
save(fullfile(folder,'result.mat'),'result');
writetable(comparison,fullfile(folder,'comparison.csv'));
writetable(result.baseline.elements,fullfile(folder,'orbital_elements.csv'));
for k=1:numel(runs)
    r=runs{k};prefix=sprintf('F%d_',r.config.phasing);
    writetable(r.gaps,fullfile(folder,[prefix 'service_gaps.csv']));
    for g=1:height(c.sites)
        name=sprintf('%ssite%d_',prefix,g);
        T=table(r.timeUTC,r.counts(:,g),'VariableNames',{'TimeUTC','VisibleCount'});
        writetable(T,fullfile(folder,[name 'counts.csv']));
        writetable(r.perSatellite{g},fullfile(folder,[name 'satellite_access.csv']));
        writetable(r.accessIntervals{g},fullfile(folder,[name 'access_intervals.csv']));
    end
end
vis='off';if showFigure,vis='on';end
fig=figure('Name','Walker-Delta constellation study','Visible',vis,'Color','w','Position',[80 60 1200 850]);
lay=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');b=result.baseline;
ax=nexttile(lay);stairs(ax,b.timeSeconds/3600,b.counts,'LineWidth',1);hold(ax,'on');
yline(ax,4,'k--');grid(ax,'on');xlabel(ax,'Elapsed hours');ylabel(ax,'Visible satellites');
legend(ax,cellstr(c.sites.Name),'Location','best');title(ax,sprintf('Baseline F=%d | mask %g deg',c.phasing,c.minElevationDeg));
ax=nexttile(lay);imagesc(ax,b.timeSeconds/3600,1:c.satellites,double(b.visible(:,:,1)'));axis(ax,'xy');
colormap(ax,[.94 .95 .97;.08 .45 .65]);clim(ax,[0 1]);xlabel(ax,'Elapsed hours');ylabel(ax,'Satellite index');
title(ax,sprintf('%s access: blue = visible',c.sites.Name(1)));
ax=nexttile(lay);hold(ax,'on');
for k=1:numel(runs),stairs(ax,runs{k}.timeSeconds/3600,runs{k}.counts(:,1),'LineWidth',1);end
grid(ax,'on');xlabel(ax,'Elapsed hours');ylabel(ax,'Visible satellites');
legend(ax,cellstr("F="+string(phases)),'Location','best');title(ax,'Phasing comparison at first site');
ax=nexttile(lay);E=b.elements;
u=mod(E.ArgumentOfPeriapsis+E.TrueAnomaly,360);
scatter(ax,E.RightAscensionOfAscendingNode,u,50,'filled');grid(ax,'on');
xlim(ax,[-10 360]);ylim(ax,[-10 360]);xlabel(ax,'RAAN (deg)');ylabel(ax,'Initial argument of latitude (deg)');
title(ax,sprintf('%g : %d / %d / %d | radius %g km',c.inclinationDeg,c.satellites,c.planes,c.phasing,c.radiusKm));
title(lay,'Ideal Walker-Delta | Two-body orbit | Geometric visibility, not navigation accuracy');
exportgraphics(fig,fullfile(folder,'walker_overview.png'),'Resolution',150);
if ~showFigure,close(fig);end
disp(comparison);
if showViewer,mission.openWalkerViewer(c);end
end
