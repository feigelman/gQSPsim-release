function [Yout] = SREBP2_reg(SREBP2,Vmax_up, Km_up, Vmax_down, Km_down)

if ( SREBP2 >= 1 )
    In = (SREBP2-1);
    Yout = 1 + (Vmax_up-1) * In / (In + (Km_up-1)); 

elseif ( SREBP2 < 1 )
    In = (1-SREBP2);
    Yout = 1 - Vmax_down * In / (In + Km_down); 
    
else
    Yout = 0; 
end
 
end

