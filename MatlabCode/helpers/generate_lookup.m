function [force_table, disp_table] = generate_lookup(...
                                    params)
    % Fixed endpoints
    displacement = [0,  params.x2,  params.x3,  params.x4];
    force        = [0,  params.F2,  params.F3,  params.F4];

    % Build spline
    % switch to pchip to prevent overshoot
%     pp = spline(displacement, force);
    pp = pchip(displacement, force);

    % Generate lookup table (displacement -> force)
    % faster vectorized operation
    disp_table  = linspace(0, params.x4, 100);
    force_table = ppval(pp, disp_table);
    
end