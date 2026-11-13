function [r, elements] = propagate(c,t)
% Circular two-body or averaged first-order J2; spherical rotating Earth.
R=6378.137; mu=398600.4418; J2=1.08262668e-3;
a=R+c.altitudeKm; n=sqrt(mu/a^3); inc=deg2rad(c.inclinationDeg);
odot=0; udot=n;
if strcmp(c.model,'J2 secular')
    z=J2*(R/a)^2;
    odot=-1.5*z*n*cos(inc);
    udot=n+1.5*z*n*(4*cos(inc)^2-1);
end
epoch=datetime(c.epochUTC,'InputFormat','yyyy-MM-dd HH:mm:ss','TimeZone','UTC');
jd=posixtime(epoch)/86400+2440587.5;
D=jd-2451545; T=D/36525;
theta=deg2rad(mod(280.46061837+360.98564736629*D+0.000387933*T^2-T^3/38710000,360));
t=t(:); earth=theta+7.2921151467e-5*t;
r=zeros(numel(t),3,c.satellites);
plane=zeros(c.satellites,1); raan=plane; phase=plane;
perPlane=c.satellites/c.planes;
for s=1:c.satellites
    p=floor((s-1)/perPlane); slot=mod(s-1,perPlane);
    plane(s)=p+1;
    raan(s)=mod(c.raanDeg+360*p/c.planes,360);
    phase(s)=mod(c.phaseDeg+360*slot/perPlane+360*p/c.satellites,360);
    O=deg2rad(raan(s))+odot*t; u=deg2rad(phase(s))+udot*t;
    x=a*(cos(O).*cos(u)-sin(O).*sin(u)*cos(inc));
    y=a*(sin(O).*cos(u)+cos(O).*sin(u)*cos(inc));
    z=a*sin(u)*sin(inc);
    r(:,:,s)=[cos(earth).*x+sin(earth).*y,-sin(earth).*x+cos(earth).*y,z];
end
elements=table((1:c.satellites)',plane,repmat(c.altitudeKm,c.satellites,1), ...
    repmat(c.inclinationDeg,c.satellites,1),raan,phase, ...
    'VariableNames',{'Satellite','Plane','AltitudeKm','InclinationDeg','RAANDeg','ArgumentOfLatitudeDeg'});
end
