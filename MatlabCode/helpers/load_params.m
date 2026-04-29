%% called in all functions that requires these parameters for consistency
function [K_shoes, thicknesses, des_dp_Mass] =  load_params()
    % old values:
    % K_shoes = 20000:2500:70000;
    % thicknesses = 0.01:0.0025:0.035; 
    
    % 2.490 MPa +- 20%; 1MPa = 10^6 N/m^2; take single foot area to be 0.05m^2
    % count forefoot area as 1/3 of foot, then area approx 0.018m^2
    % 35856 - 53784
    % The lowcost shoe stiffness tested at the fast and slow loading rates was
    % 426 N/mm and 358 N/mm, respectively. The high-cost shoe
    % stiffness tested at the fast and slow loading rates was 257 N/
    % mm and 246 N/mm
    
    K_shoes = 20000:2500:55000;
    thicknesses = 0.005:0.0025:0.025; % maximum sole thickness is 4-5cm; 50% compressed
    % double feet
%     des_dp_Mass = 0.035;
    des_dp_Mass = 0.04;
end