function [schedule,tracks]=passSchedule(utc,az,el,rangeKm,mask)
% Linear interpolation at threshold crossings; no extrapolation beyond window.
utc=utc(:);az=az(:);el=el(:);rangeKm=rangeKm(:);t=seconds(utc-utc(1));
assert(numel(t)>=2&&all(diff(t)>0)&&numel(az)==numel(t)&&numel(el)==numel(t)&& ...
    numel(rangeKm)==numel(t)&&all(isfinite([az;el;rangeKm])));
% False -> true starts a run; true -> false closes it. Window edges are clipped.
above=el>=mask;edges=diff([false;above;false]);a=find(edges==1);b=find(edges==-1)-1;
start=[];finish=[];peak=[];maxEl=[];peakRange=[];startAz=[];endAz=[];clippedStart=[];clippedEnd=[];tracks={};
% Interpolate 359 -> 1 degrees through north, not backwards through 180.
unwrapped=unwrap(deg2rad(az))*180/pi;
for k=1:numel(a)
    i=a(k);j=b(k);lo=t(i);hi=t(j);
    if i>1,lo=t(i-1)+(mask-el(i-1))/(el(i)-el(i-1))*(t(i)-t(i-1));end
    if j<numel(t),hi=t(j)+(mask-el(j))/(el(j+1)-el(j))*(t(j+1)-t(j));end
    if hi<=lo,continue;end
    tt=unique([lo;t(i:j);hi]);ee=interp1(t,el,tt);rr=interp1(t,rangeKm,tt);
    aa=mod(interp1(t,unwrapped,tt),360);[mx,p]=max(ee);
    start(end+1,1)=lo;finish(end+1,1)=hi;peak(end+1,1)=tt(p); %#ok<AGROW>
    maxEl(end+1,1)=mx;peakRange(end+1,1)=rr(p);startAz(end+1,1)=aa(1);endAz(end+1,1)=aa(end); %#ok<AGROW>
    clippedStart(end+1,1)=i==1;clippedEnd(end+1,1)=j==numel(t); %#ok<AGROW>
    tracks{end+1,1}=table(utc(1)+seconds(tt),tt,aa,ee,rr, ...
        'VariableNames',{'TimeUTC','ElapsedSeconds','AzimuthDeg','ElevationDeg','RangeKm'}); %#ok<AGROW>
end
% Keep an empty result typed and column-shaped for tables and CSV exports.
start=start(:);finish=finish(:);peak=peak(:);maxEl=maxEl(:);peakRange=peakRange(:);
startAz=startAz(:);endAz=endAz(:);clippedStart=logical(clippedStart(:));clippedEnd=logical(clippedEnd(:));
startUTC=utc(1)+seconds(start);endUTC=utc(1)+seconds(finish);peakUTC=utc(1)+seconds(peak);
startKST=startUTC;startKST.TimeZone='Asia/Seoul';endKST=endUTC;endKST.TimeZone='Asia/Seoul';
peakKST=peakUTC;peakKST.TimeZone='Asia/Seoul';
schedule=table((1:numel(start))',startKST,endKST,peakKST,(finish-start)/60,maxEl, ...
    startAz,endAz,peakRange,clippedStart,clippedEnd,startUTC,endUTC, ...
    'VariableNames',{'Pass','StartKST','EndKST','PeakKST','DurationMinutes','MaxElevationDeg', ...
    'StartAzimuthDeg','EndAzimuthDeg','RangeAtPeakKm','StartClipped','EndClipped','StartUTC','EndUTC'});
for key={'StartKST','EndKST','PeakKST','StartUTC','EndUTC'},schedule.(key{1}).Format='yyyy-MM-dd HH:mm:ss';end
end
