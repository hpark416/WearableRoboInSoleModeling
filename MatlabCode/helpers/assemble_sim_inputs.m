% boilerplate to use both in bayesian optimization and parsim
% input can be both scalar or vector; 
% will return array of simulationInput objects for sim or parsim
function [simIn, param_combinations] = assemble_sim_inputs( ...
                               model_name, K_shoes, thicknesses, T_stims)
    % returns an array of simIn of all possible combinations
    n_combinations = length(K_shoes) * length(thicknesses) * length(T_stims);
    
    % params like the following might need to be done outside:
    % simIn = simIn.setModelParameter('SimulationMode', "accelerator");
    
    if n_combinations == 1
        simIn = assemble_single_sim_input(...
                    model_name, K_shoes, thicknesses, T_stims);
        param_combinations = [K_shoes, thicknesses, T_stims];
        return
    end
    % might not need meshgrid for contourf
    param_combinations = zeros(n_combinations, 3);
    count = 1;
    
    % need to return a gridpoint for plotting
    for K_shoe = K_shoes
        for thickness = thicknesses
            for T_stim = T_stims
                % only done for parsim; speed does not matter
                simIn(count) = assemble_single_sim_input(...
                    model_name, K_shoe, thickness, T_stim);
                param_combinations(count,:) = [K_shoe, thickness, T_stim];

                count = count + 1;
            end
        end
    end

end


function simIn = assemble_single_sim_input( ...
                               model_name, K_shoe, thickness, T_stim)
                           
    % T_stim may cause problem if not divisible by fixed timestep = 0.01s
    T_stim_divisible = T_stim - mod(T_stim, 0.01);
    
    % better practice?
    simIn = Simulink.SimulationInput(model_name);
    % should not use set_param. use set variable (matlab workspace)
    % instead, or might need to recomplie in accelerator mode
    simIn = simIn.setVariable(...
        'k_shoe', K_shoe, 'Workspace', model_name);
    simIn = simIn.setVariable(...
        'thickness',thickness,'Workspace', model_name);
    simIn = simIn.setVariable(...
        'T_stim',T_stim_divisible,'Workspace', model_name);

end




                           
                           