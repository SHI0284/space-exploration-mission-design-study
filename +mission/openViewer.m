function viewer = openViewer(r)
% Optional course-toolbox integration, using the SAME computed ephemeris.
assert(exist('satelliteScenario','file')~=0, ...
    'satelliteScenario가 필요합니다. Aerospace Toolbox 설치와 라이선스를 확인하세요.');
c=r.config;
epoch=datetime(c.epochUTC,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC');
sc=satelliteScenario(epoch,epoch+seconds(r.timeSeconds(end)),c.stepSeconds);
for s=1:c.satellites
    tt=timetable(epoch+seconds(r.timeSeconds),r.positionECEFKm(:,:,s)*1000);
    satellite(sc,tt,'CoordinateFrame','ecef','Name',sprintf('Sat %d',s));
end
groundStation(sc,c.stations.LatitudeDeg,c.stations.LongitudeDeg, ...
    'MinElevationAngle',c.minElevationDeg,'Name',string(c.stations.Name));
groundTrack(sc.Satellites);
viewer=satelliteScenarioViewer(sc);
end
