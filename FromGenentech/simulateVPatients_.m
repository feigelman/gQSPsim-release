
function [Results, nFailedSims, StatusOK, Message, Cancelled, taskID] = simulateVPatients_(ItemModel, options, Message, job)  
    Cancelled = false;
    nFailedSims = 0;
    taskObj = ItemModel.Task;
    taskID = [];
    
    % clear the results of the previous simulation
    Results = [];
    StatusOK = true;
    
    ParamValues_in = options.Pin;
    
    usePar = options.usePar;
    
    if isempty(taskObj) % could not load the task
        StatusOK = false;
        Message = sprintf('%s\n\n%s', 'Failed to run simulation', Message);
        
        return
    end

    % store the output times in Results
    if ~isempty(taskObj.OutputTimes)
        taskTimes = taskObj.OutputTimes;
    else
        taskTimes = taskObj.DefaultOutputTimes;
    end        
    Results.Time = union(taskTimes, options.extraOutputTimes);

    % preallocate a 'Data' field in Results structure
    Results.Data = [];

    % species names
    Results.SpeciesNames = [];
    if ~isempty(taskObj.ActiveSpeciesNames)
        Results.SpeciesNames = taskObj.ActiveSpeciesNames;
    else
        Results.SpeciesNames = taskObj.SpeciesNames;
    end    
    
    if isfield(ItemModel,'nPatients')
        
        if ~usePar
            for jj = 1:ItemModel.nPatients
    %             disp([' ', num2str(jj),' '])
                % check for user-input parameter values
                if ~isempty(ParamValues_in)
                    Names = options.paramNames;
                    Values = ParamValues_in;
                else
                    Names = ItemModel.Names;
                    Values = ItemModel.Values;
                end


                try 
                    if isempty(Values)
                        theseValues = [];
                    else
                        theseValues = Values(jj,:);
                    end
                    
                    [simData,simOK,errMessage]  = taskObj.simulate(...
                            'Names', Names, ...
                            'Values', theseValues, ...
                            'OutputTimes', Results.Time, ...
                            'Waitbar', options.WaitBar);
                    if ~simOK

    %                     ME = MException('simulationRunHelper:simulateVPatients', 'Simulation failed with error: %s', errMessage );
    %                     throw(ME)
                        StatusOK = false;
                        warning('Simulation %d failed with error: %s\n', jj, errMessage);
                        activeSpec_j = NaN(size(Results.Time,1), length(taskObj.ActiveSpeciesNames));
                    else
                        % extract active species data, if specified
                        if ~isempty(taskObj.ActiveSpeciesNames)
                            [~,activeSpec_j] = selectbyname(simData,taskObj.ActiveSpeciesNames);
                        else
                            [~,activeSpec_j] = selectbyname(simData,taskObj.SpeciesNames);
                        end

                    end

                % Add results of the simulation to Results.Data
                Results.Data = [Results.Data,activeSpec_j];
                catch err% simulation
                    % If the simulation fails, store NaNs
                    warning(err.identifier, 'simulationRunHelper: %s', err.message)
                    % pad Results.Data with appropriate number of NaNs
                    if ~isempty(taskObj.ActiveSpeciesNames)
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.ActiveSpeciesNames))];
                    else
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.SpeciesNames))];
                    end

                    nFailedSims = nFailedSims + 1;

                end % try

                % update wait bar:q
                if ~isempty(options.WaitBar)
                    StatusOK = uix.utility.CustomWaitbar(jj/ItemModel.nPatients, options.WaitBar, sprintf('Simulating vpatient %d/%d', jj, ItemModel.nPatients));
                end
                if ~StatusOK
                    Cancelled=true;
                    break
                end
            end % for jj = ...
        else

%             j = batch(c, @simulateVPatients_batch, 4, {taskObj, ItemModel, options, Results});
%             wait(j)
%             data = fetchOutputs(j);
%             [Results, StatusOK, Message, nFailedSims] = fetchOutputs(j);
%             [Results, StatusOK, Message, nFailedSims, job] = simulateVPatients_batch(taskObj, ItemModel, options, Results, job);
              if ~isempty(ParamValues_in)
                    Names = options.paramNames;
                    Values = ParamValues_in;
              else
                    Names = ItemModel.Names;
                    Values = ItemModel.Values;
              end
                block = 1:ItemModel.nPatients;
                
            % update outside of the batch job to avoid filesystem
            % calls
            taskObj.update(); 

            taskID = job.createTask(@parBlock,5,{block, Names, Values, taskObj, Results});
    
    
        end
            
    end % if
    

%     Message = vertcat(Message{:});
    Cancelled = ~isvalid(options.WaitBar);
end
