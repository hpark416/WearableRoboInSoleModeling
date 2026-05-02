%% Straight monotone spline tables from linear K_shoe and thickness (same as gen_sweep_data)
function [force_table, disp_table] = straight_spline_tables_from_kb(K_shoe, thickness)

displacement = linspace(0, thickness, 4);
force = linspace(0, K_shoe * thickness, 4);
params.x2 = displacement(2);
params.x3 = displacement(3);
params.x4 = displacement(4);
params.F2 = force(2);
params.F3 = force(3);
params.F4 = force(4);

[force_table, disp_table] = generate_lookup(params);

end
