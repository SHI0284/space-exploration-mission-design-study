function exportResult(r,folder)
if ~isfolder(folder), mkdir(folder); end
save(fullfile(folder,'result.mat'),'r','-v7.3');
config=r.config; save(fullfile(folder,'scenario.mat'),'config');
writetable(r.summary,fullfile(folder,'target_summary.csv'));
writetable(r.elements,fullfile(folder,'orbits.csv'));
epoch=datetime(r.config.epochUTC,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC');
E=r.events; E.ObservationUTC=epoch+seconds(E.StartSeconds);
E.NextContactUTC=epoch+seconds(E.ContactSeconds);
writetable(E,fullfile(folder,'observations_and_wait.csv'));
G=r.contacts; G.StartUTC=epoch+seconds(G.StartSeconds); G.EndUTC=epoch+seconds(G.EndSeconds);
writetable(G,fullfile(folder,'ground_contacts.csv'));
f=figure('Visible','off','Color','w','Position',[100 100 1200 800]);
cleanup=onCleanup(@()close(f)); %#ok<NASGU>
ax=subplot(2,1,1,'Parent',f); mission.drawMap(ax,r,0);
ax=subplot(2,1,2,'Parent',f); mission.drawTimeline(ax,r);
exportgraphics(f,fullfile(folder,'overview.png'),'Resolution',160);
fid=fopen(fullfile(folder,'model_notes.txt'),'w');
assert(fid>=0,'Could not write model notes.');
cleanupFile=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,['Scenario: %s\nEpoch UTC: %s\nModel: %s\nStep: %.3f s\n' ...
    'Spherical Earth R=6378.137 km; circular orbits; fixed nadir full-cone FOV.\n' ...
    'Access is left-held on the sample grid; short passes may be missed.\n' ...
    'One instantaneous acquisition at each satellite-target access start.\n' ...
    'Wait is to the SAME satellite next ground contact, not transmission completion.\n' ...
    'Unresolved events are right-censored at analysis end; blank waits are not zero.\n' ...
    'Max gap includes the start and end boundaries of the analysis window.\n' ...
    'No cloud, illumination, slew, contention, storage, link budget, or data-rate model.\n'], ...
    r.config.name,r.config.epochUTC,r.config.model,r.config.stepSeconds);
end
