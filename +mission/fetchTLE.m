function tle=fetchTLE(catalogNumber)
% CelesTrak single-object query; reuse a validated download for two hours.
validateattributes(catalogNumber,{'numeric'},{'scalar','integer','>=',1,'<=',99999});
root=fileparts(fileparts(mfilename('fullpath')));folder=fullfile(root,'results','tle_cache');
if ~isfolder(folder),mkdir(folder);end
file=fullfile(folder,sprintf('%d.mat',catalogNumber));nowUTC=datetime('now','TimeZone','UTC');
if isfile(file)
    x=load(file,'tle');age=hours(nowUTC-x.tle.retrievedUTC);
    if age>=0&&age<2
        mission.parseTLE(x.tle.text);tle=x.tle;tle.fromCache=true;return;
    end
end
url=sprintf('https://celestrak.org/NORAD/elements/gp.php?CATNR=%d&FORMAT=TLE',catalogNumber);
try
    body=webread(url,weboptions('ContentType','text','Timeout',25));
catch
    error('mission:TLEDownload','CelesTrak 다운로드에 실패했습니다. 자동 재시도하지 않습니다. 저장한 TLE 파일을 불러오거나 나중에 다시 시도하세요.');
end
tle=mission.parseTLE(body);
assert(tle.catalogNumber==catalogNumber,'mission:TLEFormat','요청 번호와 응답 위성 번호가 다릅니다.');
tle.source=url;tle.retrievedUTC=nowUTC;tle.fromCache=false;
save(file,'tle');
end
