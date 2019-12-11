function [StatusOK,Message,ResultFileNames,Cancelled, varargout] = simulationRunHelper(obj,varargin)
% Function that performs the simulations using the (Task,
% VirtualPopulation) pairs listed in the simulation object "obj".
% Simulates the model using the variants, doses, rules, reactions, and 
% species specified in each Task for each set of parameters in the 
% corresponding VirtualPopulation.

StatusOK = true;
Message = '';
ResultFileNames = {};
if nargout > 4
    varargout{1} = {};
end

Cancelled = false;

%% update path to include everything in subdirectories of the root folder
myPath = path;
%addpath(genpath(obj.Session.RootDirectory));


%% parse inputs and initialize
% [nItems, ResultFileNames, output, Pin, paramNames, extraOutputTimes, simName, allTaskNames, allVpopNames] = parseInputs(obj,varargin);

[options, ThisStatusOK, ThisMessage] = parseInputs(obj,varargin{:});
[ThisStatusOK,ThisMessage] = validatePin(obj, options, ThisStatusOK, ThisMessage);

if ~ThisStatusOK
    StatusOK = false;
    Message = ThisMessage;
    if nargout==6
        varargout{2} = {};
    end
    return;
end

VpopWeights = [];
ItemModels = [];

% Initialize waitbar
Title1 = sprintf('Configuring models...');
hWbar1 = uix.utility.CustomWaitbar(0,Title1,'',false);

nBuildItems = options.nBuildItems;
nRunItems = options.nRunItems;

validRunItems = true(1,nRunItems);

if ~isempty(options.ItemModels)
    % Item Models were already built and just need to be resimulated
    ItemModels = options.ItemModels;
else
    % Configure models for each (task, vpop) pair (i.e. for each simulation item)
    ItemModels = struct('Vpop', [], 'Task', [], 'Group', '', 'Names', {}, 'Values', [], 'nPatients', []);
    
    for ii = 1:nBuildItems
        % update waitbar
        uix.utility.CustomWaitbar(ii/nBuildItems,hWbar1,sprintf('Configuring model for task %d of %d...',ii,nBuildItems));

        % grab the names of the task and vpop for the i'th simulation
        taskName = obj.Item(ii).TaskName;
        vpopName = obj.Item(ii).VPopName;

        % Validate
        taskObj = obj.Settings.Task(strcmp(taskName,options.allTaskNames));
        [ThisStatusOK,ThisMessage] = validate(taskObj,false);        
        if isempty(taskObj)
            validRunItems(ii) = false;
            continue
        elseif ~ThisStatusOK
            StatusOK = false;
            ThisMessage = sprintf('Error loading task "%s". Skipping [%s]...', taskName,ThisMessage);
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            validRunItems(ii) = false;            
    %         continuesim
        end

        % find the relevant task and vpop objects in the settings object
        vpopObj = [];    
        if ~isempty(vpopName) && ~strcmp(vpopName,QSP.Simulation.NullVPop)
            vpopObj = obj.Settings.VirtualPopulation(strcmp(vpopName,options.allVpopNames));
%             if isempty(vpopObj)
%                 StatusOK = false;
%                 Message = sprintf('Invalid vpop "%s". VPop does not exist.',vpopName);
%                 continue
%             else
            if ~isempty(vpopObj)
                [ThisStatusOK,ThisMessage] = validate(vpopObj,false);
            end
            if ~ThisStatusOK
                StatusOK = false;
                ThisMessage = sprintf('Error loading vpop "%s". Skipping [%s]...', vpopName,ThisMessage);            
                Message = sprintf('%s\n%s\n',Message,ThisMessage);
                continue
            end
        end

        % group of the task-vpop item
        groupObj = obj.Item(ii).Group;

        % Load the Vpop and parse contents 
       [ThisItemModel, ThisStatusOK, ThisMessage] = constructVpopItem(taskObj, vpopObj, groupObj, options, Message);
       if ~ThisStatusOK
           StatusOK = false;
           Message = sprintf('%s\n%s\n',Message,ThisMessage);
           break
       end
       
       if ii == 1
           ItemModels = ThisItemModel;
       else
           ItemModels(ii) = ThisItemModel;
       end


    end % for ii...
