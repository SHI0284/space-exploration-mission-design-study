function [sc,sat,gs]=walkerScenario(c)
% Shared scenario construction for numerical analysis and the native 3D viewer.
validateattributes(c.satellites,{'numeric'},{'scalar','integer','positive'});
validateattributes(c.planes,{'numeric'},{'scalar','integer','positive'});
assert(mod(c.satellites,c.planes)==0,'Total satellites must be divisible by planes.');
validateattributes(c.phasing,{'numeric'},{'scalar','integer','>=',0,'<',c.planes});
validateattributes(c.radiusKm,{'numeric'},{'scalar','finite','>',6378.137});
validateattributes(c.inclinationDeg,{'numeric'},{'scalar','>=',0,'<=',180});
validateattributes(c.minElevationDeg,{'numeric'},{'scalar','>=',0,'<=',90});
validateattributes(c.durationHours,{'numeric'},{'scalar','finite','positive'});
validateattributes(c.stepSeconds,{'numeric'},{'scalar','finite','positive'});
ratio=c.durationHours*3600/c.stepSeconds;
assert(ratio>=1&&abs(ratio-round(ratio))<1e-8,'Duration must be a positive integer multiple of stepSeconds.');
assert(height(c.sites)>0&&all(isfinite(c.sites.LatitudeDeg))&& ...
    all(abs(c.sites.LatitudeDeg)<=90)&&all(isfinite(c.sites.LongitudeDeg))&& ...
    all(abs(c.sites.LongitudeDeg)<=180)&&all(isfinite(c.sites.AltitudeM))&& ...
    all(c.sites.AltitudeM>=0),'Invalid ground sites.');
epoch=datetime(c.epochUTC,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC');
sc=satelliteScenario(epoch,epoch+hours(c.durationHours),c.stepSeconds);
sat=walkerDelta(sc,c.radiusKm*1000,c.inclinationDeg,c.satellites,c.planes,c.phasing, ...
    'RAAN',c.raanDeg,'ArgumentOfLatitude',c.argumentLatitudeDeg, ...
    'Name','WalkerStudy','OrbitPropagator','two-body-keplerian');
gs=groundStation(sc,c.sites.LatitudeDeg',c.sites.LongitudeDeg', ...
    'Altitude',c.sites.AltitudeM','Name',c.sites.Name', ...
    'MinElevationAngle',c.minElevationDeg);
end
