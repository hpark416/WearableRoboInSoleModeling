function F = spline_force(delta, params)
    % Fixed endpoints
    x1 = 0;       F1 = 0;
    x4 = 0.023;   F4 = 2300;

    % Middle 2 points from optimizer
    x2 = params(1);   F2 = params(2);
    x3 = params(3);   F3 = params(4);

    % Build spline
    displacement = [x1, x2, x3, x4];
    force        = [F1, F2, F3, F4];

    pp = spline(displacement, force);

    % Evaluate at given displacement
    F = ppval(pp, delta);
end