classdef Session < QSP.abstract.BasicBaseProps & uix.mixin.HasTreeReference
    % Session - Defines an session object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Session
    %
    % Syntax:
    %           obj = QSP.Session
    %           obj = QSP.Session('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Session Properties:
    %
    %   Settings - 
    %
    %   Simulation - 
    %
    %   Optimization - 
    %
    %   VirtualPopulationGeneration - 
    %
    %   RootDirectory -
    %
    %   ResultsDirectory -
    %
    %   RelativeResultsPath -
    %
    %   RelativeFunctionsPath -
    %
    % QSP.Session Methods:
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
        RootDirectory = pwd
        RelativeResultsPath = ''        
        RelativeUserDefinedFunctionsPath = ''
        RelativeObjectiveFunctionsPath = ''        
        RelativeAutoSavePath = ''
        AutoSaveFrequency = 1 % minutes
        AutoSaveBeforeRun = true
        UseParallel = false
        ParallelCluster
        UseAutoSaveTimer = false
    end
    
    properties (Transient=true)        
        timerObj
    end
    
    properties % (NonCopyable=true) % Note: These properties need to be public for tree
        Settings = QSP.Settings.empty(1,0);
        Simulation = QSP.Simulation.empty(1,0)
        Optimization = QSP.Optimization.empty(1,0)
        VirtualPopulationGeneration = QSP.VirtualPopulationGeneration.empty(1,0)
        CohortGeneration = QSP.CohortGeneration.empty(1,0)
        Deleted = QSP.abstract.BaseProps.empty(1,0)
    end
    
    properties (SetAccess='private')
        SessionName = ''
        
        ColorMap1 = QSP.Session.DefaultColorMap
        ColorMap2 = QSP.Session.DefaultColorMap
        
        toRemove = false;
    end
    
    properties (Constant=true)
        DefaultColorMap = repmat(lines(10),5,1)
    end
        
    properties (Dependent=true, SetAccess='immutable')
        ResultsDirectory
        ObjectiveFunctionsDirectory
        UserDefinedFunctionsDirectory
        AutoSaveDirectory
    end
    
    %% Constructor and Destructor
    methods
        function obj = Session(varargin)
            % Session - Constructor for QSP.Session
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Session object.
            %
            % Syntax:
            %           obj = QSP.Session('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Session object
            %
            % Example:
            %    aObj = QSP.Session();
            
            % Instantiate settings
            obj.Settings = QSP.Settings;
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Provide Session handle to Settings
            obj.Settings.Session = obj;
            
            info = ver;
            if ismember('Parallel Computing Toolbox', {info.Name})
                clusters = parallel.clusterProfiles;
                obj.ParallelCluster = clusters{1};
            else
                obj.ParallelCluster = {''};
            end
            
%             % Initialize timer - If you call initialize here, it will
%             enter a recursive loop. Do not call here. Instead, invoke
%             initializeTimer on the App side when new sessions are created
%             and call deleteTimer on the App side when sessions are closed
%             initializeTimer(obj);            
            
        end %function obj = Session(varargin)
        
        % Destructor
%         function delete(obj)
%             removeUDF(obj)             
%         end
        
    end %methods
    
    
    %% Static methods
    methods (Static=true)
        function obj = loadobj(s)
            
            obj = s;
            
            info = ver;
            if ~any(contains({info.Name},'Parallel Computing Toolbox'))
                obj.UseParallel = false; % disable parallel
            end
            % Invoke refreshData
            try 
                [StatusOK,Message] = refreshData(obj.Settings);
            catch err
                if strcmp(err.identifier, 'Settings:CancelledLoad')
                     % cancelled
                     obj.toRemove = true;
                else
                    rethrow(err)
                end
            end
        end %function
        
    end %methods (Static)
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTimeStr;
                'Description',obj.Description;       
                'Root Directory',obj.RootDirectory;
                'Objective Functions Directory',obj.ObjectiveFunctionsDirectory;
                'User Functions Directory',obj.UserDefinedFunctionsDirectory;
                'Use AutoSave',mat2str(obj.UseAutoSaveTimer);
                'AutoSave Directory',obj.AutoSaveDirectory;
                'AutoSave Frequency (min)',num2str(obj.AutoSaveFrequency);
                'AutoSave Before Run',mat2str(obj.AutoSaveBeforeRun);
                };
        end
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid) %#ok<INUSD>
            
            StatusOK = true;
            Message = sprintf('Session: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            if ~isfolder(obj.RootDirectory)
                StatusOK = false;
                Message = sprintf('%s\n* Invalid Root Directory specified "%"',Message,obj.RootDirectory);
            end
        end
        
        function clearData(obj) %#ok<MANU>
        end
    end
    
    
    %% Callback (non-standard)
    methods

        function onTimerCallback(obj,~,~)
            
            % Note, autosave is applied to vObj.Data, not vObj.TempData
            autoSaveFile(obj);
            
        end %function        
        
    end %methods
    
    %% Methods
    methods
        
        
        function initializeTimer(obj)
            
            % Delete timer
            deleteTimer(obj);
                
            % Create timer
            obj.timerObj = timer(...
                'ExecutionMode','fixedRate',...
                'BusyMode','drop',...
                'Tag','QSPtimer',...
                'Period',1*60,... % minutes
                'StartDelay',1,...
                'TimerFcn',@(h,e)onTimerCallback(obj,h,e));
            
            % Only start if UseAutoSave is true
            if obj.UseAutoSaveTimer
                start(obj.timerObj);
            end
            
        end %function
        
        function deleteTimer(obj)
            if ~isempty(obj.timerObj)
                if strcmpi(obj.timerObj.Running,'on')
                    stop(obj.timerObj);
                end
                delete(obj.timerObj);
            end
        end %function
        
        function newObj = copy(obj,varargin)
            % Note: copy actually is used in place of BaseProps copy
            
            if ~isempty(obj)
                
                % Copy basic properties
                newObj = QSP.Session;
                newObj.Name = obj.Name; % Do not copy name, as this changes the tree node
                newObj.SessionName = obj.SessionName; 
                newObj.Description = obj.Description;                
              
                newObj.RootDirectory = obj.RootDirectory;
                newObj.RelativeResultsPath = obj.RelativeResultsPath;
                newObj.RelativeUserDefinedFunctionsPath = obj.RelativeUserDefinedFunctionsPath;
                newObj.RelativeObjectiveFunctionsPath = obj.RelativeObjectiveFunctionsPath;
                newObj.RelativeAutoSavePath = obj.RelativeAutoSavePath;
                newObj.AutoSaveFrequency = obj.AutoSaveFrequency;
                newObj.AutoSaveBeforeRun = obj.AutoSaveBeforeRun;
                newObj.UseParallel = obj.UseParallel;
                newObj.ParallelCluster = obj.ParallelCluster;
                newObj.UseAutoSaveTimer = obj.UseAutoSaveTimer;
                
                newObj.LastSavedTime = obj.LastSavedTime;
                newObj.LastValidatedTime = obj.LastValidatedTime;
                
                newObj.TreeNode = obj.TreeNode;
                
                % Carry-over Settings object; just assign Session
                sObj = obj.Settings;                
                sObj.Session = newObj;
                
                newObj.Settings = sObj;
                newObj.Simulation = obj.Simulation;
                newObj.Optimization = obj.Optimization;
                newObj.VirtualPopulationGeneration = obj.VirtualPopulationGeneration;
                newObj.CohortGeneration = obj.CohortGeneration;
                newObj.Deleted = obj.Deleted;
                
                for idx = 1:numel(obj.Settings.Task)
%                     sObj.Task(idx) = copy(obj.Settings.Task(idx));
                    sObj.Task(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.VirtualPopulation)
%                     sObj.VirtualPopulation(idx) = copy(obj.Settings.VirtualPopulation(idx));
                    sObj.VirtualPopulation(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.Parameters)
%                     sObj.Parameters(idx) = copy(obj.Settings.Parameters(idx));
                    sObj.Parameters(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.OptimizationData)
%                     sObj.OptimizationData(idx) = copy(obj.Settings.OptimizationData(idx));
                    sObj.OptimizationData(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.VirtualPopulationData)
%                     sObj.VirtualPopulationData(idx) = copy(obj.Settings.VirtualPopulationData(idx));
                    sObj.VirtualPopulationData(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.VirtualPopulationGenerationData)
%                     sObj.VirtualPopulationGenerationData(idx) = copy(obj.Settings.VirtualPopulationGenerationData(idx));
                    sObj.VirtualPopulationGenerationData(idx).Session = newObj;
                end
          
                % Get all BaseProps and if isprop(...,'QSP.Session)...
                for idx = 1:numel(obj.Simulation)
%                     newObj.Simulation(idx) = copy(obj.Simulation(idx));
                    newObj.Simulation(idx).Session = newObj;
                    newObj.Simulation(idx).Settings = sObj;
                end
                for idx = 1:numel(obj.Optimization)
%                     newObj.Optimization(idx) = copy(obj.Optimization(idx));
                    newObj.Optimization(idx).Session = newObj;
                    newObj.Optimization(idx).Settings = sObj;
                end
                for idx = 1:numel(obj.VirtualPopulationGeneration)
%                     newObj.VirtualPopulationGeneration(idx) = copy(obj.VirtualPopulationGeneration(idx));
                    newObj.VirtualPopulationGeneration(idx).Session = newObj;
                    newObj.VirtualPopulationGeneration(idx).Settings = sObj;
                end
                for idx = 1:numel(obj.CohortGeneration)
%                     newObj.CohortGeneration(idx) = copy(obj.CohortGeneration(idx));
                    newObj.CohortGeneration(idx).Session = newObj;
                    newObj.CohortGeneration(idx).Settings = sObj;
                end
             
                % TODO:
                for index = 1:numel(obj.Deleted)
%                     newObj.Deleted(index) = copy(obj.Deleted(index));
                    if isprop(newObj.Deleted(index),'Settings')
                        newObj.Deleted(index).Settings = sObj;
                    end
                    if isprop(newObj.Deleted(index),'Session')
                        newObj.Deleted(index).Session = newObj;
                    end
                end 
            end %if
            
        end %function
        
        function setSessionName(obj,SessionName)
            obj.SessionName = SessionName;
        end %function
        
        function Colors = getItemColors(obj,NumItems)
            ThisColorMap = obj.ColorMap1;
            if isempty(ThisColorMap) || size(ThisColorMap,2) ~= 3
                ThisColorMap = obj.DefaultColorMap;
            end
            if NumItems ~= 0
                Colors = uix.utility.getColorMap(ThisColorMap,NumItems);
            else
                Colors = [];
            end
        end %function
            
        function Colors = getGroupColors(obj,NumGroups)
            ThisColorMap = obj.ColorMap2;
            if isempty(ThisColorMap) || size(ThisColorMap,2) ~= 3
                ThisColorMap = obj.DefaultColorMap;
            end
            if NumGroups ~= 0
                Colors = uix.utility.getColorMap(ThisColorMap,NumGroups);
            else
                Colors = [];
            end
        end %function
        
        function autoSaveFile(obj,varargin)
            
            p = inputParser;
            p.KeepUnmatched = false;
            
            % Define defaults and requirements for each parameter
            p.addParameter('Tag',''); %#ok<*NVREPL>
            
            p.parse(varargin{:});
            
            Tag = p.Results.Tag;
            
            try
                % Save when fired
                s.Session = obj; %#ok<STRNU>
                % Remove .qsp.mat from name temporarily
                ThisName = regexprep(obj.SessionName,'\.qsp\.mat','');
                TimeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');
                if ~isempty(Tag)
                    FileName = sprintf('%s_%s_%s.qsp.mat',ThisName,TimeStamp,Tag);
                else
                    FileName = sprintf('%s_%s.qsp.mat',ThisName,TimeStamp);
                end
                FilePath = fullfile(obj.AutoSaveDirectory,FileName);
                save(FilePath,'-struct','s')
            catch err %#ok<NASGU>
                warning('The file could not be auto-saved');  
                if strcmpi(obj.timerObj.Running,'off')
                    start(obj.timerObj);
                end
            end
        end %function
        
    end %methods    
    
    %% Get/Set Methods
    methods
      
        function set.RootDirectory(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RootDirectory = fullfile(Value);
        end %function
        
        function set.RelativeResultsPath(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RelativeResultsPath = fullfile(Value);
        end %function
        
        function set.RelativeObjectiveFunctionsPath(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RelativeObjectiveFunctionsPath = fullfile(Value);
        end %function
        
        function set.RelativeUserDefinedFunctionsPath(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RelativeUserDefinedFunctionsPath = fullfile(Value);                
        end %function
        
        function set.RelativeAutoSavePath(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RelativeAutoSavePath = fullfile(Value);                
        end %function
        
        function addUDF(obj)
            % add the UDF to the path
            p = path;
            if isempty(obj.RelativeUserDefinedFunctionsPath)
                % don't add anything unless UDF is defined
                return
            end
            
            UDF = fullfile(obj.RootDirectory, obj.RelativeUserDefinedFunctionsPath);
            
            if exist(UDF, 'dir')
                if ~isempty(obj.RelativeUserDefinedFunctionsPath) && ...
                	isempty(strfind(p, UDF))
                    addpath(genpath(UDF))
                end
            end    
        end
        
        function removeUDF(obj)
            % don't do anything if the session was empty (nothing selected)
            if isempty(obj)
                return
            end
                
            % don't do anything if the UDF is empty
            if isempty(obj.RelativeUserDefinedFunctionsPath)
                return
            end
            
            % remove UDF from the path
            p = path;
            subdirs = genpath(fullfile(obj.RootDirectory, obj.RelativeUserDefinedFunctionsPath));
            if isempty(subdirs)
                return
            end
            
            if ispc
                subdirs = strsplit(subdirs,';');
                pp = strsplit(p,';');
            else
                subdirs = strsplit(subdirs,':');
                pp = strsplit(p,':');                
            end
            
            pp = setdiff(pp, subdirs);
            
            if ispc
                ppp = strjoin(pp,';');
            else
                ppp = strjoin(pp,':');
            end
            
            path(ppp)
        end
        
        function value = get.ResultsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeResultsPath);
        end
        
        function value = get.ObjectiveFunctionsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeObjectiveFunctionsPath);
        end
        
        function value = get.UserDefinedFunctionsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeUserDefinedFunctionsPath);
        end
        
        function value = get.AutoSaveDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeAutoSavePath);
        end
        
        function set.UseAutoSaveTimer(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.UseAutoSaveTimer = Value;
        end
        
        function set.AutoSaveFrequency(obj,Value)
            validateattributes(Value,{'numeric'},{'positive'});
            obj.AutoSaveFrequency = Value;
        end
        
        function set.AutoSaveBeforeRun(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.AutoSaveBeforeRun = Value;
        end
        
        function set.ColorMap1(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.ColorMap1 = Value;
        end
        
        function set.ColorMap2(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.ColorMap2 = Value;
        end
        
        
    end %methods
    
end %classdef
