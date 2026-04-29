function [simIn, param_combinations] = assemble_sim_inputs( ...
                        model_name, K_shoes, thicknesses, amplitudes, ...
                        force_table, disp_table)

    n_combinations = length(K_shoes) * length(thicknesses) * length(amplitudes);
    
    if n_combinations == 1
        simIn = assemble_single_sim_input(...
                    model_name, K_shoes, thicknesses, amplitudes, ...
                    force_table, disp_table);
        param_combinations = [K_shoes, thicknesses, amplitudes];
        return
    end

    param_combinations = zeros(n_combinations, 3);
    count = 1;
    
    for K_shoe = K_shoes
        for thickness = thicknesses
            for amplitude = amplitudes
                simIn(count) = assemble_single_sim_input(...
                    model_name, K_shoe, thickness, amplitude, ...
                    force_table, disp_table);
                param_combinations(count,:) = [K_shoe, thickness, amplitude];
                count = count + 1;
            end
        end
    end
end


function simIn = assemble_single_sim_input( ...
                        model_name, K_shoe, thickness, amplitude, ...
                        force_table, disp_table)
    simIn = Simulink.SimulationInput(model_name);
    simIn = simIn.setVariable(...
        'k_shoe', K_shoe, 'Workspace', model_name);
    simIn = simIn.setVariable(...
        'thickness', thickness, 'Workspace', model_name);
    simIn = simIn.setVariable(...
        'amplitude', amplitude, 'Workspace', model_name);
    simIn = simIn.setVariable(...
        'force_table', force_table, 'Workspace', model_name);
    simIn = simIn.setVariable(...
        'disp_table', disp_table, 'Workspace', model_name);
end