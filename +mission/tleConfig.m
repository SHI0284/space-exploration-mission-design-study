function c=tleConfig()
% Approximate Global Campus reference point; not a surveyed antenna location.
nowKST=datetime('now','TimeZone','Asia/Seoul');
c=struct('siteName','KHU Global Campus (approx.)','latitudeDeg',37.2456, ...
    'longitudeDeg',127.0762,'altitudeM',0,'minElevationDeg',10,'stepSeconds',10, ...
    'startKST',char(string(nowKST,'yyyy-MM-dd HH:mm:ss')));
end