end
% close waitbar
uix.utility.CustomWaitbar(1,hWbar1,'Done.');
if ~isempty(hWbar1) && ishandle(hWbar1)
    delete(hWbar1);
end


%%%% Simulate each parameter set in the vpop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize waitbar
Title2 = sprintf('Simulating tasks...');
hWbar2 = uix.utility.CustomWaitbar(0,Title2,'',true);

%% Cell containing all results
output = cell(1,nRunItems);
ResultFileNames = cell(nRunItems,1);

if ~iscell(options.Pin)
    options.Pin = {options.Pin};
end

if ~isempty(ItemModels)
    

    % update simulation time stamp
    runItems = find(validRunItems); % only those for which no error was produced during model compilation/configuration
    if ~isempty(runItems)
        updateLastSavedTime(obj);        
    end
    
    task_indices = [];
    if obj.Session.UseParallel
        ParallelCluster = obj.Session.ParallelCluster;
        c = parcluster(ParallelCluster);    

        UDF_files = dir(fullfile(taskObj.Session.UserDefinedFunctionsDirectory,'**','*.m'));
        UDF_files = arrayfun(@(x) fullfile(x.folder,x.name), UDF_files, 'UniformOutput', false);

        RootPath = { fullfile(fileparts(fileparts(mfilename('fullpath'))),'app'), fullfile(fileparts(fileparts(mfilename('fullpath'))),'FromGenentech'), ...
            fullfile(fileparts(fileparts(mfilename('fullpath'))),'utilities')};

        job = createJob(c, 'AttachedFiles', [UDF_files, RootPath]);
    else
        job = [];
    end
    
    taskIndex=1;
    taskIDs = {};
    for ii = runItems
        ItemModel = ItemModels(options.runIndices(ii));
        if ~StatusOK % interrupted
            break
        end
        % update waitbar
%         if isempty(hWbar2)
            set(hWbar2, 'Name', sprintf('Simulating task %d of %d',ii,nRunItems))
            uix.utility.CustomWaitbar(0,hWbar2,'');
%         end
        options.WaitBar = hWbar2;

        % start simulations for virtual patients
        for jj=1:length(options.Pin)
            thisOptions = options;
            thisOptions.Pin = options.Pin{jj};
            if ~isempty(thisOptions.paramNames)
                thisOptions.paramNames = options.paramNames{jj};
            else
                thisOptions.paramNames = {};
            end
            
            thisOptions.usePar = obj.Session.UseParallel;
            thisOptions.ParallelCluster = obj.Session.ParallelCluster;
            thisOptions.UDF = obj.Session.UserDefinedFunctionsDirectory;
            
            [thisResults, this_nFailedSims, ThisStatusOK, ThisMessage, Cancelled, taskID] = simulateVPatients(ItemModel, thisOptions, Message, job);
            nFailedSims{ii,jj} = this_nFailedSims;
            Results_array{ii,jj} = thisResults;
            StatusOK_array{ii,jj} = ThisStatusOK;
            Messages{ii,jj} = ThisMessage;
            if ~isempty(taskID)
                taskIDs{taskIndex} = taskID;
            end
            
            taskIndex = taskIndex + 1;
                                   
            task_indices = [task_indices; ii, jj];  
            
            
        end
    end
    
    % run job if set up for cluster computing
    
    taskIndex = 1;
    if ~isempty(taskIDs)
        set(hWbar2, 'Name', 'Please wait')        
        uix.utility.CustomWaitbar(0,hWbar2,sprintf('Submitted job with %d tasks to cluster %s.\nWaiting for completion.', nRunItems, ParallelCluster));        
        submit(job)
        wait(job)
        data = fetchOutputs(job);
