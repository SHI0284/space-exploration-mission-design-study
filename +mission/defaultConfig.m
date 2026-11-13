function c = defaultConfig()
% Reproducible educational scenario. Angles in degrees, distances in km.
c.name = 'Baseline';
c.epochUTC = '2026-11-03 00:00:00';
c.durationDays = 3;
c.stepSeconds = 20;
c.model = 'Two-body';
c.altitudeKm = 600;
c.inclinationDeg = 55;
c.satellites = 3;
c.planes = 3;
c.raanDeg = 0;
c.phaseDeg = 0;
c.fovDeg = 60; % Full cone angle, nadir pointing.
c.minElevationDeg = 10;
c.targets = table({'Seoul';'Busan';'Jeju'},[37.5665;35.1796;33.4996], ...
    [126.9780;129.0756;126.5312], ...
    'VariableNames',{'Name','LatitudeDeg','LongitudeDeg'});
c.stations = table({'Daejeon'},36.3504,127.3845, ...
    'VariableNames',{'Name','LatitudeDeg','LongitudeDeg'});
end
