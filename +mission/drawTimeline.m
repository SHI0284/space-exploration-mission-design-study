function drawTimeline(ax,r)
cla(ax); hold(ax,'on');
n=height(r.config.targets); m=height(r.config.stations);
for k=1:n+m
    if k<=n
        I=mission.intervals(r.timeSeconds,r.unionObservation(:,k)); color=[.18 .65 .95];
    else
        I=mission.intervals(r.timeSeconds,r.unionStation(:,k-n)); color=[.1 .7 .48];
    end
    for j=1:size(I,1)
        plot(ax,I(j,:)/3600,[k k],'Color',color,'LineWidth',5);
    end
    if ~isempty(I), scatter(ax,I(:,1)/3600,repmat(k,size(I,1),1),12,color,'filled'); end
end
ax.YTick=1:n+m;
ax.YTickLabel=["OBS: "+string(r.config.targets.Name);"GS: "+string(r.config.stations.Name)];
ylim(ax,[.4 n+m+.6]); xlim(ax,[0 r.timeSeconds(end)/3600]); grid(ax,'on');
xlabel(ax,'Hours since UTC epoch'); title(ax,'Access union | lines: duration, dots: start','FontSize',12);
hold(ax,'off');
end