%         delete(hWbar2);
        
        % unpack results
        
        for ii = runItems        
            for jj=1:length(options.Pin)
                Results_array{ii,jj} = data{taskIndex, 1};
                nFailedSims{ii,jj} = data{taskIndex, 2};
                StatusOK_array{ii,jj} = data{taskIndex, 3};                
                Messages{ii,jj} = data{taskIndex, 4};           
                ErrObj{ii,jj} = data{taskIndex,5};
                taskIndex = taskIndex + 1;
            end
        end
    
    end
    
    % gather results
    taskIndex = 1;
    if isvalid(hWbar2)
        set(hWbar2, 'Name', 'Processing results')
    end
    for ii = runItems        
        ItemModel = ItemModels(options.runIndices(ii));
        if isvalid(hWbar2)
            uix.utility.CustomWaitbar(ii/length(runItems),hWbar2,'');
        end
        for jj=1:length(options.Pin)

            if ~StatusOK_array{ii,jj}
                StatusOK = false;
                Message = sprintf('%s\n%s\n',Message,Messages{ii,jj});                
                continue
            end
            
            %%% Save results of each simulation in different files %%%%%%%%%%%%%%%%%%%%
            SaveFlag = isempty(options.Pin{1}); % don't save if PIn is provided

            % keep the VpopWeights for this group
            Results = Results_array{ii,jj};
            Results.VpopWeights = ItemModel.VpopWeights;

            % add results to output cell
            output{jj,ii} = Results;

            SaveFilePath = fullfile(obj.Session.RootDirectory,obj.SimResultsFolderName);
            if ~exist(SaveFilePath,'dir')
                [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
                if ~ThisStatusOk
                    Message = sprintf('%s\n%s\n',Message,ThisMessage);
                    SaveFlag = false;
                end
            end

            if SaveFlag
                % Update ResultFileNames
                if ~isempty(obj.Item(options.runIndices(ii)).Group)
                    grpStr = obj.Item(options.runIndices(ii)).Group;
                else
                    grpStr = '';
                end
                ResultFileNames{ii} = ['Results - Sim = ' options.simName ...
                    ', Task = ' obj.Item(options.runIndices(ii)).TaskName ...
                    ' - Vpop = ' obj.Item(options.runIndices(ii)).VPopName ...
                    ' - Group = ' grpStr ...
                    ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS') '.mat'];

                try
                    if isempty(VpopWeights)
                        save(fullfile(SaveFilePath,ResultFileNames{ii}), 'Results')
                    else
                        save(fullfile(SaveFilePath,ResultFileNames{ii}), 'Results', 'VpopWeights')
                    end
                catch error
                    ThisMessage = 'Error encountered saving file. Check that the save file name is valid.';
                    
                    if ispc
                        fName = regexp(error.message, '(C:\\.*\.mat)', 'match');
                        if length(fName{1}) > 260
                            ThisMessage = sprintf('%s\n* Windows cannot save filepaths longer than 260 characters. See %s for more details.\n', ...
                               ThisMessage, 'https://www.howtogeek.com/266621/how-to-make-windows-10-accept-file-paths-over-260-characters/' );
                        end
                    end
%             
                    Message = sprintf('%s\n%s\n\n%s\n',Message,ThisMessage,error.message);        
                    StatusOK = false;
                    % close waitbar
                    uix.utility.CustomWaitbar(1,hWbar2,'Done.');
                    if ~isempty(hWbar2) && ishandle(hWbar2)
                        delete(hWbar2);
                    end
                    return
                end
                % right now it's one line of Message per Simulation Item
                if nFailedSims{ii,jj} == ItemModel.nPatients
                    ThisMessage = 'No simulations were successful. (Check that dependencies are valid.)';
                else
                    ThisMessage = [num2str(ItemModel.nPatients-nFailedSims{ii,jj}) ' simulations were successful out of ' num2str(ItemModel.nPatients) '.'];
                end
                Message = sprintf('%s\n%s\n',Message,ThisMessage);        
            elseif isfield(options,'Pin') && isempty(options.Pin)
                StatusOK = false;
                ThisMessage = 'Unable to save results to MAT file.';
                Message = sprintf('%s\n%s\n',Message,ThisMessage);
            end
            
            taskIndex = taskIndex + 1;
            
        end % for jj

    end % for ii = ...


    
end


% close waitbar
uix.utility.CustomWaitbar(1,hWbar2,'Done.');
if ~isempty(hWbar2) && ishandle(hWbar2)
    delete(hWbar2);
end

% output the results of all simulation items if Pin in provided
if nargout > 4
    varargout{1} = output;
end

% save the exported model object
if nargout > 5
    varargout{2} = ItemModels;
end

% restore path
path(myPath);

end

% [nItems, ResultFileNames, output, Pin, paramNames, extraOutputTimes, simName, allTaskNames, allVpopNames] = parseInputs(obj,varargin)
function [options, StatusOK, Message] = parseInputs(obj, varargin)

StatusOK = true;
Message = '';

%% get number of items to simulate
if ~isempty(obj)
    nBuildItems = length(obj.Item);
else
    nBuildItems = 0;
    StatusOK = false;
    ThisMessage = sprintf('There are no simulation items.');
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
end

ParamValues = []; % input parameters for simulation (empty by default)
ParamNames = {}; % parameter names
extraOutputTimes = [];

if nargin > 2
    ParamValues = varargin{1};
    if ~isempty(ParamValues)
        ParamValues = cellfun(@(x) reshape(x,1,[]), ParamValues, 'UniformOutput', false); % row vector
    end
    ParamNames = varargin{2};
end

% allow for manual specification of output times to be included on top of
% the task-specific output times
if nargin > 3
    extraOutputTimes = varargin{3};
end

if nargin > 4
    options.ItemModels = varargin{4};
else
    options.ItemModels = [];
end

if nargin > 5
    % run specified
    options.runIndices = varargin{5};
    nRunItems = length(options.runIndices);
else
    % run all
    options.runIndices = 1:nBuildItems;
    nRunItems = nBuildItems;
end

if nargin > 6
    options.hWaitBar = varargin{6};
else
    options.hWaitBar = [];
end

% Get the simulation object name
simName = obj.Name;

% Extract the names of all tasks and vpops %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
allTaskNames = {obj.Settings.Task.Name};
allVpopNames = {obj.Settings.VirtualPopulation.Name};


%% construct options object
options.nBuildItems = nBuildItems;
options.nRunItems = nRunItems;
options.Pin = ParamValues;
options.paramNames = ParamNames;
options.extraOutputTimes = extraOutputTimes;
options.simName = simName;
options.allTaskNames = allTaskNames;
options.allVpopNames = allVpopNames;

end

function [StatusOK,Message] = validatePin(obj, options, StatusOK, Message)
Pin = options.Pin;
nBuildItems = options.nBuildItems;

if isempty(Pin)
    for ii = 1:nBuildItems
        vpopName = obj.Item(ii).VPopName;
        if strcmp(vpopName,QSP.Simulation.NullVPop)
            % do not create a vpopObj for the model default virtual population
            continue
        end
        if ~isempty(vpopName) 
            tmpObj = obj.Settings.VirtualPopulation(strcmp(vpopName,options.allVpopNames));
            if isempty(tmpObj) 
                StatusOK = false;
                ThisMessage = sprintf('The virtual population named %s is invalid.', vpopName); % TODO: Replace with ThisMessage/Message?
                Message = sprintf('%s\n%s\n',Message,ThisMessage);
                break
            elseif isempty(tmpObj.FilePath)
                StatusOK = false;
                ThisMessage = sprintf('The virtual population named %s is incomplete.',vpopName);
                Message = sprintf('%s\n%s\n',Message,ThisMessage);
%                 error('The virtual population named %s is incomplete.', vpopName) % TODO: Replace with ThisMessage/Message?
                break
            end % if
        else
            StatusOK = false;
            ThisMessage = sprintf('A virtual population is missing a name.');
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            break
        end % if
        
    end % for
end % if

end

function [ItemModel, StatusOK, Message] = constructVpopItem(taskObj, vpopObj, groupObj, options, Message)
    % they are 1) all full and Pin is empty or 2) all full and Pin is not
    % empty or 3) all empty and Pin is not empty
    % case 1) only need to export model with parameters in the Vpop
    % case 2) need to export model with all parameters and find the
    % locations of each parameter in the Vpop
    % case 3) need to export model with all parameters, but don't need to
    % worry about the Vpop
    
    VpopWeights     = [];
   
    ItemModel.Vpop = vpopObj;
    ItemModel.Task = taskObj;
    ItemModel.Group = groupObj;
    
    if ~isempty(vpopObj) % AG: TODO: added ~isempty(vpopObj) for function-call from plotOptimization. Need to verify with Genentech
        
