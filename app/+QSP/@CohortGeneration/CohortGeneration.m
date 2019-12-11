classdef CohortGeneration < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % CohortGeneration - Defines a CohortGeneration object
    % ---------------------------------------------------------------------
    % Abstract: This object defines CohortGeneration
    %
    % Syntax:
    %           obj = QSP.CohortGeneration
    %           obj = QSP.CohortGeneration('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.CohortGeneration Properties:
    %
    %
    % QSP.CohortGeneration Methods:
    %
    %
    %
    
    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $  $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        Settings = QSP.Settings.empty(0,1)
        VPopResultsFolderName = 'CohortGenerationResults' 
        ICFileName = ''
        ExcelResultFileName = ''
        VPopName = '' % VPop name from running vpop gen
              
        DatasetName = '' % VirtualPopulationData Name
        RefParamName = '' % Parameters.Name
        GroupName = ''
        Method = 'Distribution' 
        SaveInvalid = 'Save all virtual subjects'
        
        
        Item = QSP.TaskGroup.empty(0,1)
        SpeciesData = QSP.SpeciesData.empty(0,1)
        
        MaxNumSimulations = 5000
        MaxNumVirtualPatients = 500
        MCMCTuningParam = 0.15
       
        FixRNGSeed = false
        RNGSeed = 100
        
        PlotSpeciesTable = cell(0,5)
        PlotItemTable = cell(0,5) 
        
        PrevalenceWeights = [];
        
        PlotType = 'Normal'
        
        SelectedPlotLayout = '1x1'   
        
        ShowInvalidVirtualPatients = true
        
        PlotSettings = repmat(struct(),1,12)
    end
    
    properties (SetAccess = 'private')
        SpeciesLineStyles
    end
    
    %% Constant Properties
    properties (Constant=true)
        ValidPlotTypes = {
            'Normal'
            'Diagnostic'
            }
    end
    
    %% Transient Properties
    properties (Transient=true)
        SimResults = {} % cached simulation results
        SimFlag = [] % valid/invalid flag for simulation
    end
    
    
    %% Constructor
    methods
        function obj = CohortGeneration(varargin)
            % CohortGeneration - Constructor for QSP.CohortGeneration
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.CohortGeneration object.
            %
            % Syntax:
            %           obj = QSP.CohortGeneration('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.CohortGeneration object
            %
            % Example:
            %    aObj = QSP.CohortGeneration();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % For compatibility
            if size(obj.PlotSpeciesTable,2) == 4
                obj.PlotSpeciesTable(:,5) = obj.PlotSpeciesTable(:,3);
            end
            
            % For compatibility
            if size(obj.PlotItemTable,2) == 4
                obj.PlotItemTable(:,5) = obj.PlotItemTable(:,3);
            end
            
            % assign plot settings names
            for index = 1:length(obj.PlotSettings)
                obj.PlotSettings(index).Title = sprintf('Plot %d', index);
            end            
            
        end %function obj = VirtualPopulationGeneration(varargin)
        
    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
           
            if ~isempty(obj.Item)
                VPopGenItems = {};
                % Check what items are stale or invalid
                [StaleFlag,ValidFlag,InvalidMessages] = getStaleItemIndices(obj);

                for index = 1:numel(obj.Item)

                    % Default
                    ThisItem = sprintf('%s - %s',obj.Item(index).TaskName,obj.Item(index).GroupID);
                    if StaleFlag(index)~=0

                        switch StaleFlag(index)
                            case 1
                                StaleMessage = 'Task has been modified';
                            case 2
                                StaleMessage = 'Task/Project has been modified';
                            case 3
                                StaleMessage = 'Acceptance criteria item has been modified';
                            case 4
                                StaleMessage = 'Acceptance criteria file has been modified';
                            case 5
                                StaleMessage = 'Parameters item has been modified';
                            case 6
                                StaleMessage = 'Parameters file has been modified';
                            case 7
                                StaleMessage = 'VPop result has been modified';
                        end
                                
                        % Item may be out of date
                        ThisItem = sprintf('***WARNING*** %s\n***Item may be out of date (%s)***\n',ThisItem,StaleMessage);
                    elseif ~ValidFlag(index)
                        % Display invalid
                        ThisItem = sprintf('***ERROR*** %s\n***%s***',ThisItem,InvalidMessages{index});
                    else
                        ThisItem = sprintf('%s',ThisItem);
                    end
                    % Append \n
                    if index < numel(obj.Item)
                        ThisItem = sprintf('%s\n',ThisItem);
                    end
                    VPopGenItems = [VPopGenItems; ThisItem]; %#ok<AGROW>
                end
            else
                VPopGenItems = {};
            end
            
            % Species-Data mapping
            if ~isempty(obj.SpeciesData)
                SpeciesDataItems = cellfun(@(x,y)sprintf('%s - %s',x,y),{obj.SpeciesData.SpeciesName},{obj.SpeciesData.DataName},'UniformOutput',false);
            else
                SpeciesDataItems = {};
            end
            
            % Get the parameter used            
            Names = {obj.Settings.Parameters.Name};
            MatchIdx = strcmpi(Names,obj.RefParamName);
            if any(MatchIdx)
                pObj = obj.Settings.Parameters(MatchIdx);
                [~,~,ParametersHeader,ParametersData] = importData(pObj,pObj.FilePath);                
            else
                ParametersHeader = {};
                ParametersData = {};
            end
            
            if ~isempty(ParametersHeader)
                MatchInclude = find(strcmpi(ParametersHeader,'Include'));
                MatchName = find(strcmpi(ParametersHeader,'Name'));
                if numel(MatchInclude) == 1 && numel(MatchName) == 1
                    IsUsed = strcmpi(ParametersData(:,MatchInclude),'yes');
                    UsedParamNames = ParametersData(IsUsed,MatchName);
                else
                    UsedParamNames = {};
                end
            else
                UsedParamNames = {};
            end
            
            if isempty(obj.ICFileName)
                obj.ICFileName = '';
            else
                obj.ICFileName = obj.ICFileName;
            end
            
            thisVpop = obj.Settings.getVpopWithName(obj.VPopName);
            if ~isempty(thisVpop)
                nValid = num2str(thisVpop.NumValidPatients);
                nInvalid = num2str(thisVpop.NumVirtualPatients - thisVpop.NumValidPatients);
            else
                nValid = 'N/A';
                nInvalid = 'N/A';
            end
            
            % random seed
            if obj.FixRNGSeed
                randomSeedStr = num2str(obj.RNGSeed);
            else
                randomSeedStr = 'not fixed';
            end
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTimeStr;
                'Description',obj.Description;
                'Results Path',obj.VPopResultsFolderName;
                'Dataset',obj.DatasetName;
                'Group Name',obj.GroupName;
                'Items',VPopGenItems;
                'Parameter File',obj.RefParamName;
                'Parameters Used for Cohort Generation',UsedParamNames;
                'Species-data Mapping',SpeciesDataItems;
                'Initial Conditions File',obj.ICFileName;
                'Max No of Simulations',num2str(obj.MaxNumSimulations);
                'Max No of Virtual Subjects',num2str(obj.MaxNumVirtualPatients);
                'Number of Valid Virtual Subjects', nValid; ...
                'Number of Invalid Virtual Subjects', nInvalid;...
                'Random Seed', randomSeedStr
                };
            
        end %function
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid)
            
            StatusOK = true;
            Message = sprintf('Virtual Population Generation: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            if  obj.Session.UseParallel && ~isempty(getCurrentTask())
                return
            end            
            
            % TODO: Validate that params in vpop exist in the file
            if ~isempty(obj.Settings)
                                
                % Check that Dataset (VirtualPopulationData) is valid if it exists
                if ~isempty(obj.Settings.VirtualPopulationData)
                    MatchIdx = find(strcmpi({obj.Settings.VirtualPopulationData.Name},obj.DatasetName));
                    if isempty(MatchIdx) || numel(MatchIdx) > 1
                        StatusOK = false;
                        Message = sprintf('%s\n* %s\n',Message,'Invalid dataset name specified for Optimization Data.');
                    else
                        [ThisStatusOK,ThisMessage] = validate(obj.Settings.VirtualPopulationData(MatchIdx),FlagRemoveInvalid);
                        if ~ThisStatusOK
                            StatusOK = false;
                            Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        end
                    end
                else
                    ThisMessage = 'No Acceptance Criteria specified';
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end                    
                
                % Check that RefParamName (Parameters) is valid if it exists
                if ~isempty(obj.Settings.Parameters)
                    MatchIdx = find(strcmpi({obj.Settings.Parameters.Name},obj.RefParamName));
                    if isempty(MatchIdx) || numel(MatchIdx) > 1
                        StatusOK = false;
                        Message = sprintf('%s\n* %s\n',Message,'Invalid reference parameter name specified for Parameters.');
                    else
                        [ThisStatusOK,ThisMessage] = validate(obj.Settings.Parameters(MatchIdx),FlagRemoveInvalid);
                        if ~ThisStatusOK
                            StatusOK = false;
                            Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        end
                    end
                else
                    ThisMessage = 'No Parameters specified';
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                
                
                % Import VirtualPopulationData
                if ~isempty(obj.Settings.VirtualPopulationData)
                    Names = {obj.Settings.VirtualPopulationData.Name};
                    MatchIdx = strcmpi(Names,obj.DatasetName);
                    
                    if any(MatchIdx)
                        vpopObj = obj.Settings.VirtualPopulationData(MatchIdx);
                        
                        [~,~,VPopHeader,VPopData] = importData(vpopObj,vpopObj.FilePath);
                    else
                        VPopHeader = {};
                    end
                else
                    VPopHeader = {};
                end
                
                % Get the group column and data column
                % GroupID
                if ~isempty(VPopHeader) && ~isempty(VPopData)
                    MatchIdx = find(strcmp(VPopHeader,obj.GroupName));
                    if numel(MatchIdx) == 1
                        GroupIDs = VPopData(:,MatchIdx);
                        if iscell(GroupIDs)
                            GroupIDs = cell2mat(GroupIDs);
                        end
                        GroupIDs = unique(GroupIDs);
                        GroupIDs = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
                    else
                        StatusOK = false;
                        ThisMessage = sprintf('Group name "%s" does not exist or exists multiple times within the header of the Excel file.',obj.GroupName);
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        GroupIDs = [];
                    end
                    
                    
                    MatchIdx = find(strcmp(VPopHeader,'Data'));
                    if numel(MatchIdx) == 1
                        DataValues = VPopData(:,MatchIdx);
                        DataValues = unique(DataValues);
                    else
                        StatusOK = false;
                        ThisMessage = sprintf('The column name "Data" does not exist or exists multiple times within the header of the Excel file.');
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        DataValues = {};
                    end
                else
                    GroupIDs = [];
                    DataValues = {};
                end
                
                
                %%% Remove the invalid task/group combos if any
                if all(isvalid(obj.Item))
                    [TaskItemIndex,MatchTaskIndex] = ismember({obj.Item.TaskName},{obj.Settings.Task.Name});
                    if ~isempty({obj.Item.GroupID}) && ~isempty(GroupIDs(:))
                        GroupItemIndex = ismember({obj.Item.GroupID},GroupIDs(:)');
                    else
                        GroupItemIndex = [];
                    end
                    RemoveIndices = ~TaskItemIndex | ~GroupItemIndex;
                    if any(RemoveIndices)
                        StatusOK = false;
                        ThisMessage = sprintf('Task-Group rows %s are invalid.',num2str(find(RemoveIndices)));
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    end
                else
                    RemoveIndices = 1:length(obj.Item);
                    MatchTaskIndex = [];
                end
                if FlagRemoveInvalid
                    obj.Item(RemoveIndices) = [];
                end

            % Check Tasks
                MatchTaskIndex(MatchTaskIndex == 0) = [];
                for index = MatchTaskIndex
                    [ThisStatusOK,ThisMessage] = validate(obj.Settings.Task(index),FlagRemoveInvalid);
                    if ~ThisStatusOK
                        StatusOK = false;
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    end
                end
                
                % Check GroupID
                if any(GroupItemIndex == 0)
                    BadValues = {obj.Item(GroupItemIndex == 0).GroupID};
                    ThisMessage = sprintf('Invalid group indices: %s',uix.utility.cellstr2dlmstr(BadValues,','));
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                
                % Get the species list
                ItemTaskNames = {obj.Item.TaskName};
                SpeciesList = getSpeciesFromValidSelectedTasks(obj.Settings,ItemTaskNames);
                
                %%% Remove the invalid species-data mapping                
                % Check Species
                SpeciesMappingIndex = ismember({obj.SpeciesData.SpeciesName},SpeciesList(:)');
                
                % Check Data
                DataMappingIndex = ismember({obj.SpeciesData.DataName},DataValues(:)');
                 
                % Check Species (Mapping)
                if any(SpeciesMappingIndex == 0)
                    BadValues = {obj.SpeciesData(SpeciesMappingIndex==0).SpeciesName};
                    ThisMessage = sprintf('Invalid species: %s',uix.utility.cellstr2dlmstr(BadValues,','));
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                                
                 % Check Data (Mapping)
                if any(DataMappingIndex == 0)
                    BadValues = {obj.SpeciesData(DataMappingIndex==0).DataName};
                    ThisMessage = sprintf('Invalid species: %s',uix.utility.cellstr2dlmstr(BadValues,','));
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                else
                    % Check that the function is only a function of x
                    tmp = cellfun(@symvar, {obj.SpeciesData.FunctionExpression}, 'UniformOutput', false);
                    ThisStatusOK = all(cellfun(@(x) length(x) == 1 && strcmp(x,'x'), tmp));
                    if ~ThisStatusOK
                        StatusOK = false;
                        ThisMessage = 'Data mappings must be a function of x only';
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    end
                end
                
                % Then, remove invalid
                RemoveIndices = ~SpeciesMappingIndex | ~DataMappingIndex;
                if any(RemoveIndices)
                    StatusOK = false;
                    ThisMessage = sprintf('Species-Data mapping rows %s are invalid.',num2str(find(RemoveIndices)));
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                if FlagRemoveInvalid
                    obj.SpeciesData(RemoveIndices) = [];
                end
                
                % remove any cached simulation results when an update has
                % taken place
                obj.SimResults = {}; % cached simulation results

                % VpopGeneration name forbidden characters
                if any(regexp(obj.Name,'[:*?/]'))
                    Message = sprintf('%s\n* Invalid vpop generation name.', Message);
                    StatusOK=false;
                end
                
            end %if
            
        end %function
           
        function clearData(obj)
            obj.SimResults = {};
            obj.SimFlag = [];
            obj.ExcelResultFileName = '';
            obj.VPopName = '';
        end
    end
    
    
    %% Methods    
    methods
        
        function [StatusOK,Message,vpopObj] = run(obj)
            
            % Invoke validate
            [StatusOK, Message] = validate(obj,false);
            
            % Invoke helper
            if StatusOK
                
                % For autosave with tag
                if obj.Session.AutoSaveBeforeRun
                    autoSaveFile(obj.Session,'Tag','preRunCohortGeneration');
                end
                
                % Run helper
                
                % set RNG if specified
                if obj.FixRNGSeed
                    rng(obj.RNGSeed)
                end
                
                % clear cached results if any
                obj.SimResults = {};
                obj.SimFlag = [];
                [StatusOK,Message,ResultsFileName,ThisVPopName] = cohortGenerationRunHelper(obj);
                % Update MATFileName in the simulation items
                obj.ExcelResultFileName = ResultsFileName;
                obj.VPopName = ThisVPopName;
                
                if StatusOK
                    % Create a new virtual population
                    vpopObj = QSP.VirtualPopulation;
                    vpopObj.Session = obj.Session;
                    vpopObj.Name = ThisVPopName;
                    vpopObj.FilePath = fullfile(obj.Session.RootDirectory,obj.VPopResultsFolderName,obj.ExcelResultFileName);
                    % Update last saved time
                    updateLastSavedTime(vpopObj);
                    % Validate
                    validate(vpopObj,false);
                else
                    vpopObj = QSP.VirtualPopulation.empty(0,1);
                end
            else
                vpopObj = QSP.VirtualPopulation.empty(0,1);
            end
            
        end %function
        
        function updateSpeciesLineStyles(obj)
            ThisMap = obj.Settings.LineStyleMap;
            if ~isempty(ThisMap) && size(obj.PlotSpeciesTable,1) ~= numel(obj.SpeciesLineStyles)
                obj.SpeciesLineStyles = uix.utility.GetLineStyleMap(ThisMap,size(obj.PlotSpeciesTable,1)); % Number of species
            end
        end %function
        
        function setSpeciesLineStyles(obj,Index,NewLineStyle)
            NewLineStyle = validatestring(NewLineStyle,obj.Settings.LineStyleMap);
            obj.SpeciesLineStyles{Index} = NewLineStyle;
        end %function
        
        function [StaleFlag,ValidFlag,InvalidMessages] = getStaleItemIndices(obj)
            
            StaleFlag = zeros(1,numel(obj.Item));
            ValidFlag = true(1,numel(obj.Item));
            InvalidMessages = cell(1,numel(obj.Item));
            
            % Check if VirtualPopulationData is valid
            ThisList = {obj.Settings.VirtualPopulationData.Name};
            MatchIdx = strcmpi(ThisList,obj.DatasetName);
            GroupIDs = [];
            if any(MatchIdx)
                dObj = obj.Settings.VirtualPopulationData(MatchIdx);
                ThisStatusOk = validate(dObj);
                ForceMarkAsInvalid = ~ThisStatusOk;
                
                if ThisStatusOk
                    
                    [~,~,VPopHeader,VPopData] = importData(dObj,dObj.FilePath);
                    
                    MatchIdx = strcmp(VPopHeader,obj.GroupName);
                    GroupIDs = VPopData(:,MatchIdx);
                    
                    if iscell(GroupIDs)
                        GroupIDs = cell2mat(GroupIDs);
                    end
                    GroupIDs = unique(GroupIDs);
                    GroupIDs = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
                else
                    GroupIDs = [];
                end
            else
                ForceMarkAsInvalid = false;
            end
            
            % ONLY if OptimizationData is valid, check Parameters
            ThisList = {obj.Settings.Parameters.Name};
            MatchIdx = strcmpi(ThisList,obj.RefParamName);
            if any(MatchIdx)
                pObj = obj.Settings.Parameters(MatchIdx);
            else
                pObj = QSP.Parameters.empty(0,1);
            end
                
            if ForceMarkAsInvalid                
                if ~isempty(pObj)
                    ThisStatusOk = validate(pObj);
                    ForceMarkAsInvalid = ~ThisStatusOk;
                else
                    ForceMarkAsInvalid = false;
                end
            end
            
            for index = 1:numel(obj.Item)
                % Validate Task-Group and ExcelFilePath
                ThisTask = getValidSelectedTasks(obj.Settings,obj.Item(index).TaskName);
                % Validate groupID
                MatchGroup = ismember(obj.Item(index).GroupID,GroupIDs);                
               
                if ~ForceMarkAsInvalid && ...
                        ~isempty(ThisTask) && ...
                        ~isempty(ThisTask.LastSavedTime) && ...
                        any(MatchGroup) && ...
                        ~isempty(obj.LastSavedTime)
                    
                    % Compare times
                    
                    % Optimization object (this)
                    ResultFileInfo = dir(fullfile(obj.Session.RootDirectory, obj.VPopResultsFolderName, obj.ExcelResultFileName));
                    if ~isempty(ResultFileInfo)
                        VpopLastSavedTime = ResultFileInfo.datenum;
                    else
                        VpopLastSavedTime = 0;
                    end
                                        
                    % Task object (item)
                    TaskLastSavedTime = ThisTask.LastSavedTime;
                    
                    % SimBiology Project file from Task
                    FileInfo = dir(ThisTask.FilePath);
                    TaskProjectLastSavedTime = FileInfo.datenum;
                    
                    % VirtualPopulationData object and file
                    VirtualPopulationDataLastSavedTime = dObj.LastSavedTime;
                    FileInfo = dir(dObj.FilePath);
                    VirtualPopulationDataFileLastSavedTime = FileInfo.datenum;
                                        
                    % Results file - ONE file
                    ThisFilePath = fullfile(obj.Session.RootDirectory,obj.VPopResultsFolderName,obj.ExcelResultFileName);
                    if exist(ThisFilePath,'file') == 2
                        FileInfo = dir(ThisFilePath);                        
                        ResultLastSavedTime = FileInfo.datenum;
                        
                        % Parameter object and file
                        if ~isempty(pObj)
                            ParametersLastSavedTime = pObj.LastSavedTime;
                            FileInfo = dir(pObj.FilePath);
                            if ~isempty(FileInfo)
                                ParametersFileLastSavedTime = FileInfo.datenum;    
                            else
                                ParametersFileLastSavedTime = Inf;
                            end
                        else
                            ResultLastSavedTime = Inf;
                            ParametersLastSavedTime = Inf;
                            ParametersFileLastSavedTime = Inf;
                        end
                    elseif ~isempty(obj.ExcelResultFileName)
                        ResultLastSavedTime = '';
                        % Display invalid
                        ValidFlag(index) = false;
                        ParametersLastSavedTime = Inf;
                        ParametersFileLastSavedTime = Inf;                        
                        InvalidMessages{index} = 'Excel file cannot be found';
                    else
                        ResultLastSavedTime = Inf;
                        ParametersLastSavedTime = Inf;
                        ParametersFileLastSavedTime = Inf;
                    end
                    
                    % Check
                    if VpopLastSavedTime < TaskLastSavedTime 
                        StaleFlag(index) = 1;
                    elseif VpopLastSavedTime < TaskProjectLastSavedTime 
                        StaleFlag(index) = 2;
                    elseif VpopLastSavedTime < VirtualPopulationDataLastSavedTime
                        StaleFlag(index) = 3;
                    elseif VpopLastSavedTime < VirtualPopulationDataFileLastSavedTime
                        StaleFlag(index) = 4;
                    elseif VpopLastSavedTime < ParametersLastSavedTime 
                        StaleFlag(index) = 5;
                    elseif VpopLastSavedTime < ParametersFileLastSavedTime
                        StaleFlag(index) = 6;
                    elseif (~isempty(ResultLastSavedTime) && VpopLastSavedTime > ResultLastSavedTime)
                        StaleFlag(index) = 7;
                    end
                                            
                elseif ForceMarkAsInvalid
                    % Display invalid
                    ValidFlag(index) = false;                    
                    InvalidMessages{index} = 'Invalid reference parameter set';
                elseif isempty(ThisTask) || ~any(MatchGroup)
                    % Display invalid
                    ValidFlag(index) = false;                    
                    InvalidMessages{index} = 'Invalid Task and/or Group ID';
                end          
            end 
        end %function
        
    end %methods
    
   
    %% Set Methods
    methods
        
        function set.Settings(obj,Value)
            validateattributes(Value,{'QSP.Settings'},{'scalar'});
            obj.Settings = Value;
        end
        
        function set.VPopResultsFolderName(obj,Value)
            validateattributes(Value,{'char'},{'row'});
            obj.VPopResultsFolderName = Value;
        end
        
        function set.DatasetName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.DatasetName = Value;
        end
        
        function set.GroupName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.GroupName = Value;
        end
        
        function set.RefParamName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RefParamName = Value;
        end
        
        function set.Item(obj,Value)
            validateattributes(Value,{'QSP.TaskGroup'},{});
            obj.Item = Value;
        end
    
        function set.SpeciesData(obj,Value)
            validateattributes(Value,{'QSP.SpeciesData'},{});
            obj.SpeciesData = Value;
        end
        
        function set.MaxNumSimulations(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','positive'});
            obj.MaxNumSimulations = Value;
        end
        
        function set.MaxNumVirtualPatients(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','positive'});
            obj.MaxNumVirtualPatients = Value;
        end
        
        function set.PlotType(obj,Value)
            Value = validatestring(Value,obj.ValidPlotTypes);
            obj.PlotType = Value;
        end
        
        function set.ShowInvalidVirtualPatients(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.ShowInvalidVirtualPatients = Value;
        end
        
        function set.PlotSettings(obj,Value)
            validateattributes(Value,{'struct'},{});
            obj.PlotSettings = Value;
        end
    end %methods
    
end %classdef
