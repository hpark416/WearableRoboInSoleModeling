function [max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
    eval_all_objectives(model_name, K_shoe, thickness, amplitude, ...
                        force_table, disp_table, varargin)

    if isscalar(amplitude)
        amplitude_res = amplitude;
        [max_GRF, max_dpMass, mean_Pmet] = ...
            eval_params(model_name, K_shoe, thickness, amplitude, ...
                        force_table, disp_table);
    else
        des_max_dpMass = varargin{1};  % now correctly reads des_dp_Mass
        [amplitude_res, max_GRF, max_dpMass, mean_Pmet] = search_amplitude(...
            des_max_dpMass, model_name, K_shoe, thickness, amplitude, ...
            force_table, disp_table);
    end
end


function [max_GRF, max_dpMass, mean_Pmet] = ...
    eval_params(model_name, K_shoe, thickness, amplitude, ...
                force_table, disp_table)

    [simIn, ~] = assemble_sim_inputs(model_name, ...
        K_shoe, thickness, amplitude, force_table, disp_table); 
    simOut = sim(simIn);
    
    [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simOut);
end


function [amplitude, max_GRF, max_dpMass, mean_Pmet] = search_amplitude(...
    des_max_dpMass, model_name, K_shoe, thickness, amplitude_range, ...
    force_table, disp_table, varargin)

    if isempty(varargin)
        objectives_range = zeros(2,3);
        objectives_range(1,:) = ...
            eval_and_pack(model_name, K_shoe, thickness, amplitude_range(1), ...
                          force_table, disp_table);
        objectives_range(2,:) = ...
            eval_and_pack(model_name, K_shoe, thickness, amplitude_range(2), ...
                          force_table, disp_table);
        iters = 1;
    else
        objectives_range = varargin{1};
        iters = varargin{2};
    end

    if iters > 5
        amplitude = mean(amplitude_range); 
        [max_GRF, max_dpMass, mean_Pmet] = ...
            eval_params(model_name, K_shoe, thickness, amplitude_range(2), ...
                        force_table, disp_table);
        return
    end

    if (des_max_dpMass < objectives_range(1,2))
        amplitude = amplitude_range(1);
        [max_GRF, max_dpMass, mean_Pmet] = unpack(objectives_range(1,:));
        return
    elseif (des_max_dpMass > objectives_range(2,2))
        amplitude = amplitude_range(2);
        [max_GRF, max_dpMass, mean_Pmet] = unpack(objectives_range(2,:));
        return
    end

    mid_amplitude = mean(amplitude_range);
    mid_objectives = ...
        eval_and_pack(model_name, K_shoe, thickness, mid_amplitude, ...
                      force_table, disp_table);
    mid_max_dpMass = mid_objectives(2);

    if abs(mid_max_dpMass - des_max_dpMass) < 0.0005
        amplitude = mid_amplitude;
        [max_GRF, max_dpMass, mean_Pmet] = unpack(mid_objectives(:));
        return
    end
    
    if (des_max_dpMass < mid_max_dpMass)
        next_amplitude_range = [amplitude_range(1), mid_amplitude];
        next_objectives_range = [objectives_range(1,:); mid_objectives];
    elseif (des_max_dpMass > mid_max_dpMass)
        next_amplitude_range = [mid_amplitude, amplitude_range(2)];
        next_objectives_range = [mid_objectives; objectives_range(2,:)];
    end

    [amplitude, max_GRF, max_dpMass, mean_Pmet] = search_amplitude(...
                    des_max_dpMass, model_name, K_shoe, thickness, ...
                    next_amplitude_range, force_table, disp_table, ...
                    next_objectives_range, iters+1);
end


function [max_GRF, max_dpMass, mean_Pmet] = unpack(objectives)
    max_GRF    = objectives(1);
    max_dpMass = objectives(2);
    mean_Pmet  = objectives(3);
end

function objectives = eval_and_pack(...
    model_name, K_shoe, thickness, amplitude, force_table, disp_table)

    [max_GRF, max_dpMass, mean_Pmet] = eval_params(...
        model_name, K_shoe, thickness, amplitude, force_table, disp_table);
    objectives = [max_GRF, max_dpMass, mean_Pmet];
end