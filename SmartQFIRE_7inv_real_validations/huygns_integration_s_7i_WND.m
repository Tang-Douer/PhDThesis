function [xyout]=huygns_integration_s_7i_WND(x,y,Mf,Mx,SAV,Wo,Depth,aspect,slope,NewSpeedMapGRD,NewDirMapGRD,At,dt, res)
%%   huygns_integration_s()
%
%   Steps the integration time At into corresponding little steps for integrations
%   and then calculates a,b,c and runs the corresponding model
% INPUTS
%    x,y           column vectors with coordinates to be propagated
%    fuel_depth    fuel_depth GRD matrix
%    aspect        aspect GRD STRUCT (from loadEsriGRD)
%    slope         slope GRD STRUCT (from loadEsriGRD)
%    At            is ONE time to be integrated to!
%    dt            fixed diff eq. integration time (s)
%    res           degridding distance ressolution (m)
%
% OUTPUTS
%   xyout          Colum xy vectors (Nx2) (if not, they are transposed)
% INFO:
%   Implemented function from Richards1990 (pag 1168)
%   IMPORTANT! el primer i �ltim valor d'x i y no poden estar DUPLICATS!
%   integrates using Euler and Predictor-Corrector methods along dt
%
% HISTORY:
%   Modificaci� 11/12/14: es passa fuel depth i Imfw per calcular ROS DURANT
%       la integraci�! (necessari per a combustibles/terreny canviant (incloure inclinaci�!)
%   Modificaci� 10/12/14: dt �s un temps t'integraci� constant, es menat�
%       petit i s'integra fins a At
%       Alerta! Durant la integraci� NO es corregeix per loop clipping ni overlap
%      (possible millora!)%   la sortida �s double sempre
%   Modificaci� 22/12/14: identifica a,b,c aqui extrapola els fuel_map amb el valor als l�mits si sub2ind cau fora
%   Modificaci� 13/01/15% incorporem PENDENT i funci� getROS()
%   23/04/16: Handles WindNinja data!
% % $24.12.16 NOVELTY ->interpolates map in EXPANSION and NOT IN HUYGENS
%
% By Oriol 2014/15
%----------------$
% dt=10;%SEC % Fixed integration time [sec] (Richards 1990 uses 50s)
% %----------------$
% res=20; % Degridding distance ressolution 
%----------------$
%plot_ellipses_flag= 0; % 0 NO plot 1 PLOT
%----------------$

if numel(At)>1
    error('At must be ONE single value')
end

if size(x,1)<size(x,2) % if row vectors, convert to column
    x=x';
    y=y';
end

% if At<=dt
%     t=At;
% else
%     t=dt:dt:At;
%     if ~isequal(t(end),At)
%         t=[t At];
%     end
% end
if At<=dt
    t=At;
else
    %t=dt:dt:At;
    t=dt*ones(1,floor(At/dt));
    if mod(At,dt)~=0
        t=[t At-dt*floor(At/dt)];
    end
end

% No repetir el punt inicial i final abans de la propagaci� (IMPORTANT)!
% (es pot utilitzar una divisio si tampoc es vol acceptar una diferencia ~1)
if isequal([x(end),y(end)],[x(1),y(1)])
    x(end)=[];
    y(end)=[];
end

for k=1:length(t)
    %% OPEN PERIMENTER FOR EXPANDING CALCULATIONS (ho tornem a fer?)
    if x(1)==x(end) && y(1)==y(end)
        x(end)=[];
        y(end)=[];
    end
    
    %% FALLA ADIMAT
    % We dont want repeated points
%     xy=[x y];
%     [xy]=unique(xy,'rows','stable');
%     x=xy(:,1);
%     y=xy(:,2);

    %wind_dir=fuel_depth;
    % CANVIAR AIX� I FER B�!
    %wind_dir.data = theta * ones(size(wind_dir.data));
    
    %% !!!!!!!!!!!!!!!!!!! CHANGE THIS AFTER AD !!!!!!!!!!!!!!!!!!!
    
    fuel_depth=aspect;
    fuel_depth.data=Depth.*ones(size(fuel_depth.data));
    
    [fuel_depth_i]  =getGRDvalue_simple(fuel_depth, x,y);
    [aspect_i]      =getGRDvalue_simple(aspect,x,y);
    [slope_i]       =getGRDvalue_simple(slope,x,y);
    
    % WIND NINJA INTERPOLATION
    %[U_i,wind_dir_i]=SpeedDirMapReadAndInterpolValue(AllSpeedMapStrucGRD,AllDirMapStrucGRD,MesoU,MesoDir,x,y);% READING DATA
    %[wind_dir_i]    =getGRDvalue_simple(wind_dir,x,y);
    
    %[U_i, wind_dir_i]=SpeedDirMapInterpolValue(AllSpeedMapStrucGRD,AllDirMapStrucGRD,MesoU,MesoDirN,x,y);
    [U_i]          =getGRDvalue_simple(NewSpeedMapGRD,x,y);
    [wind_dir_i]   =getGRDvalue_simple(NewDirMapGRD,x,y);
    [wind_dir_i]=AngularNorth2Horz_From2BlowCW(wind_dir_i, 'r');
    %% CALCULATE ROS As Lauterberger (exept for wind-slope)
   
  % NEW all variables
    [RoS_i,theta_w_s_i]=RothSlopeSI(U_i, wind_dir_i,fuel_depth_i, slope_i, aspect_i, SAV, Wo, Mf, Mx);

    % OLD
    % RoS0_i=Imfw.*fuel_depth_i; %[m/s]
    %[RoS0_i]=getRoS_0(x,y,fuel_depth_i,Imfw); !Fa el mateix!
    %[RoS_i,theta_w_s]=wind_slope_corr1(x,y,RoS0_i,U,wind_dir,I_Wo,slope,aspect,fuel_depth);
    %[RoS_i,theta_w_s]=wind_slope_corr2(x,y,RoS0_i,U,wind_dir_i,I_Wo,slope_i,aspect_i,fuel_depth_i);
    %%
       
%     %% DEBUG
%     RoS_i=0.5.*ones(size(RoS_i));% m/s (30m/min)
    [a,b,c]=getABC(U_i,RoS_i);
    %plot(RoS_i); hold on;
    
    [x,y]=do_expansion_WN(x,y,a,b,c,theta_w_s_i,aspect_i,slope_i,dt,res);
end


xyout=[x y];

end

%% Nested Functions
% Nested Functions
% %     function [fuel_depth_i,aspect_i,slope_i]=GetGRDValueIfNeeded(x,y,fuel_depth,aspect,slope)
% %         %Slope
% %         if isstruct(slope) % get aspect values vector
% %             if ~exist('x','var') || ~exist('y','var')
% %                 error('If slope is input as GRD, xy coordinates are required!')
% %             end
% %             slope_i =getGRDvalue(slope,x,y);
% %         else
% %             slope_i=slope;
% %         end
% %         % FUEL
% %         if isstruct(fuel_depth) % get aspect vlaues vector
% %             if ~exist('x','var') || ~exist('y','var')
% %                 error('If slope is input as GRD, xy coordinates are required!')
% %             end
% %             fuel_depth_i =getGRDvalue(fuel_depth,x,y);
% %         else
% %             fuel_depth_i=fuel_depth;
% %         end

% PENDENT
% %         % wind dir
% %         if isstruct(wind_dir)
% %             if ~exist('x','var') || ~exist('y','var')
% %                 error('If WIND is input as GRD, xy coordinates are required!')
% %             end
% %             % !!!!!     % PENDENT de preparar la funci� per llegir un arxiu de vent 'wind' (GRID)!
% %             [wind_dir_i]=getGRDvalue(wind_dir,x,y);
% %         else
% %             wind_dir_i=wind_dir;
% %         end
% %         
% %         if isstruct(aspect) % get aspect vlaues vector
% %             if ~exist('x','var') || ~exist('y','var')
% %                 error('If aspect is input as GRD, xy coordinates are required!')
% %             end
% %             aspect_i =getGRDvalue(aspect,x,y);
% %         else
% %             aspect_i=aspect;
% %         end
% %         
% %     end