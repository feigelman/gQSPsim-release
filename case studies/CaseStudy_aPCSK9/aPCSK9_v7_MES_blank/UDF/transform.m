function [Yout] = transform(Xin,Yrange,Xic50,varargin)

nVarargs = length(varargin);
Xscale='log'; % default is log
Xrange=3;     % log-order if log; actual range if linear
if (nVarargs==1) 
    Xrange=varargin{1}; 
end
if (nVarargs==2)
    Xrange=varargin{1}; Xscale=varargin{2};
end

if strcmp(Xscale,'log')
    expT=3.97865*Xrange^-0.995; % This is fitted to give 99% output at the extreme of the range specified
    Yout=( Yrange(2) - Yrange(1) ) * (Xin^expT/(Xin^expT+Xic50^expT)) + Yrange(1);
end

 if strcmp(Xscale,'lin')
    Xmin=Xic50-Xrange/2;Xmax=Xic50+Xrange/2;
    expT=3.97865*2^-0.995; % optimized for range of -1 to 1;
    Xmod=10^( 2*(Xin-Xmin)/(Xmax-Xmin) -1 )  ; 
    Xmodic50=10^( 2*(Xic50-Xmin)/(Xmax-Xmin) -1 );  
    Yout=( Yrange(2) - Yrange(1) ) * (Xmod^expT/(Xmod^expT+Xmodic50^expT)) + Yrange(1);
 end
 
end
