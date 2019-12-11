function [StatusOK,Message,ResultsFileNames,VpopNames, groupErrorCounts, groupErrorMessages, groupErrorMessageCounts] = optimizationRunHelper(obj)
% Sets up and runs the optimization contained in the Optimization object
% "obj".

% check for species-data mapping
if isempty(obj.SpeciesData)
    StatusOK = false;
    Message = 'At least one species-data mapping must be defined for optimization to proceed.';
    ResultsFileNames = {};
    VpopNames = {};
   
    return 
end

% Initialize waitbar
Title = sprintf('Run Optimization');
DialogMessage = sprintf('Optimization in progress. Please wait...');
hDlg = warndlg(DialogMessage,Title,'modal');

StatusOK = true;
Message = '';

% store path & add all subdirectories of root directory
myPath = path;
addpath(genpath(obj.Session.RootDirectory));


if isempty(obj.SpeciesIC)
    ResultsFileNames = cell(1,1);
    VpopNames = cell(1,1);
else
    ResultsFileNames = cell(1+length(obj.Item),1);
    VpopNames = cell(1+length(obj.Item),1);
end

%% Load Parameters
Names = {obj.Settings.Parameters.Name};
MatchIdx = strcmpi(Names,obj.RefParamName);
if any(MatchIdx)
    pObj = obj.Settings.Parameters(MatchIdx);
    [ThisStatusOk,ThisMessage,paramHeaders,paramData] = importData(pObj,pObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        path(myPath);
        return
    end
else
    warning('Could not find match for specified parameter file')
    paramData = {};
end

%Fix to remove Nans in parameter headers
paramHeaders = paramHeaders(1:(find(cell2mat(cellfun(@ischar, paramHeaders, 'UniformOutput', false)),1,'last')));  

if ~isempty(paramData)
    % parse paramData
    
    colId.Include = find(strcmpi(paramHeaders, 'Include'));
    colId.Name = find(strcmpi(paramHeaders, 'Name'));
    colId.LB = find(strcmpi(paramHeaders, 'LB'));
    colId.UB = find(strcmpi(paramHeaders, 'UB'));
%     colId.P0 = find(contains(upper(paramHeaders), 'P0'), 1, 'first'); % keep only first column for now!
    colId.P0 = find(contains(upper(paramHeaders), 'P0')); % keep only first column for now!    
    colId.Scale = find(strcmpi(paramHeaders, 'SCALE'));
    
    

    % convert to numeric cell array if it is a cell array (i.e. contains strings)
    for k=1:length(colId.P0)
        if iscell(paramData(:,colId.P0(k)))            
            isStr = cellfun(@ischar, paramData(:,colId.P0(k)));
            paramData(isStr,colId.P0(k)) = cellfun(@str2num, paramData(isStr,colId.P0(k)), 'UniformOutput', false);
        end
    end
   
    % remove any NaNs at bottom of file
    paramData = paramData(~all(cellfun(@isnan,paramData(:,colId.P0)),2),:);
    optimizeIdx = find(strcmpi('Yes',paramData(:,colId.Include)));
    
    
    % check that an initial guess is given
    if isempty(colId.P0)
        StatusOK = false;
        ThisMessage = 'No initial guess for the parameter values was given. Make sure sure the P0_1 column of the selected parameter file is filled out.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        path(myPath);
        return
    elseif any(any(isnan(cell2mat(paramData(optimizeIdx,colId.P0)))))
        StatusOK = false;
        ThisMessage = 'Parameter file is missing information.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        path(myPath);
        return
    end
    
    % check for parameters that are not in any of the models to be
    % simulated
    
    
    
    
    % separate into estimated parameters and fixed parameters
    colInclude = strcmpi(paramHeaders,'Include');
    idxEstimate = strcmpi('Yes',paramData(:,colInclude));
    if ~any(idxEstimate)
        StatusOK = false;
        ThisMessage = 'No parameters included in optimization.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        path(myPath);
        return
    end
    
    % check that all parameters to be optimized (Include=Yes) have
    % specified LB and UB
    
    
    LB = cell2mat(paramData(optimizeIdx, colId.LB));
    UB = cell2mat(paramData(optimizeIdx, colId.UB));
    if any(isnan(LB) | isempty(LB) | isnan(UB) | isempty(UB))
        StatusOK = false;
        ThisMessage = 'LB and UB must be given for each parameter to be optimized.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        path(myPath);
        return
    end
    

    
    % record indices of parameters that will be log-scaled
    logInds = find(strcmpi('log',paramData(idxEstimate,colId.Scale)));
    % extract parameter names
    estParamNames = paramData(idxEstimate,colId.Name);
    fixedParamNames = paramData(~idxEstimate,colId.Name);
    allParamNames = paramData(:,colId.Name);
    % extract numeric data
%     estParamData = cell2mat(paramData(idxEstimate,4:end));
    estParamData = cell2mat(paramData(idxEstimate,[colId.LB, colId.UB, colId.P0]));
    
    if ~isempty(fixedParamNames)
        isValid = ~cellfun(@isempty, paramData(~idxEstimate, colId.P0(1)));
        fixedParamData = cell2mat(paramData(~idxEstimate,colId.P0(1)));
        fixedParamNames = fixedParamNames(isValid);
    else
        fixedParamData = {};
    end
    % transform log-scaled parameters
    estParamData(logInds,:) = log10(estParamData(logInds,:));
    
    paramObj.estParamNames = estParamNames;
    paramObj.fixedParamNames = fixedParamNames;
    paramObj.fixedParamData = fixedParamData;
    paramObj.logInds = logInds;
    
else
    StatusOK = false;
    ThisMessage = 'The selected Parameter file is empty.';
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
    path(myPath);
    return
end



%% Load data
Names = {obj.Settings.OptimizationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

if any(MatchIdx)
    odObj = obj.Settings.OptimizationData(MatchIdx);
    DestFormat = 'wide';
    [ThisStatusOk,ThisMessage,optimHeader,optimData] = importData(odObj,odObj.FilePath,DestFormat);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    optimHeader = {};
    optimData = {};
end

if ~isempty(optimHeader) && ~isempty(optimData)
    
    % check for column headers
    if ~any(strcmp(obj.GroupName,optimHeader)) || ~any(strcmp(obj.IDName,optimHeader)) ...
        || ~any(strcmp('Time',optimHeader))
            StatusOK = false;
        Message = 'Data file is missing columns. Check that the data file has columns named "Group", "ID", and "Time"';
        return
    end
    
    
    % parse optimData
    Groups = cell2mat(optimData(:,strcmp(obj.GroupName,optimHeader)));
    IDs = cell2mat(optimData(:,strcmp(obj.IDName,optimHeader)));
    Time = cell2mat(optimData(:,strcmp('Time',optimHeader)));

    excludeIdx = find(strcmpi('Exclude',optimHeader));
    Exclude = false(size(optimData,1),1);

    if ~isempty(excludeIdx)
        tmp = optimData(:,excludeIdx);
        Exclude(strcmpi(tmp,'Yes')) = true;
    end
    
    % find columns corresponding to species data and initial conditions
    [~, dataInds] = ismember(union({obj.SpeciesIC.DataName}, {obj.SpeciesData.DataName}), optimHeader);
    % filter
    optimData = optimData(~Exclude,:);
    
    % convert optimData into a matrix of species data
    optimData = cell2mat(optimData(:,dataInds));
    % save only the headers for the data columns
    dataNames = optimHeader(:,dataInds);
    
    % remove data for groups that are not currently being used in optimization
    optimGrps = cell2mat(cellfun(@str2num, {obj.Item.GroupID}, 'UniformOutput', false));
    include = ismember(Groups, optimGrps);
    optimData = optimData(include,:);
    Time = Time(include,:);
    IDs = IDs(include,:);
    Groups = Groups(include,:);
    
    % process data so that if there are multiple measurements for a given time
    % point, replace with the average of those measurements
    [~,ia,G] = unique([Groups, IDs, Time], 'rows');
    optimData = splitapply(@(X) nanmean(X,1), optimData, G );
    Time = Time(ia,:);
    IDs = IDs(ia,:);
    Groups = Groups(ia,:);
else
    StatusOK = false;
    Message = 'The selected Data for Optimization file is empty.';
    return
end
% At this point, the data contains measurements only for unique time values


%% Generate structure containing pertinent Task information to pass to the
% objective function
% do this up-front so that it isn't done on every call to the objective
% function
nItems = length(obj.Item);

% for each task-group item
for ii = 1:nItems

    % get the task obj from the settings obj
    tskInd = find(strcmp(obj.Item(ii).TaskName,{obj.Settings.Task.Name}));
    tObj_i = obj.Settings.Task(tskInd);
    
    % Validate
    [ThisStatusOk,ThisMessage] = validate(tObj_i,false);    
    if isempty(tObj_i)
        continue
    elseif ~ThisStatusOk
        warning('Error loading task %s. Skipping [%s]...', taskName,ThisMessage)
        continue
    end       
    
    tObj_i.compile();
    
    ItemModels.Task(ii) = tObj_i;
   
end % for ii = ...


%% pre-optimization check
p0 = estParamData(:,3);

[~, thisStatusOK, thisMessage] = objectiveFun(p0,paramObj,ItemModels,Groups,IDs,Time,optimData,dataNames,obj);

if ~thisStatusOK
    Message = sprintf('%s\nError encountered for initial parameter set P0_1:%s.\nAborting optimization.', Message, thisMessage);
    StatusOK = false;
    return
end
    
%% Call optimization program
switch obj.AlgorithmName
    case 'ScatterSearch'
        if obj.Session.UseParallel
            [VpopParams,StatusOK,ThisMessage] = run_ss_par(@(est_p) objectiveFun(est_p,paramObj,ItemModels,Groups,IDs,Time,optimData,dataNames,obj),estParamData);
        else
            [VpopParams,StatusOK,ThisMessage] = run_ss_ser(@(est_p) objectiveFun(est_p,paramObj,ItemModels,Groups,IDs,Time,optimData,dataNames,obj),estParamData);
        end
        
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        
        if ~StatusOK
            path(myPath);
            return
        end
        
    case 'ParticleSwarm'
        N = size(estParamData,1);
        try
            StatusOK = true;
            LB = estParamData(:,1);
            UB = estParamData(:,2);
            p0 = estParamData(:,3);

            options = optimoptions('ParticleSwarm', 'Display', 'iter', 'FunctionTolerance', .1, 'MaxTime', 12000, ...
                'UseParallel', obj.Session.UseParallel, 'FunValCheck', 'on', 'UseVectorized', false, 'PlotFcn',  @pswplotbestf, ...
                'InitialSwarmMatrix', p0');
            
            VpopParams = particleswarm( @(est_p) objectiveFun(est_p',paramObj,ItemModels,Groups,IDs,Time,optimData,dataNames,obj), N, LB, UB, options);
        catch err
            StatusOK = false;
            warning('Encountered error in particle swarm optimization')
            Message = sprintf('%s\n%s\n',Message,err.message);
            path(myPath);
            return
        end    
        

    case 'Local'
        % parameter bounds
        LB = estParamData(:,1);
        UB = estParamData(:,2);

        % options
        LSQopts = optimoptions(@lsqnonlin,'MaxFunctionEvaluations',1e4,'MaxIterations',1e4,'UseParallel',false,'FunctionTolerance',1e-5,'StepTolerance',1e-3,...
            'Display', 'iter', 'PlotFcn', @optimplotfval, 'UseParallel', obj.Session.UseParallel );

        % fit
        p0 = estParamData(:,3);
        try
        VpopParams = lsqnonlin(@(est_p) objectiveFun(est_p,paramObj,ItemModels,Groups,IDs,Time,optimData,dataNames,obj), p0, LB, UB, LSQopts);
        VpopParams = VpopParams';
        catch err
            StatusOK = false;
            warning('Encountered error in local optimization')
            Message = sprintf('%s\n%s\n',Message,err.message);
            path(myPath);
            return            
        end
            
end % switch

% VpopParams is a matrix of patients and varying parameter values
% patients run along the rows, parameters along the columns
% VpopParams only contains the parameters that were varied for
% optimization

%% Parse and save outputs
% transform parameters back
VpopParams(:,logInds) = 10.^VpopParams(:,logInds);

% fix timestamp
timeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');

% if if necessary, replicate parameters for each initial condition
if isempty(obj.SpeciesIC)
    % if no initial condition data is specified
    % make a single Vpop with default group ICs for each patient
    Vpop = VpopParams;
    ICspecNames = {};
else
    % if initial condition data is specified
    % Replicate parameters and match with initial conditions from data
    % Only include initial conditions measured in the data
    % If an initial condition is missing for a given ID or group, use model
    % default instead
    
    % get names of all species for which there is initial condition data,
    % across groups
    ICspecNames = {obj.SpeciesIC.SpeciesName};
    
    % get indices of all species for which there is initial condition data,
    % across groups. need to do this so that the Vpops for each group are
    % of the same size and can be concatentated
    allSpeciesInds = [];
%     for grp1 = 1:length(ItemModels)
%         allSpeciesInds = union(allSpeciesInds,ItemModels(grp1).SpeciesInds);
%     end
    
    % prepare for a concatenated Vpop
    Vpop = [];
    nPatients = size(VpopParams,1);
    
    % make a Vpop for each group
    for grp1 = 1:length(obj.Item)
        Vpop_grp = [];
        
        % get indices of relevant rows
        grpInds1 = find(Groups == str2double(obj.Item(grp1).GroupID));
        
        % grab group data
        IDs_grp1 = IDs(grpInds1);
        Time_grp1 = Time(grpInds1);
        optimData_grp1 = optimData(grpInds1,:);
        
        % for each ID (varying initial conditions and time points in the same model)
        uniqueIDs_grp1 = unique(IDs_grp1);
        SpeciesIC = obj.SpeciesIC;

        for pat = 1:nPatients
            for id1 = 1:length(uniqueIDs_grp1)
                % get time and data values for this ID
                optimData_id1 = optimData_grp1(IDs_grp1 == uniqueIDs_grp1(id1),:);
                Time_id1 = Time_grp1(IDs_grp1 == uniqueIDs_grp1(id1));
                
                %get species IC values from data for the current ID
                % use average of values with t <= 0
                [~,spIdx] = ismember({SpeciesIC.DataName},dataNames); % columns in the data table
                IC = optimData_id1(Time_id1<=0,spIdx);
                IC = nanmean(IC,1);
                                
                % Add VP parameters and data ICs for this ID to the Vpop
                Vpop_grp = [Vpop_grp;VpopParams(pat,:),IC];

            end % for id1 = ...
        end % for pat = ...
        
        Vpop = [Vpop;Vpop_grp];
        
        % add headers to current group's Vpop
%         Vpop_grp = [[estParamNames', fixedParamNames' ,ICspecNames]; num2cell(Vpop_grp)];

        
        VpopHeaders = [estParamNames',ICspecNames,fixedParamNames'];
        VpopData = [num2cell(Vpop_grp), num2cell(repmat(fixedParamData', size(Vpop_grp,1), 1)) ];
        
        % reoder according to original names in parameters file
        [bParam,paramOrder] = ismember(VpopHeaders,allParamNames);
        VpopHeaders = [VpopHeaders(paramOrder(bParam)), VpopHeaders(~bParam)];
        VpopData = [VpopData(:, paramOrder(bParam)), VpopData(:, ~bParam)];
        
        Vpop_grp = [ VpopHeaders; VpopData];

        % save current group's Vpop
        SaveFlag = true;
        SaveFilePath = fullfile(obj.Session.RootDirectory,obj.OptimResultsFolderName);
        if ~exist(SaveFilePath,'dir')
            [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
            if ~ThisStatusOk
                Message = sprintf('%s\n%s\n',Message,ThisMessage);
                SaveFlag = false;
            end
        end
        
        if SaveFlag
            VpopNames{grp1} = ['Results - Optimization = ' obj.Name ' - Group = ' obj.Item(grp1).GroupID ' - Date = ' timeStamp];
            ResultsFileNames{grp1} = [VpopNames{grp1} '.xlsx'];
            if ispc
                try
                    [StatusOK, ThisMessage] = xlswrite(fullfile(SaveFilePath,ResultsFileNames{grp1}),Vpop_grp);
                catch error
                    fName = regexp(error.message, '(C:\\.*\.mat)', 'match');
                    if length(fName{1}) > 260
                        ThisMessage = sprintf('%s\n* Windows cannot save filepaths longer than 260 characters. See %s for more details.\n', ...
                           ThisMessage, 'https://www.howtogeek.com/266621/how-to-make-windows-10-accept-file-paths-over-260-characters/' );
                    end
                end
            else
                xlwrite(fullfile(SaveFilePath,ResultsFileNames{grp1}),Vpop_grp);
            end
        else
            StatusOK = false;
            ThisMessage = 'Unable to save results to Excel file.';
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
        end
    end % for grp1 = ...
    
    
end % if


% PWeight = ones(length(Vpop_grp),1)/length(Vpop_grp);
% Vpop = [[estParamNames',specNames,{'PWeight'}]; num2cell([Vpop,PWeight])];

% add headers to final Vpop

VpopHeaders = [estParamNames',ICspecNames,fixedParamNames'];
VpopData = [num2cell(Vpop), num2cell(repmat(fixedParamData', size(Vpop,1), 1)) ];

% reoder according to original names in parameters file
[bParam,paramOrder] = ismember(VpopHeaders,allParamNames);
VpopHeaders = [VpopHeaders(paramOrder(bParam)), VpopHeaders(~bParam)];
VpopData = [VpopData(:, paramOrder(bParam)), VpopData(:, ~bParam)];

Vpop = [ VpopHeaders; VpopData];


% Vpop = [[estParamNames',ICspecNames,fixedParamNames']; [num2cell(Vpop), num2cell(repmat(fixedParamData', size(Vpop,1), 1)) ]];

% save final Vpop
SaveFlag = true;
SaveFilePath = fullfile(obj.Session.RootDirectory,obj.OptimResultsFolderName);
if ~exist(SaveFilePath,'dir')
    [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
    if ~ThisStatusOk
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        SaveFlag = false;
    end
end

if SaveFlag
    VpopNames{end} = ['Results - Optimization = ' obj.Name ' - Date = ' timeStamp];
    ResultsFileNames{end} = [VpopNames{end} '.xls'];
    try
        if ispc
            xlswrite(fullfile(SaveFilePath,ResultsFileNames{end}),Vpop);
        else
            xlwrite(fullfile(SaveFilePath,ResultsFileNames{end}),Vpop);
        end
    catch xlsError
        Message = sprintf('%s\n%s: %s', Message,'Unable to save results to Excel file.', ...
            xlsError.message);
        StatusOK = false;
    end
else
    StatusOK = false;
    ThisMessage = 'Unable to save results to Excel file.';
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
end


%% Objective function
    function [objective,varargout] = objectiveFun(est_p,paramObj,ItemModels,Groups,IDs,Time,optimData,dataNames,obj)
        tempStatusOK = true;
        tempMessage = '';
        
%         inputStr = '(species,data,simTime,dataTime,allData,ID,Grp,currID,currGrp)';
        logInds = reshape( paramObj.logInds, [], 1);
        
        if ~isempty(paramObj.fixedParamData)
            fixed_p = paramObj.fixedParamData;
        else
            fixed_p = [];
        end
        
        estParamNames = paramObj.estParamNames;
        fixedParamNames = paramObj.fixedParamNames;
        
        est_p(logInds) = 10.^(est_p(logInds));
        objectiveVec = [];
        
        % added property ObjectiveName to SpeciesData class
        objective_handles = cell(length(obj.SpeciesData),1);
        for spec = 1:length(obj.SpeciesData)
            objective_handles{spec} = str2func( regexprep(obj.SpeciesData(spec).ObjectiveName, '.m$', ''));
        end
        SpeciesData = obj.SpeciesData;
        SpeciesIC = obj.SpeciesIC;
        
        % try calculating the objective
        try
            
            groupErrorCounts = zeros(1,length(obj.Item));
            groupErrorMessages = cell(1,length(obj.Item));
            groupErrorMessageCounts = cell(1,length(obj.Item));
            
            % for each Group (varying experiments)
            for grpIdx = 1:length(obj.Item)
                
                % get indices of relevant rows
                currGrp = str2double(obj.Item(grpIdx).GroupID);
                grpInds = find(Groups == currGrp);
                
                % grab group data
                IDs_grp = IDs(grpInds);
                Time_grp = Time(grpInds);
                optimData_grp = optimData(grpInds,:);
                
                % for each ID (varying initial conditions (animals) and time points in the same experiment)
                uniqueIDs_grp = unique(IDs_grp);
                for id = 1:length(uniqueIDs_grp)
                    currID = uniqueIDs_grp(id);
                    % get time and data values for this ID
                    optimData_id = optimData_grp(IDs_grp == currID,:);
                    Time_id = Time_grp(IDs_grp == currID);
                    
                    %get species IC values from data for the current ID
                    % use average of values with t <= 0
                    [~,spIdx] = ismember({SpeciesIC.DataName},dataNames); % columns in the data table
                    IC = zeros(length(spIdx),1);
                    for k=1:length(spIdx)
                        IC(k) = SpeciesIC(spIdx(k)).evaluate(optimData_id(Time_id<=0,spIdx(k)));
                        IC(k) = nanmean(IC,1);
                    end                    
 
                    % simulate experiment for this ID
                    OutputTimes = sort(unique(Time_id(Time_id>=0)));
                    StopTime = max(Time_id(Time_id>=0));
                    Values = [IC;est_p];
                    Names = [{SpeciesIC.SpeciesName}'; estParamNames];
                    if ~isempty(fixed_p)
                        Values = [Values; fixed_p];
                        Names = [Names; fixedParamNames];
                    end
                    
                    [simData_id, thisStatusOK, thisMessage] = ItemModels.Task(grpIdx).simulate(...
                        'Names', Names, ...
                        'Values', Values, ...
                        'OutputTimes', OutputTimes, ...
                        'StopTime', StopTime );
                    
                    if ~thisStatusOK
                        % simulation failed for this particular task
                        % keep track of the number of times each simulation
                        % failed and the error messages that were produced
                        % for this group
                        Message = sprintf('%s\n%s\n', Message, thisMessage);
                        fprintf('Warning: Group %d produced error %s\n', currGrp, thisMessage);
                        
                    end
                                        
                    % generate elements of objective vector by comparing model
                    % outputs to data
                    for spec = 1:length(SpeciesData)
                        % name of current species in the dataset
                        currDataName = SpeciesData(spec).DataName;
                        
                        
                        
                        try
                            % grab each model output for the measured species                        
                            [simTime_spec,simData_spec] = selectbyname(simData_id,SpeciesData(spec).SpeciesName);
                            % transform to match the format of the measured data
                            simData_spec = SpeciesData(spec).evaluate(simData_spec);
                        catch tempME
                            tempStatusOK = false;
                            tempThisMessage = sprintf('There is an error in one of the function expressions in the SpeciesData mapping. %s', tempME.message);
                            tempMessage = sprintf('%s\n%s\n',tempMessage,tempThisMessage);
                            objective = 1e6;
                            if nargout>1
                                varargout{1} = tempStatusOK;
                                varargout{2} = tempMessage;
%                                 varargout{3} =  groupErrorCounts;
%                                 varargout{4} = groupErrorMessages;
%                                 varargout{5} = groupErrorMessageCounts;
                            end
                            path(myPath);
                            return                    
                        end % try
                        
                        % compare model outputs to data and concatenate onto the
                        % objective vector, keeping only time points for which
                        % there is data for that species
                        optimData_spec = optimData_id(Time_id>=0,strcmp(SpeciesData(spec).DataName,dataNames));
                        nonNanDataIdx = find(~isnan(optimData_spec));
                        if isempty(nonNanDataIdx)
                            % ignore data if it is all missing
                            continue
                        end
                        simData_spec = simData_spec(nonNanDataIdx);
                        dataTime_spec = sort(Time_id(Time_id>=0));
                        dataTime_spec = dataTime_spec(~isnan(optimData_spec));
                        
                        % simTime was set to be the unique list of times for
                        % this ID, therefore it should be the same length
                        % as the output of sort(Time_id(Time_id>=0))
                        simTime_spec = simTime_spec(~isnan(optimData_spec));
                        
                        % remove NaNs from optimData_spec
                        optimData_spec = optimData_spec(~isnan(optimData_spec));
                        
                        % optimData_spec, simData_spec, and dataTime_spec
                        % should now be vectors of the same length and contain
                        % no nans
                        
                        % Inputs are '(species,data,simTime,dataTime,allData,ID,Grp,currID,currGrp)'
                        % or           (simData_spec,optimData_spec,simTime_spec,dataTime_spec,optimData(:,strcmp(currDataName,dataNames)),IDs,Groups,currID,currGrp)
                        thisObj = objective_handles{spec}(simData_spec,optimData_spec,simTime_spec,dataTime_spec,optimData(:,strcmp(currDataName,dataNames)),IDs,Groups,currID,currGrp);
                        objectiveVec = [objectiveVec; thisObj];
                        
                    end % for spec = ...
                    
                end % for id = ...
                
            end % for grp = ...
            
        catch simErr
            warning(simErr.message)
            % if objective calculation fails
            objectiveVec = [];
            for grpIdx = 1:length(obj.Item)
                
                % get indices of relevant rows
                currGrp = str2double(obj.Item(grpIdx).GroupID);
                grpInds = find(Groups == currGrp);
                
                % grab group data
                IDs_grp = IDs(grpInds);
                optimData_grp = optimData(grpInds,:);
                
                % for each ID
                uniqueIDs_grp = unique(IDs_grp);
                for id = 1:length(uniqueIDs_grp)
                    currID = uniqueIDs_grp(id);
                    % get data values for this ID
                    optimData_id = optimData_grp(IDs_grp == currID,:);
                    
                    %
                    for spec = 1:length(SpeciesData)
                        try
                            optimData_spec = optimData_id(Time_id>=0,strcmp(SpeciesData(spec).DataName,dataNames));
                        catch err
                            disp(err.message)
                        end
                        objectiveVec = [objectiveVec; 1e6*ones(length(optimData_spec(~isnan(optimData_spec))),1)];
                    end % for spec = ...
                end % for id
            end % for grp
        end % try
               
        if ~strcmp(obj.AlgorithmName, 'Local')
            % return scalar objective function
            objective = nansum(objectiveVec);
        else
            objective = objectiveVec;
        end
        
        if nargout>1
            varargout{1} = tempStatusOK;
            varargout{2} = tempMessage;
        end
        
    end % function

path(myPath);

% close dialog
if ~isempty(hDlg) && ishandle(hDlg)
    delete(hDlg);
end

end % function

