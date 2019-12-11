function [StatusOK,Message,ResultsFileName,VpopName] = cohortGenerationRunHelper(obj)
       
    if obj.Session.UseParallel
        [StatusOK,Message,ResultsFileName,VpopName] = cohortGenerationRunHelper_par(obj);
    else
        [StatusOK,Message,ResultsFileName,VpopName] = cohortGenerationRunHelper_ser(obj);    
    end
    
end

function [StatusOK,Message,ResultsFileName,VpopName] = cohortGenerationRunHelper_par(obj)
% Function that generates a Virtual population by sampling parameter space,
% running simulations, and comparing the outputs to Acceptance Criteria.

StatusOK = true;
Message = '';
ResultsFileName = '';
VpopName = '';

%% update path to include everything in subdirectories of the root folder
myPath = path;
addpath(genpath(obj.Session.RootDirectory));

%% Check number of items
if numel(obj.Item) == 0
    StatusOK = false;
    Message = 'The number of items is 0.';
    path(myPath);
    return
end

%% Load Acceptance Criteria
Names = {obj.Settings.VirtualPopulationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

if any(MatchIdx)
    vpopObj = obj.Settings.VirtualPopulationData(MatchIdx);
    
    [ThisStatusOk,ThisMessage,accCritHeader,accCritData] = importData(vpopObj,vpopObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    accCritHeader = {};
    accCritData = {};
end

%% Prepare species-data Mappings
Mappings = cell(length(obj.SpeciesData),2);
for ii = 1:length(obj.SpeciesData)
    Mappings{ii,1} = obj.SpeciesData(ii).SpeciesName;
    Mappings{ii,2} = obj.SpeciesData(ii).DataName;
end


if ~isempty(accCritHeader) && ~isempty(accCritData)
    
    % filter out any acceptance criteria that are not included
    includeIdx = accCritData(:,strcmp('Include',accCritHeader));
    if ~isempty(includeIdx)
        param_candidate = cell2mat(includeIdx);
        accCritData = accCritData(param_candidate==1,:);
    end
    
    spIdx = ismember( accCritData(:,3), Mappings(:,2));
    % [Group, Species, Time, LB, UB]
    Groups = cell2mat(accCritData(spIdx,strcmp('Group',accCritHeader)));
    unqGroups = unique(Groups);
    Time = cell2mat(accCritData(spIdx,strcmp('Time',accCritHeader)));
    Species = accCritData(spIdx,strcmp('Data',accCritHeader));
    LB_accCrit = cell2mat(accCritData(spIdx,strcmp('LB',accCritHeader)));
    UB_accCrit = cell2mat(accCritData(spIdx,strcmp('UB',accCritHeader)));
else
    
    StatusOK = false;
    Message = 'The selected Acceptance Criteria file is empty.';
    path(myPath);
    return
end



%% Load Parameters
Names = {obj.Settings.Parameters.Name};
MatchIdx = strcmpi(Names,obj.RefParamName);
if any(MatchIdx)
    pObj = obj.Settings.Parameters(MatchIdx);
    [ThisStatusOk,ThisMessage,paramHeader,paramData] = importData(pObj,pObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    paramHeader = {};
    paramData = {};
end

if ~isempty(paramHeader) && ~isempty(paramData)
    % [Include, Name, Scale, LB, UB, P0_1, ...]
    % filter missing LB/UB
    ixValid = (~isnan(cell2mat(paramData(:,strcmp('LB',paramHeader)))) & ~isnan(cell2mat(paramData(:,strcmp('UB',paramHeader))))) | ...
        ~isnan(cell2mat(paramData(:,strcmp('P0_1',paramHeader))));
    paramData = paramData(ixValid,:);
    
    paramNames = paramData(:,strcmp('Name',paramHeader));
    Scale = paramData(:,strcmp('Scale',paramHeader));
    
    LB_params = cell2mat(paramData(:,strcmp('LB',paramHeader)));
    UB_params = cell2mat(paramData(:,strcmp('UB',paramHeader)));
    
    if isempty(find(strcmpi('Dist',paramHeader)==1)) == 0
        Dist = paramData(:,strcmpi('Dist',paramHeader));
    else 
        Dist = cell(length(LB_params),1); 
        Dist(:) = {'uniform'}; %If empty, uniform distribution 
    end
    if isempty(find(strcmpi('CV',paramHeader)==1)) == 0
        CV_params = cell2mat(paramData(:,strcmpi('CV',paramHeader))); %MES add 2/14/2019
    else
        CV_params = zeros(length(LB_params),1); 
    end
    
    useParam = paramData(:,strcmpi('Include',paramHeader));
    p0 = cell2mat(paramData(:,strcmpi('P0_1',paramHeader))); % MES edit to search header instead of column number 
    if isempty(useParam)
        useParam = repmat('yes',size(paramNames));
    end
    
    useParam = strcmpi(useParam,'yes');
    perturbParamNames = paramNames(useParam);
    fixedParamNames = paramNames(~useParam);
    logInds = strcmp(Scale, 'log');
    
    LB = LB_params(useParam);
    UB = UB_params(useParam);
    CV = CV_params(useParam);
    P0_1 = p0(useParam);
    
    if any(isnan(LB) | isnan(UB))
        StatusOK = false;
        Message = 'At least one optimization parameter is missing a lower/upper bound. Check parameter file';
        path(myPath);
        return
    end
    
    logInds = logInds(useParam);
    
    LB(logInds) = log10(LB(logInds));
    UB(logInds) = log10(UB(logInds));
    fixedParams = p0(~useParam);
else
    %     LB_params = [];
    %     UB_params = [];
    StatusOK = false;
    Message = 'The selected Parameter file is empty.';
    path(myPath);
    return
end


%% Deal with initial conditions file if it is specified and exists

if ~isempty(obj.ICFileName) && ~strcmp(obj.ICFileName,'N/A') && exist(obj.ICFileName, 'file')
 % get names from the IC file
    ICTable = importdata(obj.ICFileName);
  % validate the column names
    [hasGroupCol, groupCol] = ismember('Group', ICTable.colheaders);
    if ~hasGroupCol
        StatusOK = false;
        ThisMessage = 'Initial conditions file does not contain Group column';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        return
    end
    
    % check that we are not specifying an initial condition for a species
    % that is also being sampled
    [~,ixConflictingParameters] = ismember( ICTable.colheaders, perturbParamNames);
    if any(ixConflictingParameters)
        StatusOK = false;
        Message = sprintf(['%s\nInitial conditions file contains species that are sampled in the cohort generation.  '...
            'To continue set Include=No for %s or remove them from the parameters file.\n'], ...
            Message, strjoin(perturbParamNames(ixConflictingParameters(ixConflictingParameters>0)), ','));
    end
else 
    ICTable = [];
end



%% For each task/group, load models and prepare for simulations

nItems = length(obj.Item);

obj.SimResults = {}; %cell(1,nItems);

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
    
    ItemModels.Task(ii) = tObj_i;
end % for

%% Sample parameter sets, simulate, compare to acceptance criteria
Vpop = zeros(obj.MaxNumSimulations,length(LB_params));
isValid = zeros(obj.MaxNumSimulations,1);

% set up the loop for different initial conditions
if isempty(ICTable )
    % no initial conditions specified
    groupVec = unqGroups;
else
    % initial conditions exist
    groupVec = ICTable.data(:,groupCol);
    ixSpecies = setdiff(1:numel(ICTable.colheaders), groupCol); % columns of species in IC table
end

%% loop over the candidates until enough are generated
hWbar = uix.utility.CustomWaitbar(0,'Virtual cohort generation','Generating virtual cohort...',true);


ViolationTable = [];
% param_candidate = LB + (UB-LB).*rand(size(LB)); % initial candidate
tmp = p0;
logInds = strcmp(Scale, 'log');

tmp(logInds) = log10(tmp(logInds));
logInds = logInds(useParam);

%% MES 2/13: indicate the indices that require normal distribution
normInds = strcmp(Dist, 'norm'); 
normInds = normInds(useParam); 
%%

param_candidate_old = tmp(useParam);
tune_param = obj.MCMCTuningParam; % percent of interval

P = param_candidate_old;
if any(P<LB | P>UB)
    warning('Initial parameter P0_1 outside search interval. Resetting to boundary.')
end

% quick fix to include normal distribution 
%Preallocate the normally distributed random number:
my_randn = randn(obj.MaxNumSimulations, length(P)); 

 % keep only the unique groups in the acceptance criteria that are also
 % identified with items
isMapped = ismember(arrayfun(@num2str, unqGroups, 'UniformOutput', false), {obj.Item.GroupID});
unqGroups = unqGroups(isMapped);

% check that the tasks are assigned only to one group
nMappings = arrayfun( @(g) nnz(strcmp(g, num2str(unqGroups))), {obj.Item.GroupID});
if any(nMappings>1)
    StatusOK = false;
    Message = sprintf('%s\nOnly one task may be assigned to any group. Check task group mappings.\n', Message);
    delete(hWbar)
    return
end

% check that the groups specified in the IC file are assigned to tasks
for currGrp = unqGroups
    if ~any(groupVec==currGrp)
        StatusOK = false;
        Message = sprintf('%sInitial conditions file specified contains groups for which no task has been assigned.\n', Message);
        delete(hWbar)
        return
    end
end


p = gcp('nocreate');
if isempty(p) 
    p = parpool(obj.Session.ParallelCluster, ...
        'AttachedFiles', obj.Session.UserDefinedFunctionsDirectory);
elseif  ~strcmp(p.Cluster.Profile,obj.Session.ParallelCluster)
    delete(gcp('nocreate'))
    p = parpool(obj.Session.ParallelCluster, ...
     'AttachedFiles', obj.Session.UserDefinedFunctionsDirectory);
end
% p.,);
% nPat = Composite();
% nSim = Composite();

% for k=1:p.NumWorkers
%     nPat{k} = 0;
%     nSim{k} = 0;
% end

% allSim = 0;
% allPat = 0;

% q = parallel.pool.DataQueue;
q_vp = parallel.pool.DataQueue;

% afterEach(q, @(data) updateWaitBar(hWbar, q_vp, data));

listener = afterEach(q_vp, @(data) updateData(hWbar, data) );
vPop_all = [];
isValid_all = [];
bCancelled = false;
allPat = 0;
allSim = 0;

F = parfevalOnAll(p, @whileBlock, 2);
fprintf('waiting...\n')
wait(F)
fprintf('Generated %d vpatients (%d valid)\n', size(vPop_all,1), nnz(isValid_all))


function updateData(hWbar, data)
    allPat = allPat + data(end); % 0 or 1
    allSim = allSim + 1;
    
    vPop_all = [vPop_all; data(1:end-1)];
    isValid_all = [isValid_all; data(end)];
    
    if ~isempty(hWbar)
        thisStatusOK = uix.utility.CustomWaitbar(allPat/obj.MaxNumVirtualPatients,hWbar,sprintf('Succesfully generated %d/%d vpatients. (%d/%d Failed)',  ...
            allPat, obj.MaxNumVirtualPatients, allSim-allPat, allSim ));
        if ~thisStatusOK
            cancel(F);
            bCancelled = true;
        end
    end
    
    if allPat > obj.MaxNumVirtualPatients || allSim  > obj.MaxNumSimulations
        cancel(F);
        delete(listener)
    end
    
end

% 
% function updateWaitBar(hWbar, q_vp, data)
%     
%     allPat = data(1);
%     allSim = data(2);
%     
%     
% end
% 

Names0 = {};

function [Vpop, isValid] = whileBlock()
    
nPat = 0;
nSim = 0;

while nSim < obj.MaxNumSimulations && nPat < obj.MaxNumVirtualPatients 
                        
    nSim = nSim+1; % tic up the number of simulations
    
    if strcmp(obj.Method, 'Distribution')
        % produce sample uniformly sampled between LB & UB

        param_candidate = unifrnd(LB,UB);
        param_candidate_norm = P0_1 + CV.*P0_1.*my_randn(nSim,:)'; %MES edit 2/13
        param_candidate(normInds) = param_candidate_norm(normInds); %MES edit 2/13 

    elseif strcmp(obj.Method, 'MCMC')

        param_candidate = param_candidate_old + (UB-LB).*(2*rand(size(LB))-1)*tune_param;
        param_candidate_norm = param_candidate_old + CV.*my_randn(nSim,:)'*tune_param;
        param_candidate(normInds) = param_candidate_norm(normInds); %MES edit 2/13 
        
    end
    
    param_candidate = max(param_candidate, LB); param_candidate = min(param_candidate, UB);
    P = param_candidate;
    
    P(logInds) = 10.^P(logInds);
    Values0 = [P; fixedParams];
    Names0 = [perturbParamNames; fixedParamNames];
    
    
    % generate a long vector of model outputs to compare to the acceptance
    % criteria
    spec_outputs = [];
    time_outputs = [];
    LB_outputs = [];
    UB_outputs = [];
    taskName_outputs = [];
    model_outputs = [];
    LB_violation = [];
    UB_violation = [];   
    
    % loop over unique groups in the acceptance criteria file
    for grpIdx = 1:length(unqGroups) %nItems
        currGrp = unqGroups(grpIdx);
        
        % get matching taskGroup item based on group ID        
        itemIdx = strcmp({obj.Item.GroupID}, num2str(currGrp));
        if ~any(itemIdx)
            % this group is not part of this vpop generation
            continue
        end
        

        
        % get task object for this item based on name
        tskInd = strcmp(obj.Item(itemIdx).TaskName,{obj.Settings.Task.Name});
        taskObj = obj.Settings.Task(tskInd);
        
        % indices of data points in acc. crit. matching this group
        grpInds = find(Groups == currGrp);
        
        % get group information
        Species_grp = Species(grpInds);
        Time_grp = Time(grpInds);
        LB_grp = LB_accCrit(grpInds);
        UB_grp = UB_accCrit(grpInds);
        
        % change output times for the exported model
        OutputTimes = sort(unique(Time_grp));
        
        % set the initial conditions to the value in the IC file if specified
        if ~isempty(ICTable)
            ICs = ICTable.data(groupVec==currGrp, ixSpecies );
            IC_species = ICTable.colheaders(ixSpecies);
            nIC = size(ICs,1);
        else
            nIC = 1;
            ICs = [];
            IC_species = {};
        end
        
        % loop over initial conditions for this group
        for ixIC = 1:nIC
            if ~isempty(IC_species)
                Names = [Names0; IC_species'];  
                Values = [Values0; ICs(ixIC,:)'];
            else
                Names = Names0;
                Values = Values0;
            end


            % simulate
            try
                simData  = taskObj.simulate(...
                    'Names', Names, ...
                    'Values', Values, ...
                    'OutputTimes', OutputTimes);

                % for each species in this grp acc crit, find the corresponding
                % model output, grab relevant time points, compare
                uniqueSpecies_grp = unique(Species_grp);
                for spec = 1:length(uniqueSpecies_grp)
                    % find the data species in the Species-Data mapping
                    specInd = strcmp(uniqueSpecies_grp(spec),Mappings(:,2));


                    % grab data for the corresponding model species from the simulation results
                    [simT,simData_spec,specName] = selectbyname(simData,Mappings(specInd,1));

                    try
                        % transform the model outputs to match the data
                        simData_spec = obj.SpeciesData(specInd).evaluate(simData_spec);
                    catch ME
%                         StatusOK = false;
                        ThisMessage = sprintf(['There is an error in one of the function expressions in the SpeciesData mapping.'...
                            'Validate that all mappings have been specified for each unique species in dataset. %s'], ME.message);
                        Message = sprintf('%s\n%s\n',Message,ThisMessage);
                        path(myPath);                        
                        break                    
                    end % try

                    % grab all acceptance criteria time points for this species in this group
                    ix_grp_spec = strcmp(uniqueSpecies_grp(spec),Species_grp);
                    Time_grp_spec = Time_grp(ix_grp_spec);
                    LB_grp_spec = LB_grp(ix_grp_spec);
                    UB_grp_spec = UB_grp(ix_grp_spec);

                    % select simulation time points for which there are acceptance criteria
                    [bSim,okInds] = ismember(simT,Time_grp_spec);
                    simData_spec = simData_spec(bSim);
                    LB_grp_spec = LB_grp_spec(okInds(bSim));
                    UB_grp_spec = UB_grp_spec(okInds(bSim));
                    Time_grp_spec = Time_grp_spec(okInds(bSim));

                    % save model outputs
                    model_outputs = [model_outputs;simData_spec];
                    time_outputs = [time_outputs;Time_grp_spec];
                    spec_outputs = [spec_outputs;repmat(specName,size(simData_spec))];
                    taskName_outputs = [taskName_outputs;repmat({taskObj.Name},size(simData_spec))];

                    LB_outputs = [LB_outputs; LB_grp_spec];
                    UB_outputs = [UB_outputs; UB_grp_spec];

                end % for spec
            catch ME2
                % if the simulation fails, replace model outputs with Inf so
                % that the parameter set fails the acceptance criteria
                model_outputs = [model_outputs;Inf*ones(length(grpInds),1)];
                LB_outputs = [LB_outputs;NaN(length(grpInds),1)];            
                UB_outputs = [UB_outputs;NaN(length(grpInds),1)];
            end
        end % for ixIC
        
    end % for grp

    % at this point, model_outputs should be the same length as the vectors
    % LB_accCrit and UB_accCrit
    
    % compare model outputs to acceptance criteria
    if ~isempty(model_outputs) 
        Vpop(nSim,:) = Values0'; % store the parameter set
        isValid(nSim) = double(all(model_outputs>=LB_outputs) && all(model_outputs<=UB_outputs));
        if isValid(nSim)
            nPat = nPat+1; % if conditions are satisfied, tick up the number of virutal patients
            param_candidate_old = param_candidate; % keep new candidate as starting point
            fprintf('.')
        end
        
        
        send(q_vp, [Values0', isValid(nSim)]);
        
%         LB_violation = [LB_violation; find(model_outputs<LB_outputs)];
%         UB_violation = [UB_violation; find(model_outputs>UB_outputs)];
        
    end      
%     LBTable = table(taskName_outputs(LB_violation), ...
%         spec_outputs(LB_violation), ...
%         num2cell(time_outputs(LB_violation)),...
%         repmat({'LB'},size(LB_violation)), ...
%         'VariableNames', {'Task','Species','Time','Type'});
%     UBTable = table(taskName_outputs(UB_violation), ...
%         spec_outputs(UB_violation), ...
%         num2cell(time_outputs(UB_violation)),...
%         repmat({'UB'},size(UB_violation)), ...
%         'VariableNames', {'Task','Species','Time','Type'});
%     ViolationTable = [ViolationTable; LBTable; UBTable];
    
    
    % update wait bar
%     send(q, [gplus(nPat), gplus(nSim)])
%     if ~isvalid(hWbar)
%         running = false;
%     end
end % while

isValid = isValid(1:nSim);
Vpop = Vpop(1:nSim,:);

end

% 
% % in case nPat is less than the maximum number of virtual patients...
% % Vpop = Vpop(isValid==1,:); % removes extra zeros in Vpop
% 
% 
% %% DEBUG: output all the violations of the constraints
% if ~isempty(ViolationTable)
%     ViolationTable = vertcat(ViolationTable{:});
%     g = findgroups(ViolationTable.Task, ViolationTable.Species, cell2mat(ViolationTable.Time), ViolationTable.Type);
%     ViolationSums = splitapply(@length, ViolationTable.Type, g);
%     [~,ix] = unique(g);
%     ViolationSumsTable = [ViolationTable(ix,:), table(ViolationSums, 'VariableNames', {'Count'})];
%     disp(ViolationSumsTable)
% end
%% Outputs

% nSim = sum([nSim{:}]);
% nPat = sum([nPat{:}]);
% 
% isValid = vertcat(isValid{:});
% Vpop = vertcat(Vpop{:});

delete(hWbar)

isValid = isValid_all;
Vpop = vPop_all;

if nnz(isValid) > obj.MaxNumVirtualPatients
    % in case parallel went past last vpatient
    ixLast = find(cumsum(isValid)==obj.MaxNumVirtualPatients,1,'first');
    isValid = isValid(1:ixLast);
    Vpop = Vpop(1:ixLast,:);
end

nSim = size(Vpop,1);
nPat = nnz(isValid);

ThisMessage = [num2str(nPat) ' virtual patients generated in ' num2str(nSim) ' simulations.'];
Message = sprintf('%s\n%s\n',Message,ThisMessage);


bProceed = true;

if nPat == 0
    bProceed = questdlg('No valid virtual patients generated. Save virtual cohort?', 'Save virtual cohort?', 'No');
    if strcmp(bProceed,'Yes')
        StatusOK = true;
        bProceed = true;   %MES 2/22- added this to allow save vpop if statement to work
    else
        StatusOK = false;
        ThisMessage = 'No virtual patients generated.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        bProceed = false;  %MES 2/22- added this to allow save vpop if statement to work
    end
elseif bCancelled
    bProceed = questdlg('Cohort generation cancelled. Save virtual cohort?', 'Save virtual cohort?', 'No');
    StatusOK = true;
    if strcmp(bProceed,'Yes')      
        bProceed = true;
    else
        bProceed = false;
        StatusOK = false;
    end
end

% StatusOK = all([StatusOK{:}]);

if StatusOK && bProceed
    hWbar = uix.utility.CustomWaitbar(0,'Saving virtual cohort','Saving virtual cohort...',true);

    SaveFlag = true;
    % add prevalence weight
%     VpopHeader = [perturbParamNames; 'PWeight']';
    Names0 = [perturbParamNames; fixedParamNames];

    VpopHeader = [Names0; 'PWeight']';

   if strcmp(obj.SaveInvalid, 'Save valid vpatients')
        % filter out invalids
        Vpop = Vpop(isValid==1,:);
        isValid = true(size(Vpop,1),1);
   end    
    
    % replicate the vpops if multiple initial conditions were specified
    if nnz(isValid)>0
        PW = num2cell(isValid/nnz(isValid));
    else
        PW = num2cell(isValid);
    end
    
    VpopData = [num2cell(Vpop), PW];
    if ~isempty(ICTable)
        [bSpeciesData,idxSpeciesData] = ismember( ICTable.colheaders, obj.PlotSpeciesTable(:,4));
        ICTableHeaders = ICTable.colheaders;
        ICTableHeaders(bSpeciesData) = obj.PlotSpeciesTable( idxSpeciesData(bSpeciesData>0), 3);
        
        Vpop=[ICTableHeaders, VpopHeader];
        for k=1:size(ICTable.data,1) % loop over initial conditions
            Vpop = [Vpop; [num2cell(repmat(ICTable.data(k,:), size(VpopData,1),1)), VpopData] ];
        end
    else
        Vpop = [VpopHeader; VpopData ];
    end
    obj.PrevalenceWeights = cell2mat(Vpop(2:end,end));     % save prevalence weight to object
    
    % save results
    SaveFilePath = fullfile(obj.Session.RootDirectory,obj.VPopResultsFolderName);
    if ~exist(SaveFilePath,'dir')
        [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
        if ~ThisStatusOk
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            SaveFlag = false;
        end
    end
    
%     obj.SimFlag = repmat(isValid, nIC, 1);
      
 
    
    if SaveFlag
        VpopName = ['Results - Cohort Generation = ' obj.Name ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS')];
        ResultsFileName = [VpopName '.xlsx'];
        if ispc
            try
                [ThisStatusOk,ThisMessage] = xlswrite(fullfile(SaveFilePath,ResultsFileName),Vpop);
            catch error
                fName = regexp(error.message, '(C:\\.*\.mat)', 'match');
                if length(fName{1}) > 260
                    ThisMessage = sprintf('%s\n* Windows cannot save filepaths longer than 260 characters. See %s for more details.\n', ...
                       ThisMessage, 'https://www.howtogeek.com/266621/how-to-make-windows-10-accept-file-paths-over-260-characters/' );
                end
            end
        else
            [ThisStatusOk,ThisMessage] = xlwrite(fullfile(SaveFilePath,ResultsFileName),Vpop);
        end
        if ~ThisStatusOk
            StatusOK = false;
            Message = sprintf('%s\n%s\n',Message,ThisMessage.message);
        end
    else
        StatusOK = false;
        ThisMessage = 'Could not save the output of virtual cohort generation.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
        
    delete(hWbar)
end

% restore path
path(myPath);
end

function [StatusOK,Message,ResultsFileName,VpopName] = cohortGenerationRunHelper_ser(obj)
% Function that generates a Virtual population by sampling parameter space,
% running simulations, and comparing the outputs to Acceptance Criteria.

StatusOK = true;
Message = '';
ResultsFileName = '';
VpopName = '';

%% update path to include everything in subdirectories of the root folder
myPath = path;
addpath(genpath(obj.Session.RootDirectory));

%% Check number of items
if numel(obj.Item) == 0
    StatusOK = false;
    Message = 'The number of items is 0.';
    path(myPath);
    return
end

%% Load Acceptance Criteria
Names = {obj.Settings.VirtualPopulationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

if any(MatchIdx)
    vpopObj = obj.Settings.VirtualPopulationData(MatchIdx);
    
    [ThisStatusOk,ThisMessage,accCritHeader,accCritData] = importData(vpopObj,vpopObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    accCritHeader = {};
    accCritData = {};
end

%% Prepare species-data Mappings
Mappings = cell(length(obj.SpeciesData),2);
for ii = 1:length(obj.SpeciesData)
    Mappings{ii,1} = obj.SpeciesData(ii).SpeciesName;
    Mappings{ii,2} = obj.SpeciesData(ii).DataName;
end


if ~isempty(accCritHeader) && ~isempty(accCritData)
    
    % filter out any acceptance criteria that are not included
    includeIdx = accCritData(:,strcmp('Include',accCritHeader));
    if ~isempty(includeIdx)
        param_candidate = strcmpi(includeIdx,'yes');
        accCritData = accCritData(param_candidate==1,:);
    end
    
    spIdx = ismember( accCritData(:,3), Mappings(:,2));
    % [Group, Species, Time, LB, UB]
    Groups = cell2mat(accCritData(spIdx,strcmp('Group',accCritHeader)));
    unqGroups = unique(Groups);
    Time = cell2mat(accCritData(spIdx,strcmp('Time',accCritHeader)));
    Species = accCritData(spIdx,strcmp('Data',accCritHeader));
    LB_accCrit = cell2mat(accCritData(spIdx,strcmp('LB',accCritHeader)));
    UB_accCrit = cell2mat(accCritData(spIdx,strcmp('UB',accCritHeader)));
else
    
    StatusOK = false;
    Message = 'The selected Acceptance Criteria file is empty.';
    path(myPath);
    return
end



%% Load Parameters
Names = {obj.Settings.Parameters.Name};
MatchIdx = strcmpi(Names,obj.RefParamName);
if any(MatchIdx)
    pObj = obj.Settings.Parameters(MatchIdx);
    [ThisStatusOk,ThisMessage,paramHeader,paramData] = importData(pObj,pObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    paramHeader = {};
    paramData = {};
end

if ~isempty(paramHeader) && ~isempty(paramData)
    % [Include, Name, Scale, LB, UB, P0_1, ...]
    % filter missing LB/UB
    ixValid = (~isnan(cell2mat(paramData(:,strcmp('LB',paramHeader)))) & ~isnan(cell2mat(paramData(:,strcmp('UB',paramHeader))))) | ...
        ~isnan(cell2mat(paramData(:,strcmp('P0_1',paramHeader))));
    paramData = paramData(ixValid,:);
    
    paramNames = paramData(:,strcmp('Name',paramHeader));
    Scale = paramData(:,strcmp('Scale',paramHeader));
    
    LB_params = cell2mat(paramData(:,strcmp('LB',paramHeader)));
    UB_params = cell2mat(paramData(:,strcmp('UB',paramHeader)));
    
    if isempty(find(strcmpi('Dist',paramHeader)==1)) == 0
        Dist = paramData(:,strcmpi('Dist',paramHeader));
    else 
        Dist = cell(length(LB_params),1); 
        Dist(:) = {'uniform'}; %If empty, uniform distribution 
    end
    if isempty(find(strcmpi('CV',paramHeader)==1)) == 0
        CV_params = cell2mat(paramData(:,strcmpi('CV',paramHeader))); %MES add 2/14/2019
    else
        CV_params = zeros(length(LB_params),1); 
    end
    
    useParam = paramData(:,strcmpi('Include',paramHeader));
    p0 = cell2mat(paramData(:,strcmpi('P0_1',paramHeader))); % MES edit to search header instead of column number 
    if isempty(useParam)
        useParam = repmat('yes',size(paramNames));
    end
    
    useParam = strcmpi(useParam,'yes');
    perturbParamNames = paramNames(useParam);
    fixedParamNames = paramNames(~useParam);
    logInds = strcmp(Scale, 'log');
    
    LB = LB_params(useParam);
    UB = UB_params(useParam);
    CV = CV_params(useParam);
    P0_1 = p0(useParam);
    
    if any(isnan(LB) | isnan(UB))
        StatusOK = false;
        Message = 'At least one optimization parameter is missing a lower/upper bound. Check parameter file';
        path(myPath);
        return
    end
    
    logInds = logInds(useParam);
    
    LB(logInds) = log10(LB(logInds));
    UB(logInds) = log10(UB(logInds));
    fixedParams = p0(~useParam);
else
    %     LB_params = [];
    %     UB_params = [];
    StatusOK = false;
    Message = 'The selected Parameter file is empty.';
    path(myPath);
    return
end


%% Deal with initial conditions file if it is specified and exists

if ~isempty(obj.ICFileName) && ~strcmp(obj.ICFileName,'N/A') && exist(obj.ICFileName, 'file')
 % get names from the IC file
    ICTable = importdata(obj.ICFileName);
  % validate the column names
    [hasGroupCol, groupCol] = ismember('Group', ICTable.colheaders);
    if ~hasGroupCol
        StatusOK = false;
        ThisMessage = 'Initial conditions file does not contain Group column';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        return
    end
    
    % check that we are not specifying an initial condition for a species
    % that is also being sampled
    [~,ixConflictingParameters] = ismember( ICTable.colheaders, perturbParamNames);
    if any(ixConflictingParameters)
        StatusOK = false;
        Message = sprintf(['%s\nInitial conditions file contains species that are sampled in the cohort generation.  '...
            'To continue set Include=No for %s or remove them from the parameters file.\n'], ...
            Message, strjoin(perturbParamNames(ixConflictingParameters(ixConflictingParameters>0)), ','));
    end
else 
    ICTable = [];
end



%% For each task/group, load models and prepare for simulations

nItems = length(obj.Item);

obj.SimResults = {}; %cell(1,nItems);

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
    
    ItemModels.Task(ii) = tObj_i;
end % for

%% Sample parameter sets, simulate, compare to acceptance criteria
nSim = 0;
nPat = 0;
Vpop = zeros(obj.MaxNumSimulations,length(LB_params));
isValid = zeros(obj.MaxNumSimulations,1);

% set up the loop for different initial conditions
if isempty(ICTable )
    % no initial conditions specified
    groupVec = 1:length(nItems);
else
    % initial conditions exist
    groupVec = ICTable.data(:,groupCol);
    ixSpecies = setdiff(1:numel(ICTable.colheaders), groupCol); % columns of species in IC table
end

%% loop over the candidates until enough are generated
hWbar = uix.utility.CustomWaitbar(0,'Virtual cohort generation','Generating virtual cohort...',true);


ViolationTable = [];
% param_candidate = LB + (UB-LB).*rand(size(LB)); % initial candidate
tmp = p0;
logInds = strcmp(Scale, 'log');

tmp(logInds) = log10(tmp(logInds));
logInds = logInds(useParam);

%% MES 2/13: indicate the indices that require normal distribution
normInds = strcmp(Dist, 'norm'); 
normInds = normInds(useParam); 
%%

param_candidate_old = tmp(useParam);
tune_param = obj.MCMCTuningParam; % percent of interval

P = param_candidate_old;
if any(P<LB | P>UB)
    warning('Initial parameter P0_1 outside search interval. Resetting to boundary.')
end

bCancelled = false;

% quick fix to include normal distribution 
%Preallocate the normally distributed random number:
my_randn = randn(obj.MaxNumSimulations, length(P)); 

while nSim<obj.MaxNumSimulations && nPat<obj.MaxNumVirtualPatients
    nSim = nSim+1; % tic up the number of simulations
    
    if strcmp(obj.Method, 'Distribution')
        % produce sample uniformly sampled between LB & UB

        param_candidate = unifrnd(LB,UB);
        param_candidate_norm = P0_1 + CV.*P0_1.*my_randn(nSim,:)'; %MES edit 2/13
        param_candidate(normInds) = param_candidate_norm(normInds); %MES edit 2/13 

    elseif strcmp(obj.Method, 'MCMC')

        param_candidate = param_candidate_old + (UB-LB).*(2*rand(size(LB))-1)*tune_param;
        param_candidate_norm = param_candidate_old + CV.*my_randn(nSim,:)'*tune_param;
        param_candidate(normInds) = param_candidate_norm(normInds); %MES edit 2/13 
        
    end
    
    param_candidate = max(param_candidate, LB); param_candidate = min(param_candidate, UB);
    P = param_candidate;
    
    P(logInds) = 10.^P(logInds);
    Values0 = [P; fixedParams];
    Names0 = [perturbParamNames; fixedParamNames];
    
    
    % generate a long vector of model outputs to compare to the acceptance
    % criteria
    spec_outputs = [];
    time_outputs = [];
    LB_outputs = [];
    UB_outputs = [];
    taskName_outputs = [];
    model_outputs = [];
    LB_violation = [];
    UB_violation = [];   
    
    % loop over unique groups in the acceptance criteria file
    for grpIdx = 1:length(unqGroups) %nItems
        currGrp = unqGroups(grpIdx);
        
        % get matching taskGroup item based on group ID        
        itemIdx = strcmp({obj.Item.GroupID}, num2str(currGrp));
        if ~any(itemIdx)
            % this group is not part of this vpop generation
            continue
        end
        
        if nnz(itemIdx) > 1
            StatusOK = false;
            Message = sprintf('%s\nOnly one task may be assigned to any group. Check task group mappings.\n', Message);
            delete(hWbar)
            return
        end
        
        % get task object for this item based on name
        tskInd = strcmp(obj.Item(itemIdx).TaskName,{obj.Settings.Task.Name});
        taskObj = obj.Settings.Task(tskInd);
        
        % indices of data points in acc. crit. matching this group
        grpInds = find(Groups == currGrp);
        
        % get group information
        Species_grp = Species(grpInds);
        Time_grp = Time(grpInds);
        LB_grp = LB_accCrit(grpInds);
        UB_grp = UB_accCrit(grpInds);
        
        % change output times for the exported model
        OutputTimes = sort(unique(Time_grp));
        
        % set the initial conditions to the value in the IC file if specified
        if ~isempty(ICTable)
            ICs = ICTable.data(groupVec==currGrp, ixSpecies );
            IC_species = ICTable.colheaders(ixSpecies);
            nIC = size(ICs,1);
            if ~any(groupVec==currGrp)
                StatusOK = false;
                Message = sprintf('%sInitial conditions file specified contains groups for which no task has been assigned.\n', Message);
                delete(hWbar)
                return
            end
            
        else
            nIC = 1;
            ICs = [];
            IC_species = {};
        end
        
        % loop over initial conditions for this group
        for ixIC = 1:nIC
            if ~isempty(IC_species)
                Names = [Names0; IC_species'];  
                Values = [Values0; ICs(ixIC,:)'];
            else
                Names = Names0;
                Values = Values0;
            end


            % simulate
            try
                simData  = taskObj.simulate(...
                    'Names', Names, ...
                    'Values', Values, ...
                    'OutputTimes', OutputTimes);

                % for each species in this grp acc crit, find the corresponding
                % model output, grab relevant time points, compare
                uniqueSpecies_grp = unique(Species_grp);
                for spec = 1:length(uniqueSpecies_grp)
                    % find the data species in the Species-Data mapping
                    specInd = strcmp(uniqueSpecies_grp(spec),Mappings(:,2));
                    
                    if nnz(specInd) ~= 1
                        StatusOK = false;
                        Message = sprintf('%s\nOnly one species may be assigned to any given data set. Please check mappings for validity.\n', Message);
                        delete(hWbar)
                        return
                    end

                    % grab data for the corresponding model species from the simulation results
                    [simT,simData_spec,specName] = selectbyname(simData,Mappings(specInd,1));

                    try
                        % transform the model outputs to match the data
                        simData_spec = obj.SpeciesData(specInd).evaluate(simData_spec);
                    catch ME
                        StatusOK = false;
                        ThisMessage = sprintf(['There is an error in one of the function expressions in the SpeciesData mapping.'...
                            'Validate that all mappings have been specified for each unique species in dataset. %s'], ME.message);
                        Message = sprintf('%s\n%s\n',Message,ThisMessage);
                        path(myPath);
                        return                    
                    end % try

                    % grab all acceptance criteria time points for this species in this group
                    ix_grp_spec = strcmp(uniqueSpecies_grp(spec),Species_grp);
                    Time_grp_spec = Time_grp(ix_grp_spec);
                    LB_grp_spec = LB_grp(ix_grp_spec);
                    UB_grp_spec = UB_grp(ix_grp_spec);

                    % select simulation time points for which there are acceptance criteria
                    [bSim,okInds] = ismember(simT,Time_grp_spec);
                    simData_spec = simData_spec(bSim);
                    LB_grp_spec = LB_grp_spec(okInds(bSim));
                    UB_grp_spec = UB_grp_spec(okInds(bSim));
                    Time_grp_spec = Time_grp_spec(okInds(bSim));

                    % save model outputs
                    model_outputs = [model_outputs;simData_spec];
                    time_outputs = [time_outputs;Time_grp_spec];
                    spec_outputs = [spec_outputs;repmat(specName,size(simData_spec))];
                    taskName_outputs = [taskName_outputs;repmat({taskObj.Name},size(simData_spec))];

                    LB_outputs = [LB_outputs; LB_grp_spec];
                    UB_outputs = [UB_outputs; UB_grp_spec];

                end % for spec
            catch ME2
                % if the simulation fails, replace model outputs with Inf so
                % that the parameter set fails the acceptance criteria
                model_outputs = [model_outputs;Inf*ones(length(grpInds),1)];
                LB_outputs = [LB_outputs;NaN(length(grpInds),1)];            
                UB_outputs = [UB_outputs;NaN(length(grpInds),1)];
            end
        end % for ixIC
        
    end % for grp
    if ~StatusOK % exit loop if something went wrong
        break
    end
    % at this point, model_outputs should be the same length as the vectors
    % LB_accCrit and UB_accCrit
    
    % compare model outputs to acceptance criteria
    if ~isempty(model_outputs) 
        Vpop(nSim,:) = Values0'; % store the parameter set
        isValid(nSim) = double(all(model_outputs>=LB_outputs) && all(model_outputs<=UB_outputs));
        if isValid(nSim)
            nPat = nPat+1; % if conditions are satisfied, tick up the number of virutal patients
            param_candidate_old = param_candidate; % keep new candidate as starting point
        end
        
        waitStatus = uix.utility.CustomWaitbar(nPat/obj.MaxNumVirtualPatients,hWbar,sprintf('Succesfully generated %d/%d vpatients. (%d/%d Failed)',  ...
            nPat, obj.MaxNumVirtualPatients, nSim-nPat, nSim ));
        
        LB_violation = [LB_violation; find(model_outputs<LB_outputs)];
        UB_violation = [UB_violation; find(model_outputs>UB_outputs)];
        if ~waitStatus
            bCancelled = true;
            break
        end
    end      
    LBTable = table(taskName_outputs(LB_violation), ...
        spec_outputs(LB_violation), ...
        num2cell(time_outputs(LB_violation)),...
        repmat({'LB'},size(LB_violation)), ...
        'VariableNames', {'Task','Species','Time','Type'});
    UBTable = table(taskName_outputs(UB_violation), ...
        spec_outputs(UB_violation), ...
        num2cell(time_outputs(UB_violation)),...
        repmat({'UB'},size(UB_violation)), ...
        'VariableNames', {'Task','Species','Time','Type'});
    ViolationTable = [ViolationTable; LBTable; UBTable];
end % while
if ~isempty(hWbar) && ishandle(hWbar)
    delete(hWbar)
end
% in case nPat is less than the maximum number of virtual patients...
% Vpop = Vpop(isValid==1,:); % removes extra zeros in Vpop


%% DEBUG: output all the violations of the constraints
if ~isempty(ViolationTable)
    g = findgroups(ViolationTable.Task, ViolationTable.Species, cell2mat(ViolationTable.Time), ViolationTable.Type);
    ViolationSums = splitapply(@length, ViolationTable.Type, g);
    [~,ix] = unique(g);
    ViolationSumsTable = [ViolationTable(ix,:), table(ViolationSums, 'VariableNames', {'Count'})];
    disp(ViolationSumsTable)
end
%% Outputs

ThisMessage = [num2str(nPat) ' virtual patients generated in ' num2str(nSim) ' simulations.'];
Message = sprintf('%s\n%s\n',Message,ThisMessage);

isValid = isValid(1:nSim);
Vpop = Vpop(1:nSim,:);
bProceed = true;

if nPat == 0
    bProceed = questdlg('No valid virtual patients generated. Save virtual cohort?', 'Save virtual cohort?', 'No');
    if strcmp(bProceed,'Yes')
        StatusOK = true;
        bProceed = true;   %MES 2/22- added this to allow save vpop if statement to work
    else
        StatusOK = false;
        ThisMessage = 'No virtual patients generated.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        bProceed = false;  %MES 2/22- added this to allow save vpop if statement to work
    end
elseif bCancelled
    bProceed = questdlg('Cohort generation cancelled. Save virtual cohort?', 'Save virtual cohort?', 'No');
    if strcmp(bProceed,'Yes')      
        bProceed = true;
    else
        bProceed = false;
        StatusOK = false;
    end
end

if StatusOK && bProceed
    hWbar = uix.utility.CustomWaitbar(0,'Saving virtual cohort','Saving virtual cohort...',true);

    SaveFlag = true;
    % add prevalence weight
%     VpopHeader = [perturbParamNames; 'PWeight']';
    VpopHeader = [Names0; 'PWeight']';

   if strcmp(obj.SaveInvalid, 'Save valid vpatients')
        % filter out invalids
        Vpop = Vpop(isValid==1,:);
        isValid = true(size(Vpop,1),1);
   end    
    
    % replicate the vpops if multiple initial conditions were specified
    VpopData = [num2cell(Vpop), num2cell(isValid/nnz(isValid))];
    if ~isempty(ICTable)
        [bSpeciesData,idxSpeciesData] = ismember( ICTable.colheaders, obj.PlotSpeciesTable(:,4));
        ICTableHeaders = ICTable.colheaders;
        ICTableHeaders(bSpeciesData) = obj.PlotSpeciesTable( idxSpeciesData(bSpeciesData>0), 3);
        
        Vpop=[ICTableHeaders, VpopHeader];
        for k=1:size(ICTable.data,1) % loop over initial conditions
            Vpop = [Vpop; [num2cell(repmat(ICTable.data(k,:), size(VpopData,1),1)), VpopData] ];
        end
    else
        Vpop = [VpopHeader; VpopData ];
    end
    obj.PrevalenceWeights = cell2mat(Vpop(2:end,end));     % save prevalence weight to object
    
    % save results
    SaveFilePath = fullfile(obj.Session.RootDirectory,obj.VPopResultsFolderName);
    if ~exist(SaveFilePath,'dir')
        [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
        if ~ThisStatusOk
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            SaveFlag = false;
        end
    end
    
    obj.SimFlag = repmat(isValid, nIC, 1);
      
 
    
    if SaveFlag
        VpopName = ['Results - Cohort Generation = ' obj.Name ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS')];
        ResultsFileName = [VpopName '.xlsx'];
        if ispc
            [ThisStatusOk,ThisMessage] = xlswrite(fullfile(SaveFilePath,ResultsFileName),Vpop);
        else
            [ThisStatusOk,ThisMessage] = xlwrite(fullfile(SaveFilePath,ResultsFileName),Vpop);
        end
        if ~ThisStatusOk
            StatusOK = false;
            Message = sprintf('%s\n%s\n',Message,ThisMessage.message);
        end
    else
        StatusOK = false;
        ThisMessage = 'Could not save the output of virtual cohort generation.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
        
    delete(hWbar)
end

% restore path
path(myPath);

end


