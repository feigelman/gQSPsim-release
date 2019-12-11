function [Results, nFailedSims, StatusOK, Message, ErrObj] = parBlock(block, Names, Values, taskObj, Results)   

    Message = cell(1,length(block));
    ErrObj = cell(1,length(block));
    StatusOK = true;

%                 disp(block)
    Time = Results.Time;
    parData = cell(1,length(block));
    nFailedSims = zeros(size(block));
    
    
   
    
    parfor jj = block
%             disp([' ', num2str(jj),' '])
        % check for user-input parameter values

        try 
            if isempty(Values)
                theseValues = [];
            else
                theseValues = Values(jj,:);
            end

            [simData,simOK,errMessage]  = taskObj.simulate(...
                    'Names', Names, ...
                    'Values', theseValues, ...
                    'OutputTimes', Time, ...
                    'CheckCurrent', false);

            if ~simOK

%                     ME = MException('simulationRunHelper:simulateVPatients', 'Simulation failed with error: %s', errMessage );
%                     throw(ME)
                StatusOK(jj) = false;
                Message{jj} = errMessage;
                warning('Simulation %d failed with error: %s\n', jj, errMessage);
                activeSpec_j = NaN(size(Time,1), length(taskObj.ActiveSpeciesNames));
            else
                % extract active species data, if specified
                if ~isempty(taskObj.ActiveSpeciesNames)
                    [~,activeSpec_j] = selectbyname(simData,taskObj.ActiveSpeciesNames);
                else
                    [~,activeSpec_j] = selectbyname(simData,taskObj.SpeciesNames);
                end

            end

        % Add results of the simulation to Results.Data
            parData{jj} = activeSpec_j;
%             Results.Data = [Results.Data,activeSpec_j];
        catch err% simulation
            % If the simulation fails, store NaNs
            warning(err.identifier, 'simulationRunHelper: %s', err.message)
%                 pad Results.Data with appropriate number of NaNs
            if ~isempty(taskObj.ActiveSpeciesNames)
%                     Results.Data = [Results.Data,];
                parData{jj} = NaN*ones(length(Results.Time),length(taskObj.ActiveSpeciesNames));
            else
%                     Results.Data = [Results.Data,];
                parData{jj} = NaN*ones(length(Results.Time),length(taskObj.SpeciesNames));
            end

            StatusOK(jj) = false;
            Message{jj} = err.message;
            nFailedSims(jj) = 1;
            ErrObj{jj} = err;

        end % try

%             send(q, []);                      

    end % for jj = ...
    StatusOK = all(StatusOK);
    Results.Data = horzcat(parData{:});
    nFailedSims = sum(nFailedSims);
end