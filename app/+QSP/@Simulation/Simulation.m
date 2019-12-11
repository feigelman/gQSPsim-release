classdef Simulation < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % Simulation - Defines a Simulation object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Simulation
    %
    % Syntax:
    %           obj = QSP.Simulation
    %           obj = QSP.Simulation('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Simulation Properties:
    %
    %
    % QSP.Simulation Methods:
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
        SimResultsFolderName = 'SimResults' 
        
        DatasetName = '' % OptimizationData Name
        GroupName = ''
        
        Item = QSP.TaskVirtualPopulation.empty(0,1)
        
        PlotSpeciesTable = cell(0,4)
        PlotItemTable = cell(0,6)
        PlotDataTable = cell(0,4)
        PlotGroupTable = cell(0,4)
        
        SelectedPlotLayout = '1x1'
        
        PlotSettings = repmat(struct(),1,12)

    end
    
    properties (SetAccess = 'private')
        SpeciesLineStyles
    end
    
    properties (Constant=true)
        NullVPop = 'ModelDefault'
    end
    
    %% Constructor
    methods
        function obj = Simulation(varargin)
            % Simulation - Constructor for QSP.Simulation
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Simulation object.
            %
            % Syntax:
            %           obj = QSP.Simulation('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Simulation object
            %
            % Example:
            %    aObj = QSP.Simulation();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});       
            
            % For compatibility
            if size(obj.PlotSpeciesTable,2) == 3
                obj.PlotSpeciesTable(:,4) = obj.PlotSpeciesTable(:,3);
            end
            if size(obj.PlotItemTable,2) == 4
                TaskNames = obj.PlotItemTable(:,3);
                VPopNames = obj.PlotItemTable(:,4);
                obj.PlotItemTable(:,5) = cellfun(@(x,y)sprintf('%s - %s',x,y),TaskNames,VPopNames,'UniformOutput',false);
            end
            if size(obj.PlotDataTable,2) == 3
                obj.PlotDataTable(:,4) = obj.PlotDataTable(:,3);
            end
            if size(obj.PlotGroupTable,2) == 3
                obj.PlotGroupTable(:,4) = obj.PlotGroupTable(:,3);
            end
            
            % assign plot settings names
            for index = 1:length(obj.PlotSettings)
                obj.PlotSettings(index).Title = sprintf('Plot %d', index);
            end
            
        end %function obj = Simulation(varargin)
        
    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            if ~isempty(obj.Item)
                SimulationItems = {};
                % Check what items are stale or invalid
                [StaleFlag,ValidFlag,InvalidMessages,StaleReasons] = getStaleItemIndices(obj);                
                
                for index = 1:numel(obj.Item)
                    ThisResultFilePath = obj.Item(index).MATFileName;
                    if isempty(ThisResultFilePath)
                        ThisResultFilePath = 'Results: N/A';
                    end

                    % Default
                    ThisItem = sprintf('%s - %s (%s)',obj.Item(index).TaskName,obj.Item(index).VPopName,ThisResultFilePath);
                    if StaleFlag(index)
                        % Item may be out of date
                            ThisItem = sprintf('***WARNING*** %s\n%s',ThisItem, sprintf('***Item may be out of date %s***', StaleReasons{index}));
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
                    SimulationItems = [SimulationItems; ThisItem]; %#ok<AGROW>
                end
            else
                SimulationItems = {};
            end

            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTimeStr;
                'Description',obj.Description;
                'Results Path',obj.SimResultsFolderName;
                'Dataset',obj.DatasetName;       
                'Group Name',obj.GroupName;
                'Items',SimulationItems;
                };
            
        end %function
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid)
            
            StatusOK = true;
            Message = sprintf('Simulation: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            if  obj.Session.UseParallel && ~isempty(getCurrentTask())
                return
            end
            
            % Validate task-vpop pair is valid (TODO: AG: check that params in vpop exist in the file)
            if ~isempty(obj.Settings)
                
                % Check that Dataset (OptimizationData) is valid if it exists
                if ~isempty(obj.DatasetName) || ~strcmpi(obj.DatasetName,'Unspecified')
                    MatchIndex = strcmpi({obj.Settings.OptimizationData.Name},obj.DatasetName);
                    % Clear dataset name if it's invalid
                    if FlagRemoveInvalid && ~any(MatchIndex)
                        obj.DatasetName = '';
                    elseif ~FlagRemoveInvalid && any(MatchIndex)
                        [ThisStatusOK,ThisMessage] = validate(obj.Settings.OptimizationData(MatchIndex),FlagRemoveInvalid);
                        if ~ThisStatusOK
                            StatusOK = false;
                            Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        end
                    end
                end
                
                % Remove the invalid task/vpop combos if any
                [TaskItemIndex,MatchTaskIndex] = ismember({obj.Item.TaskName},{obj.Settings.Task.Name});
                [VPopItemIndex,MatchVPopIndex] = ismember({obj.Item.VPopName},{obj.Settings.VirtualPopulation.Name});
                MatchNullVPopIndex = ismember({obj.Item.VPopName},obj.NullVPop);
                RemoveIndices = ~TaskItemIndex | (~VPopItemIndex & ~MatchNullVPopIndex);
                if any(RemoveIndices)
                    StatusOK = false;
                    ThisMessage = sprintf('Task-VPop rows %s are invalid.',num2str(find(RemoveIndices)));
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
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
                
                % Check VPops
                MatchVPopIndex(MatchVPopIndex == 0) = [];                
                for index = MatchVPopIndex
                    [ThisStatusOK,ThisMessage] = validate(obj.Settings.VirtualPopulation(index),FlagRemoveInvalid);
                    if ~ThisStatusOK
                        StatusOK = false;
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    end
                end
            end
            
            % Check that the group column specified contains only integers 
            if ~isempty(obj.DatasetName)
                Names = {obj.Settings.OptimizationData.Name};
                MatchIdx = strcmpi(Names,obj.DatasetName);

                % Continue if dataset exists
                if any(MatchIdx)
                    % Get dataset
                    dObj = obj.Settings.OptimizationData(MatchIdx);      
                    DestDatasetType = 'wide';
                    [StatusOK,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
                    
                    if StatusOK
                        tmp = cell2mat(OptimData(:, strcmp(obj.GroupName, OptimHeader)));
                        if ~all(isnumeric(tmp) & floor(tmp) == tmp)
                            StatusOK = false;
                            Message = sprintf('%s\nSpecified group column contains invalid (non-integer) data.\n', Message);
                        end
                    else
                        Message = sprintf('%s\nCould not load dataset file.\n', Message);
                    end
                end
            end
            
            % Simulation name forbidden characters
            if any(regexp(obj.Name,'[:*?/]'))
                Message = sprintf('%s\n* Invalid simulation name.', Message);
                StatusOK=false;
            end
            
            % Check if the same Task / Group / Vpop is assigned more than
            % once
            
            allItems = cell2table([{obj.Item.TaskName}', {obj.Item.VPopName}', {obj.Item.Group}']);
            [~,ia] = unique(allItems);
            
            if length(ia) < size(allItems,1) % duplicates
                dups = setdiff(1:size(allItems,1), ia);

                for k=1:length(dups); dups_{k} = num2str(dups(k)); end
                if length(dups)>1
                    Message = sprintf('Items %s are duplicates. Please remove before continuing.', ...
                        strjoin(dups_, ',') );
                else
                    Message = sprintf('Item %s is a duplicate. Please remove before continuing.', ...
                        dups_{1});
                end
                StatusOK = false;
            end
            
    
        end %function
        
        function clearData(obj)
            for index = 1:numel(obj.Item)
                obj.Item(index).MATFileName = [];
            end
        end
          
    end
    
    %% Methods    
    methods
        
        function [StatusOK,Message,vpopObj] = run(obj)
            
            % Unused for simulation
            vpopObj = QSP.VirtualPopulation.empty(0,1);
            
            % Invoke validate
            [StatusOK, Message] = validate(obj,false);
            
            % Invoke helper
            if StatusOK
                
                % For autosave with tag
                if obj.Session.AutoSaveBeforeRun
                    autoSaveFile(obj.Session,'Tag','preRunSimulation');
                end
                
                % Run helper
                [ThisStatusOK,thisMessage,ResultFileNames,Cancelled] = simulationRunHelper(obj);
                if ~ThisStatusOK && ~Cancelled
%                     error('run: %s',Message);
                    StatusOK = false;
                    Message = sprintf('%s\n\n%s', Message, thisMessage);
                    return
                end
                
                if Cancelled
                    return
                end
                
                % Update MATFileName in the simulation items
                for index = 1:numel(obj.Item)
                    obj.Item(index).MATFileName = ResultFileNames{index};
                end
                
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
        
        function [StaleFlag,ValidFlag,InvalidMessages,StaleReason] = getStaleItemIndices(obj)
            
            StaleFlag = false(1,numel(obj.Item));
            ValidFlag = true(1,numel(obj.Item));
            StaleReason = cell(1,numel(obj.Item));
            InvalidMessages = cell(1,numel(obj.Item));
            
            for index = 1:numel(obj.Item)
                ThisTask = getValidSelectedTasks(obj.Settings,obj.Item(index).TaskName);
                ThisVPop = getValidSelectedVPops(obj.Settings,obj.Item(index).VPopName);
                
                if ~isempty(ThisTask) && ~isempty(ThisTask.LastSavedTime) && ...
                        ((~isempty(ThisVPop) && ~isempty(ThisVPop.LastSavedTime)) || strcmpi(obj.Item(index).VPopName,QSP.Simulation.NullVPop)) && ...
                        ~isempty(obj.LastSavedTime)
                    
                    % Compare times
                    
                    % Simulation object (this)
                    SimLastSavedTime = obj.LastSavedTime;
                    
                    % Task object (item)
                    TaskLastSavedTime = ThisTask.LastSavedTime;
                    
                    % SimBiology Project file from Task
                    FileInfo = dir(ThisTask.FilePath);                    
                    TaskProjectLastSavedTime = FileInfo.datenum;
                    
                    % VPop object (item) and file
                    if ~isempty(ThisVPop) % Guard for NullVPop
                        VPopLastSavedTime = ThisVPop.LastSavedTime;
                        FileInfo = dir(ThisVPop.FilePath);
                        VPopFileLastSavedTime = FileInfo.datenum;
                    end
                    
                    % Results file
                    ThisFilePath = fullfile(obj.Session.RootDirectory,obj.SimResultsFolderName,obj.Item(index).MATFileName);
                    if exist(ThisFilePath,'file') == 2
                        FileInfo = dir(ThisFilePath);
                        ResultLastSavedTime = FileInfo.datenum;
                    elseif ~isempty(obj.Item(index).MATFileName)
                        ResultLastSavedTime = '';
                        % Display invalid
                        ValidFlag(index) = false;
                        InvalidMessages{index} = 'MAT file cannot be found';
                    else
                        ResultLastSavedTime = '';
                    end
                    
                    % Check
                    if ~isempty(ResultLastSavedTime)
                        STALE_REASON = '';
                        if ResultLastSavedTime < TaskLastSavedTime  % task has changed
                            STALE_REASON = '(Task has changed)';
                        elseif ~isempty(ThisVPop) && ResultLastSavedTime < VPopFileLastSavedTime % Vpop has changed
                            STALE_REASON = '(Vpop has changed)';
                        elseif ResultLastSavedTime < SimLastSavedTime % simulation has changed
                            STALE_REASON = '(Simulation has changed)';
                        elseif ResultLastSavedTime < TaskProjectLastSavedTime % sbproj has changed
                            STALE_REASON = '(Sbproj has changed)';
                        end
                        
                        if ~isempty(STALE_REASON)
                            % Item may be out of date
                            StaleFlag(index) = true;
                            StaleReason{index} = STALE_REASON;
                        end                    
                    end
                    
                elseif isempty(ThisTask) || isempty(ThisVPop)
                    % Display invalid
                    ValidFlag(index) = false;      
                    InvalidMessages{index} = 'Invalid Task and/or VPop';
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
        
        function set.SimResultsFolderName(obj,Value)
            validateattributes(Value,{'char'},{'row'});
            obj.SimResultsFolderName = Value;
        end
        
        function set.DatasetName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.DatasetName = Value;
        end
        
        function set.GroupName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.GroupName = Value;
        end
        
        function set.Item(obj,Value)
            validateattributes(Value,{'QSP.TaskVirtualPopulation'},{});
            obj.Item = Value;
        end
        
        function set.PlotSpeciesTable(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.PlotSpeciesTable = Value;
        end
        
        function set.PlotItemTable(obj,Value)
            validateattributes(Value,{'cell'},{'size',[nan 6]});
            obj.PlotItemTable = Value;
        end
        
        function set.PlotDataTable(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.PlotDataTable = Value;
        end
        
        function set.PlotGroupTable(obj,Value)
            validateattributes(Value,{'cell'},{'size',[nan 4]});
            obj.PlotGroupTable = Value;
        end
        
        function set.PlotSettings(obj,Value)
            validateattributes(Value,{'struct'},{});
            obj.PlotSettings = Value;
        end
    end %methods
    
end %classdef
