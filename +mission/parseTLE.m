function tle=parseTLE(input)
% One 2LE/3LE record. Validate fixed fields/checksums before Toolbox ingestion.
lines=splitlines(strjoin(string(input),newline));lines=strip(lines,'right');
lines=lines(strlength(strtrim(lines))>0);
assert(numel(lines)==2||numel(lines)==3,'mission:TLEFormat','위성 한 개의 2줄 또는 이름 포함 3줄 TLE를 입력하세요.');
name='Satellite';if numel(lines)==3,name=char(strtrim(lines(1)));lines=lines(2:3);end
L1=char(lines(1));L2=char(lines(2));
assert(numel(L1)==69&&numel(L2)==69&&startsWith(L1,'1 ')&&startsWith(L2,'2 '), ...
    'mission:TLEFormat','TLE 데이터 줄은 각각 69자이며 1 / 2로 시작해야 합니다.');
assert(strcmp(L1(3:7),L2(3:7))&&~isempty(regexp(L1(3:7),'^\d{5}$','once')), ...
    'mission:TLEFormat','일치하는 5자리 숫자 카탈로그 번호가 필요합니다. Alpha-5/OMM은 아직 지원하지 않습니다.');
for line={L1,L2}
    s=line{1};ch=s(1:68);digits=ch(ch>='0'&ch<='9');
    checksum=mod(sum(double(digits)-double('0'))+sum(ch=='-'),10);
    assert(s(69)>='0'&&s(69)<='9'&&checksum==str2double(s(69)), ...
        'mission:TLEChecksum','TLE 체크섬이 맞지 않습니다. 원본 두 줄을 다시 확인하세요.');
end
yy=str2double(L1(19:20));doy=str2double(L1(21:32));yr=2000+yy;if yy>=57,yr=1900+yy;end
epoch0=datetime(yr,1,1,'TimeZone','UTC');next=datetime(yr+1,1,1,'TimeZone','UTC');
assert(isfinite(yy)&&isfinite(doy)&&doy>=1&&doy<days(next-epoch0)+1, ...
    'mission:TLEFormat','유효하지 않은 TLE 기준시각입니다.');
inc=str2double(L2(9:16));ecc=str2double(['0.' L2(27:33)]);mm=str2double(L2(53:63));
assert(isfinite(inc)&&inc>=0&&inc<=180&&isfinite(ecc)&&ecc>=0&&ecc<1&&isfinite(mm)&&mm>0, ...
    'mission:TLEFormat','TLE 궤도요소가 유효하지 않습니다.');
if strcmp(name,'Satellite'),name=['NORAD ' strtrim(L1(3:7))];end
name=regexprep(name,'^0\s+','');
tle=struct('name',name,'catalogNumber',str2double(L1(3:7)),'line1',L1,'line2',L2, ...
    'epochUTC',epoch0+days(doy-1),'meanMotionRevPerDay',mm);
tle.text=sprintf('%s\n%s\n%s',name,L1,L2);
tle.source='User supplied TLE';tle.retrievedUTC=NaT('TimeZone','UTC');tle.fromCache=false;
end
