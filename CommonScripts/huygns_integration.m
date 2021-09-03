function [xyout]=huygns_integration(x,y,a,b,c,theta,dt)
%implemented function from Richards1990 (pag 1168)%//从 Richards1990 实现的函数（第 1168 页）
% IMPORTANT! el primer i últim valor d'x i y no poden estar DUPLICATS!%//重要！ x 和 y 的第一个和最后一个值不能重复！
% integrates using Euler and Predictor-Corrector methods along dt//沿 dt 使用 Euler 和 Predictor-Corrector 方法进行积分
if isequal([x(end),y(end)],[x(1),y(1)]) %(es pot utilitzar una divisio si es vol acceptar una diferencia ~1)//（如果要接受差异可以使用除法~1）
    x(end)=[];
    y(end)=[];
    a(end)=[];
    b(end)=[];
    c(end)=[];
end
%Initial Checks
if numel(a)>1 && numel(a)~=numel(x)
    error('MyErr:huygns_integration-> length a~=x')
end

   % Preditor
   [Pdx,Pdy]=F(x,y,a,b,c,theta);
    Px=x+dt*Pdx;
    Py=y+dt*Pdy;
   
   %Corrector
   [Cdx,Cdy]=F(Px,Py,a,b,c,theta);
    xout=x+0.5*dt*(Pdx+Cdx);
    yout=y+0.5*dt*(Pdy+Cdy);
    
   % Correct for NaNs (not propagation). Copy last point
        NaNxy=isnan(xout);
        xout(NaNxy)=x(NaNxy);
        yout(NaNxy)=y(NaNxy);
        xyout=[xout yout];
end
