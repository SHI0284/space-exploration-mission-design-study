function [elevation, offNadir] = geometry(r,lat,lon)
% Geocentric surface coordinates on a spherical Earth.
q=[cosd(lat)*cosd(lon),cosd(lat)*sind(lon),sind(lat)];
rho=r-6378.137*q;
d=vecnorm(rho,2,2);
elevation=asind(max(-1,min(1,(rho*q')./d)));
% Satellite-to-target direction compared with satellite nadir.
offNadir=acosd(max(-1,min(1,sum(rho.*r,2)./(d.*vecnorm(r,2,2)))));
end
