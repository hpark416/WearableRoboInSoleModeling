function [force_table, disp_table] = generate_lookup(x2, F2, x3, F3)
    % Fixed endpoints
    displacement = [0,  x2,  x3,  0.023];
    force        = [0,  F2,  F3,  2300];

    % Build spline
    pp = spline(displacement, force);

    % Generate lookup table (force -> displacement)
    force_table = linspace(0, 2300, 100);
    disp_table  = zeros(1, 100);

    for i = 1:100
        try
            disp_table(i) = fzero(@(x) ppval(pp, x) - force_table(i), [0, 0.023]);
        catch
            disp_table(i) = interp1(force, displacement, force_table(i), ...
                                    'linear', 'extrap');
            disp_table(i) = max(0, min(0.023, disp_table(i)));
        end
    end
end