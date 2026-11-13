function exportTLE(r,folder)
if ~isfolder(folder),mkdir(folder);end
writetable(r.schedule,fullfile(folder,'passes.csv'));
writetable(r.history,fullfile(folder,'aer_history_utc.csv'));
writetable(r.toolboxIntervals,fullfile(folder,'toolbox_access_intervals.csv'));
for k=1:numel(r.tracks),writetable(r.tracks{k},fullfile(folder,sprintf('pass_%02d_track.csv',k)));end
fid=fopen(fullfile(folder,'source.tle'),'w');assert(fid>=0);fprintf(fid,'%s\n',r.tle.text);fclose(fid);
result=r;save(fullfile(folder,'result.mat'),'result');
meta=struct('satellite',r.tle.name,'catalogNumber',r.tle.catalogNumber,'source',r.tle.source, ...
    'retrievedUTC',string(r.tle.retrievedUTC),'tleEpochUTC',string(r.tle.epochUTC), ...
    'startUTC',string(r.startUTC),'endUTC',string(r.endUTC),'settings',r.settings, ...
    'propagator',r.propagator,'notes',{r.notes});
fid=fopen(fullfile(folder,'metadata.json'),'w','n','UTF-8');assert(fid>=0);
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',jsonencode(meta,'PrettyPrint',true));
end
