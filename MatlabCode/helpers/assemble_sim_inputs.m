%% boilerplate to use both in bayesian optimization and parsim
% input can be both scalar or vector; 
% will return array of simulationInput objects for sim or parsim.
% material_params is a struct containing either lookup table
% or K_shoe and thickness.
function [simIn, param_combinations] = assemble_sim_inputs( ...
                        model_name, material_params, amplitudes)
    % check if this is for linear or splines stiffness model
    if isfield(material_params,"force_table") 
        % forces to generate single input, 
        % as it is infeasible to sweep through spline parameters
        simIn = assemble_table_sim_input(model_name, ...
        material_params.force_table, material_params.disp_table, amplitudes(1));
        param_combinations = [material_params.force_table, material_params.disp_table];
        return
    end

    K_shoes = material_params.K_shoe;
    thicknesses = material_params.thickness;
    n_combinations = length(K_shoes) * length(thicknesses) * length(amplitudes);
    
    % params like the following might need to be done outside:
    % simIn = simIn.setModelParameter('SimulationMode', "accelerator");
    
    if n_combinations == 1
        simIn = assemble_single_sim_input(...
                    model_name, K_shoes, thicknesses, amplitudes);
        param_combinations = [K_shoes, thicknesses, amplitudes];
        return
    end
    % might not need meshgrid for contourf
    param_combinations = zeros(n_combinations, 3);
    count = 1;
    
    % need to return a gridpoint for plotting
    for K_shoe = K_shoes
        for thickness = thicknesses
            for amplitude = amplitudes % in practice, this is fixed
                % only done for parsim; speed does not matter
                simIn(count) = assemble_single_sim_input(...
                    model_name, K_shoe, thickness, amplitude);
                param_combinations(count,:) = [K_shoe, thickness, amplitude];

                count = count + 1;
            end
        end
    end

end


function simIn = assemble_single_sim_input( ...
                               model_name, K_shoe, thickness, amplitude)

    simIn = Simulink.SimulationInput(model_name);
    % should not use set_param. use set variable (matlab workspace)
    % instead, or might need to recomplie in accelerator mode
    simIn = simIn.setVariable(...
        'k_shoe', K_shoe, 'Workspace', model_name);
    simIn = simIn.setVariable(...
        'thickness',thickness,'Workspace', model_name);
    simIn = simIn.setVariable(...
        'amplitude',amplitude,'Workspace', model_name);

end

function simIn = assemble_table_sim_input( ...
                               model_name, force_table, disp_table, amplitude)

    simIn = Simulink.SimulationInput(model_name);
    % should not use set_param. use set variable (matlab workspace)
    % instead, or might need to recomplie in accelerator mode
    simIn = simIn.setVariable(...
        'force_table', force_table, 'Workspace', model_name);
    simIn = simIn.setVariable(...
        'disp_table',disp_table,'Workspace', model_name);
    simIn = simIn.setVariable(...
        'amplitude',amplitude,'Workspace', model_name);

end



                           
                           