%         if ~ispc
%             tmp = readtable(vpopObj.FilePath);
%             vpopTable = table2array(tmp);
%             params = tmp.Properties.VariableNames;
%         else
%             [vpopTable,params,raw] = xlsread(vpopObj.FilePath);
%             params = raw(1,:);
%             vpopTable = cell2mat(raw(2:end,:));
%         end
        
        [params, vpopTable, StatusOK, Message] = xlread(vpopObj.FilePath);
        vpopTable = cell2mat(vpopTable);
        if ~StatusOK
            return
        end
        
        
%         params = params(1,:);
%         T = readtable(vpopObj.FilePath);
%         vpopTable = table2cell(T);         
%         params = T.Properties.VariableNames;    
        
        % subset the vpop to the relevant group if it is defined in the
        % vpop
        [hasGroupCol, groupCol] = ismember('Group', params);
        if hasGroupCol && ~isempty(groupObj)
            groupVec = vpopTable(:,groupCol);
            vpopTable = vpopTable(str2num(groupObj)==groupVec,:); % filter
            if isempty(vpopTable)
                % no members of this group in the vpop file
                StatusOK =  false;
                Message = sprintf('Vpop file does not any entries with group = %d\n', str2num(groupObj));
                return
            end
        end

        % check whether the last column is PWeight
        if strcmp('PWeight',params{end})
            VpopWeights     = vpopTable(:,end);
            vpopTable   = vpopTable(:,1:end-1);
        end 
        
        % check if there are parameters which are not contained in the
        % model
        
        if ~isempty(setdiff( params, [taskObj.SpeciesNames; taskObj.ParameterNames; {'PWeight','Group','ID'}']))
            StatusOK = false;
            Message = sprintf(['%s%s: Invalid parameters contained in the vpop file. Valid column names includes "PWeight", "Group", "ID",'...
                    'and names of parameters/species in the model.\n\nPlease check for consistency with the selected task model.\n'], ...
                Message, taskObj.Name);
%             return

        end
        
        nPatients = size(vpopTable,1);
        Values = vpopTable;
        Names = params;
    else 
        Names = {};
        Values = {};
        nPatients = 1;
    end % if
    
    ItemModel.Names = Names;
    ItemModel.Values = Values;    
    ItemModel.nPatients = nPatients;    
    ItemModel.VpopWeights = VpopWeights;
    
    StatusOK = true;
    
end

function [Results, nFailedSims, StatusOK, Message, Cancelled, taskID] = simulateVPatients(ItemModel, options, Message, job)  
       
    [Results, nFailedSims, StatusOK, Message, Cancelled, taskID] = simulateVPatients_(ItemModel, options, Message, job);
    
end
