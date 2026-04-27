% TODO rename the function and file after editing
% then move it into the helpers folder.

% objective function to be passed into bayesian optimization
% organized from performance_eval.m
% the following function is not supposed to be passed directly
% into bayesopt; it should be wrapped in a function defined in
% the main file that contains the global variable model_name
% since true objective will be the weighted combinations of them
function [max_GRF, max_dpMass, mean_Pmet, T_stim_res] = ...
    eval_all_objectives(model_name, K_shoe, thickness, T_stim, varargin)
    % T_stim: scalar or 2-element vector. For the latter, denotes a range.
    
    % the single-scalar objective should be defined by 
    % the wrapper that calls this function.
    
    % will not save time series signals.

    if isscalar(T_stim) % T_stim is a prescribed value
        T_stim_res = T_stim;
        [max_GRF, max_dpMass, mean_Pmet] = ...
            eval_params(model_name, K_shoe, thickness, T_stim);

    else % T_stim is a permissable range
        % assumes that varargin is not empty; throws an error anyway
        des_max_dpMass = varargin{1};
        [T_stim_res, max_GRF, max_dpMass, mean_Pmet] =  search_T_stim(...
            des_max_dpMass, model_name, K_shoe, thickness, T_stim);

        % [max_GRF, max_dpMass, mean_Pmet] = ...
        %             eval_params(model_name, K_shoe, thickness, T_stim);
    end
end


%% helpers
function [max_GRF, max_dpMass, mean_Pmet] = ...
    eval_params(model_name, K_shoe, thickness, T_stim)

    [simIn,~] = assemble_sim_inputs(model_name, ...
        K_shoe, thickness, T_stim); 
    simOut = sim(simIn);
    
    [max_GRF, max_dpMass, mean_Pmet] = analyze_sole_output(simOut);
end

% place binary search for T_stim here instead of in a new function
% since it is probably not called anywhere else
% binary search might not work for parsim, call this in parfor instead

% recursively search for the T_stim that results in COM displacement 
% within a threshold, assumes the relationship is monotonic
% It will eventually return all objectives, 
% as we usually need to run a simulation to obtain T_stim. 
%
% Optional parameters:
% varargin{1}: 
%   2*3 matrix, each row is max_GRF, max_dpMass, mean_Pmet,  
%   each column corresponds to min and max T_stim in range
% varargin{2}:
%   int, number of iterations.
function [T_stim, max_GRF, max_dpMass, mean_Pmet] =  search_T_stim(...
    des_max_dpMass, model_name, K_shoe, thickness, T_stim_range, ...
    varargin)
    % do not use parallelization as the main function is in parfor

    if isempty(varargin) % initialize
        objectives_range = zeros(2,3);
        % get objectives corresponding to minimum T_stim
        objectives_range(1,:) = ...
            eval_and_pack(model_name, K_shoe, thickness, T_stim_range(1));
        % get objectives corresponding to maximum T_stim
        objectives_range(2,:) = ...
            eval_and_pack(model_name, K_shoe, thickness, T_stim_range(2));

        iters = 1;
    else
        % unpack evaluated values from the outer recursion
        objectives_range = varargin{1};
        iters = varargin{2};
    end

    if iters > 5
        T_stim = mean(T_stim_range); 
        [max_GRF, max_dpMass, mean_Pmet] = ...
            eval_params(model_name, K_shoe, thickness, T_stim_range(2));
        return
    end

    % see if the value lies between; if not; quit
    if (des_max_dpMass < objectives_range(1,2)) % minimum max_dpMass
        T_stim = T_stim_range(1);
        [max_GRF, max_dpMass, mean_Pmet] = unpack(objectives_range(1,:));
        return
    elseif (des_max_dpMass > objectives_range(2,2)) % maximum max_dpMass
        T_stim = T_stim_range(2);
        [max_GRF, max_dpMass, mean_Pmet] = unpack(objectives_range(2,:));
        return
    end

    % evaluate midpoint
    mid_T_stim = mean(T_stim_range);
    mid_objectives = ...
        eval_and_pack(model_name, K_shoe, thickness, mid_T_stim);
    mid_max_dpMass = mid_objectives(2);

    if abs(mid_max_dpMass - des_max_dpMass) < 0.005
        T_stim = mid_T_stim;
        [max_GRF, max_dpMass, mean_Pmet] = unpack(mid_objectives(:));
        return
    end
    
    if (des_max_dpMass < mid_max_dpMass)
        next_T_stim_range = [T_stim_range(1), mid_T_stim];
        next_objectives_range = [objectives_range(1,:); mid_objectives];
        
    elseif (des_max_dpMass > mid_max_dpMass)
        next_T_stim_range = [mid_T_stim, T_stim_range(2)];
        next_objectives_range = [mid_objectives; objectives_range(2,:)];
        
    end

    % search recusively until returns
    [T_stim, max_GRF, max_dpMass, mean_Pmet] = search_T_stim(...
                    des_max_dpMass, model_name, K_shoe, thickness, ...
                    next_T_stim_range, ...
                    next_objectives_range, iters+1);

end


% matlab cannot do python-styple unpack, needs additional functions

function [max_GRF, max_dpMass, mean_Pmet] = unpack(objectives)

    max_GRF = objectives(1);
    max_dpMass = objectives(2);
    mean_Pmet = objectives(3);
end

function objectives = eval_and_pack(...
    model_name, K_shoe, thickness, T_stim)

    [max_GRF, max_dpMass, mean_Pmet] = eval_params(...
        model_name, K_shoe, thickness, T_stim);
    objectives = [max_GRF, max_dpMass, mean_Pmet];
end


