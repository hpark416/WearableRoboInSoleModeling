function ctrl_points_params = to_control_points(bo_params)
    ctrl_points_params.x2 = bo_params.dx2;
    ctrl_points_params.x3 = ctrl_points_params.x2 + bo_params.dx3;
    ctrl_points_params.x4 = ctrl_points_params.x3 + bo_params.dx4;

    ctrl_points_params.F2 = bo_params.dF2;
    ctrl_points_params.F3 = ctrl_points_params.F2 + bo_params.dF3;
    ctrl_points_params.F4 = ctrl_points_params.F3 + bo_params.dF4;
end