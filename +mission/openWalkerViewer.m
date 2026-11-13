function viewer=openWalkerViewer(c)
% Reconstruct the exact baseline and display native Toolbox orbit graphics.
if nargin<1,c=mission.walkerConfig();end
[sc,~,~]=mission.walkerScenario(c);
viewer=satelliteScenarioViewer(sc,'ShowDetails',true);
end
