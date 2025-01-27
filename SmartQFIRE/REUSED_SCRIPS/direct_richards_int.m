function [xout,yout]=direct_richards_int(x,y,a,b,c,WS_dir_i,aspect_i,slope_i,dt)
% Integrates Richards equations AS FARSITE
% Error in FARSITE equations [1] & [2]
% accounting for slope projection!
% xout, yout in horizontal plane!
%
% INPUT
% 
%
% OUTPUT
% xout,yout         Colum/row vectors (as x,y input)
%
% --------------------------------------------
% ADIMAT calculat abans!!
%[aspect_i]    =getGRDvalue(aspect_str,x,y);
%[slope_i]     =getGRDvalue(slope_str,x,y);

% Centered spatial diferences (As FARSITE (no divided by anything))
% For rows and columns!

[dxs,dys]=FrontCenteredDifferences(x,y);

%% EXPLORING DEBUG
        %alpha_i = atan2((dys),(dxs));
        %[alpha_i]=angular_devaluate(alpha_i,'r'); % Important [0,2pi]
        %plot_normal_line(x,y,alpha_i,(b+c)*dt)
        %plot_ellipses(x,y,a*dt,b*dt,alpha_i)
        %plot_ellipses(x,y,a*dt,b*dt,c*dt,WS_dir_i)
%%

% Project to local surface plane to apply Richards equation
[dxs_L,dys_L]=horz2local(dxs,dys,aspect_i,slope_i);

%get Xt_L Yt_L (as FARSITE)
% equation INCORRECT in FARSITE!!!
%NO VA
%denom =sqrt((b.^2.*(dxs_L.*cos(WS_dir_i)+dys_L.*sin(WS_dir_i)).^2)-(a.^2.*(dxs_L.*sin(WS_dir_i)-dys_L.*cos(WS_dir_i)).^2));
denom_F=sqrt((b.^2.*( dxs_L.*cos(WS_dir_i)+dys_L.*sin(WS_dir_i)).^2)-(a.^2.*(dxs_L.*sin(WS_dir_i)-dys_L.*cos(WS_dir_i)).^2));
denom_R=sqrt((b.^2.*( dxs_L.*cos(WS_dir_i)-dys_L.*sin(WS_dir_i)).^2)+(a.^2.*(dxs_L.*sin(WS_dir_i)+dys_L.*cos(WS_dir_i)).^2));
denom=denom_R;

if ~isreal(denom)
    error('Flank velocity ''a'' cannot be larger than front velocity ''b''')
end

dxt_L=( a.^2.*cos(WS_dir_i).*(dxs_L.*sin(WS_dir_i)+dys_L.*cos(WS_dir_i))-b.^2.*sin(WS_dir_i).*(dxs_L.*cos(WS_dir_i)-dys_L.*sin(WS_dir_i)))./denom+c.*sin(WS_dir_i);
dyt_L=(-a.^2.*sin(WS_dir_i).*(dxs_L.*sin(WS_dir_i)+dys_L.*cos(WS_dir_i))-b.^2.*cos(WS_dir_i).*(dxs_L.*cos(WS_dir_i)-dys_L.*sin(WS_dir_i)))./denom+c.*cos(WS_dir_i);

% desProject to Horizontal plane
% ATENCI�! (dxt_H,dyt_H) s�n rosX_i i rosY_i!!! UTILITZAR!
[dxt_H,dyt_H]=local2horz(dxt_L,dyt_L,aspect_i,slope_i);

%Propagate
xout=x+dxt_H.*dt;
yout=y+dyt_H.*dt;

% Correct for NaNs (not propagation). Copy last point
NaNxy=logical(isnan(xout)+isnan(yout));
xout(NaNxy)=x(NaNxy);
yout(NaNxy)=y(NaNxy);

%% FALLA A L'ADIMAT!!!
% % %Unique points
% % xy=[xout yout];
% % xy=unique(xy,'rows','stable');
% % xout=xy(:,1);
% % yout=xy(:,2);

end