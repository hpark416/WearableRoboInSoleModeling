%% boilerplate to use both in bayesian optimization and parsim
% material_params is one single struct containing either lookup table
% or K_shoe and thickness.
% Returns all possible combinations if the parameters are K and compression.
% if running the baseline model, struct should be empty.
% Returns single / array of simulationInput objects for sim or parsim.
function [simIn, param_combinations] = assemble_sim_inputs( ...
                        model_name, material_params, amplitudes, varargin)
    % param_combinations only used in k-compression sweep for k/kb models.
    gen_sim_input = true;
    if ~isempty(varargin)
        % if false then will only generate a list of param combinations for tracking
        gen_sim_input = varargin{1};
    end
    if ~gen_sim_input
        simIn = [];
    end

    if isempty(material_params) % baseline.
        if gen_sim_input
            simIn = Simulink.SimulationInput(model_name);
            simIn = simIn.setVariable(...
                'amplitude',amplitudes(1),'Workspace', model_name);
        end

        param_combinations = amplitudes; % TODO rewrite this into struct
        return
    end

    % check if this is for linear or splines stiffness model
    if isfield(material_params,"force_table") 
        % force_table - disp_table is one-to-one, each row is a table.
        [n_tables, ~] = size(material_params.force_table);
        
        count = 1;
        for table_idx = 1:n_tables
            force_table = material_params.force_table(table_idx,:);
            disp_table = material_params.disp_table(table_idx,:);

            for amplitude = amplitudes % in practice, this is fixed
                if gen_sim_input
                    simIn(count) = assemble_table_sim_input(model_name, ...
                                    force_table, disp_table, ...
                                    amplitude);
                end

                param.force_table = force_table;
                param.disp_table = disp_table;
                param.amplitude = amplitude;
                param_combinations(count) = param;
                count = count + 1;
            end
        end

        return
    end

    K_shoes = material_params.K_shoe;
    thicknesses = material_params.thickness;
    n_combinations = length(K_shoes) * length(thicknesses) * length(amplitudes);
    
    if n_combinations == 1
        if gen_sim_input
            simIn = assemble_single_sim_input(...
                        model_name, K_shoes, thicknesses, amplitudes);
        end

        param_combinations.K_shoe = K_shoes;
        param_combinations.thickness = thicknesses;
        param_combinations.amplitude = amplitudes;
        return
    end

    count = 1;
    % need to return a gridpoint for plotting
    for K_shoe = K_shoes
        for thickness = thicknesses
            for amplitude = amplitudes % in practice, this is fixed
                % only done for parsim; speed does not matter
                if gen_sim_input
                    simIn(count) = assemble_single_sim_input(...
                        model_name, K_shoe, thickness, amplitude);
                end

                param.K_shoe = K_shoe;
                param.thickness = thickness;
                param.amplitude = amplitudes;

                param_combinations(count) = param;

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



                           
                           