function gen_sweep_data(model_name, is_fixed_height, use_curve)
    % if height is not fixed then will run parsim
    % when use_curve, will perform sanity check 

    folder_dir = "./generated_data/";
    mkdir(folder_dir)

    addpath(genpath('./helpers'))
    addpath(genpath('./models')) % or parfor cannot access

    model_filename = strcat('./models/',model_name,'.slx');

    model_experiment_folder_dir = strcat(folder_dir,"/",model_name,"/");
    mkdir(model_experiment_folder_dir)

    w = warning('off','all');
    load_system(model_filename);
    set_param(model_name, 'SimulationMode', 'accelerator')
    if use_curve
        set_param(model_name, 'FastRestart', 'off'); 
    else
        set_param(model_name, 'FastRestart', 'on'); 
    end

    if ~is_fixed_height
        do_parsim_and_save(model_name,model_experiment_folder_dir, use_curve);
    else
        do_parfor_and_save(model_name,model_experiment_folder_dir, use_curve,...
        [0.8,1]);
    end

    set_param(model_name, 'FastRestart', 'off');
    close_system(model_name,0);          
    warning(w)

end

%% 

function do_parsim_and_save(model_name,model_experiment_folder_dir, use_curve)
    % sweep through possible parameters
    [K_shoes, thicknesses, ~] =  load_params();

    material_params.K_shoe = K_shoes;
    material_params.thickness = thicknesses;

    if use_curve % need to transform from stiffness-compression to tables
        % first generate params only
        [~, linear_param_combinations] = assemble_sim_inputs( ...
                        model_name, material_params, 1, false);
        material_params = linear_params_to_curve_params(...
        linear_param_combinations, true);
    end

    [simIn, param_combinations] = assemble_sim_inputs( ...
                                model_name, material_params, 1);

    tic
    simouts = parsim(simIn);
    toc

    % save
    if use_curve % correct param_combinations to log.
        param_combinations = linear_param_combinations;
    end
    n_sims = length(simIn);
    for sim_idx = 1:n_sims 
        filename = strcat(model_experiment_folder_dir,...
            'k_',num2str(param_combinations(sim_idx).K_shoe),...
            '_maxcomp_',num2str(param_combinations(sim_idx).thickness),...
            '.mat');
        
        simout = simouts(sim_idx);
        save(filename, "simout")
    end

end

function do_parfor_and_save(...
    model_name,model_experiment_folder_dir, use_curve, amplitude_range)
    % sweep through possible parameters
    [K_shoes, thicknesses, des_dp_Mass] =  load_params();

    material_params.K_shoe = K_shoes;
    material_params.thickness = thicknesses;
    [~, linear_param_combinations] = assemble_sim_inputs( ...
                    model_name, material_params, 1, false);

    if use_curve % need to transform from stiffness-compression to tables
        param_combinations = linear_params_to_curve_params(...
        linear_param_combinations, false);
    else
        param_combinations = linear_param_combinations;
    end

    n_combinations = length(param_combinations);
    out = zeros(n_combinations, 4);

    tic
    parfor_progress(n_combinations)
    parfor idx = 1:n_combinations % nesting is not allowed in parfor
        params = param_combinations(idx);
        [max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
            eval_all_objectives(model_name, ...
                                params, ...
                                amplitude_range, des_dp_Mass);
        result = [max_GRF, max_dpMass, mean_Pmet, amplitude_res]; 
        out(idx,:) = result; % index only once
        parfor_progress
    end
    parfor_progress(0);
    toc

    % save
    if use_curve % correct param_combinations to log.
        param_combinations = linear_param_combinations;
    end
    filename = strcat(model_experiment_folder_dir,...
                'height_',num2str(des_dp_Mass),...
                '_objectives',...
                '.mat');
    save(filename, "out", "param_combinations")

end



%% degenerate case to test straight splines
function curve_params = ...
    linear_params_to_curve_params(param_combinations,single_struct)
    % convert param_combinations of K_shoe and stiffness to params
    % of force and displacement tables.
    % if single_struct, then returns a struct of multiple tables.
    % in one field, each row is a table (for assemble_sim_inputs)
    force_tables = [];
    disp_tables = [];

    count = 1;
    for param  = param_combinations
        K_shoe = param.K_shoe;
        thickness = param.thickness;
        
        [force_table, disp_table] = ...
                generate_straight_curve_tables(K_shoe, thickness);
        if single_struct
            force_tables = [force_tables; force_table];
            disp_tables = [disp_tables; disp_table];
        else
            curve_param.force_table = force_table;
            curve_param.disp_table = disp_table;

            curve_params(count) = curve_param;
            count = count+1;
        end
    end

    if single_struct
        curve_params.force_table = force_tables;
        curve_params.disp_table = disp_tables;
    end

end


function [force_table, disp_table] = ...
    generate_straight_curve_tables(K_shoe, thickness)

    displacement = linspace(0,thickness,4);
    force = linspace(0, K_shoe*thickness, 4);
    params.x2 = displacement(2);
    params.x3 = displacement(3);
    params.x4 = displacement(4);
    params.F2 = force(2);
    params.F3 = force(3);
    params.F4 = force(4);

    [force_table, disp_table] = generate_lookup(params);
    
end

