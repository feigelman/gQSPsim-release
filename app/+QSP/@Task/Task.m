classdef Task < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % Task - Defines a Task object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Task
    %
    % Syntax:
    %           obj = QSP.Task
    %           obj = QSP.Task('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Task Properties:
    %
    %   Study -
    %
    %   VirtualPopulation -
    %
    %   Parameters -
    %
    %   OptimizationData -
    %
    %   VirtualPopulationData -
    %
    % QSP.Task Methods:
    %
    %
    %
    
    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 299 $  $Date: 2016-09-06 17:18:29 -0400 (Tue, 06 Sep 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        ActiveVariantNames = {}
        ActiveDoseNames = {}
        ActiveSpeciesNames = {}
        InactiveReactionNames = {}
        InactiveRuleNames = {}
        OutputTimesStr = ''
        MaxWallClockTime = 60
        RunToSteadyState = true
        TimeToSteadyState = 100
        Resample = true
        ModelObj_ = QSP.Model % Need default for copy to work (QSP.Model)
    end
    
    %% Protected Properties
    properties (GetAccess=public, SetAccess=protected)
        ModelName
        ModelTimeStamp
        ExportedModelTimeStamp 
        ExportedModel
        Species
        Parameters
        
        VarModelObj        
    end
    
    %% Protected Transient Properties
    properties (GetAccess=public, SetAccess=protected, Transient = true)
        ModelList = {}        
    end
    
    %% Protected Transient Properties
%     properties (GetAccess=public, SetAccess=protected, Transient = true)
%         VarModelObj
%         ModelObj_
% 
%     end
    
%     %% Private Transient Properties
%     properties (GetAccess=private, SetAccess=private, Transient = true)
%         ModelObj_
%     end
    %% Dependent Properties
    properties(SetAccess=protected,Dependent=true)
        ModelObj
        ConfigSet
        VariantNames
        DoseNames
        SpeciesNames
        ParameterNames
        ParameterValues
        ReactionNames
        RuleNames
        OutputTimes
        DefaultOutputTimes
        DefaultMaxWallClockTime        
    end
    
    %% Constructor
    methods
        function obj = Task(varargin)
            % Task - Constructor for QSP.Task
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Task object.
            %
            % Syntax:
            %           obj = QSP.Task('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Task object
            %
            % Example:
            %    aObj = QSP.Task();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            obj.ExportedModelTimeStamp = 0;
        end %function obj = Task(varargin)
        
        [t,x,names] = simulate(obj, varargin) % prototype
        
        function compile(obj)
            
             % rebuild model if necessary
             if ~obj.checkExportedModelCurrent()
                 constructModel(obj);
                disp('Rebuilding model')
             end
         
        end

    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            if obj.RunToSteadyState
                RunToSteadyStateStr = 'yes';
                TimeToSteadyStateStr = num2str(obj.TimeToSteadyState);
            else
                RunToSteadyStateStr = 'no';
                TimeToSteadyStateStr = 'N/A';
            end
            
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTimeStr;
                'Description',obj.Description;
                'Model',obj.RelativeFilePath;                
                'Active Variants',obj.ActiveVariantNames;
                'Active Doses',obj.ActiveDoseNames;
                'Active Species',obj.ActiveSpeciesNames;
                'Inactive Rules',obj.InactiveRuleNames;
                'Inactive Reactions',obj.InactiveReactionNames;
                'Output Times',obj.OutputTimesStr;
                'Run to Steady State',RunToSteadyStateStr;
                'Time to Steady State',TimeToSteadyStateStr;
                'Max Wall Clock Time', obj.MaxWallClockTime;
                };
        end
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid)
            
            StatusOK = true;
            Message = '';
            if  obj.Session.UseParallel && ~isempty(getCurrentTask())
                return
            end
            
            if isempty(obj)
                Message = 'Object is empty!';
                StatusOK = false;
                return
            end
            
            % Task name forbidden characters
            if any(regexp(obj.Name,'[:*?/]'))
                Message = sprintf('%s\n* Invalid task name.', Message);
                StatusOK = false;
                return;
            end
            
            FileInfo = dir(obj.FilePath);
            if length(FileInfo)==1 && ~isempty(obj.LastValidatedTime) && (datenum(obj.LastValidatedTime) > FileInfo.datenum) 
                StatusOK = true;
                Message = '';
                return
            end
            
            % Default message            
            Message = sprintf('Task: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            % Import model
            ThisMaxWallClockTime = obj.MaxWallClockTime;
%             thisObj = obj.copy();
            
            [ThisStatusOk,ThisMessage] = importModel(obj,obj.FilePath,obj.ModelName);
            obj.MaxWallClockTime = ThisMaxWallClockTime; % override model defaults
            if ~ThisStatusOk
                Message = sprintf('%s\n* Error loading model "%s" in "%s". %s\n',Message,obj.ModelName,obj.FilePath,ThisMessage);
            end            
            
%             obj = thisObj;
            % Active Variants
            [InvalidActiveVariantNames,MatchIndex] = getInvalidActiveVariantNames(obj);
            if FlagRemoveInvalid
                obj.ActiveVariantNames(MatchIndex) = [];
            end
            
            % Active Doses
            [InvalidActiveDoseNames,MatchIndex] = getInvalidActiveDoseNames(obj);
            if FlagRemoveInvalid
                obj.ActiveDoseNames(MatchIndex) = [];
            end
            
            % Active Species
            [InvalidActiveSpeciesNames,MatchIndex] = getInvalidActiveSpeciesNames(obj);
            if FlagRemoveInvalid
                obj.ActiveSpeciesNames(MatchIndex) = [];
            end
            
            % Inactive Rules
            [InvalidInactiveRuleNames,MatchIndex] = getInvalidInactiveRuleNames(obj);
            if FlagRemoveInvalid
                obj.InactiveRuleNames(MatchIndex) = [];
            end
            
            % Inactive Reactions
            [InvalidInactiveReactionNames,MatchIndex] = getInvalidInactiveReactionNames(obj);
            if FlagRemoveInvalid
                obj.InactiveReactionNames(MatchIndex) = [];
            end
            
            % Check if any invalid components exist
            if ~isempty(InvalidActiveVariantNames) || ~isempty(InvalidActiveDoseNames) || ~isempty(InvalidActiveSpeciesNames) || ...
                    ~isempty(InvalidInactiveRuleNames) || ~isempty(InvalidInactiveReactionNames)
                StatusOK = false;
                Message = sprintf('%s\n* Invalid components exist in the task "%s".\n',Message,obj.Name);
            end
            
            % OutputTimes
            try
                if ~isnumeric(obj.OutputTimes) && ~isnumeric(eval(obj.OutputTimes))
                    StatusOK = false;
                    Message = sprintf('%s\n* Invalid OutputTimes. OutputTimes must be valid Matlab numeric vector.\n',Message);                
                elseif isempty(obj.OutputTimes)
                    StatusOK = false;
                    Message = sprintf('%s\n* Invalid OutputTimes. OutputTimes must not be empty.\n',Message);
                end
            
            catch
                StatusOK = false;
                Message = sprintf('%s\n* Invalid OutputTimes. OutputTimes must not be valid Matlab numeric vector.\n',Message);
            end            

            
            % MaxWallClockTime
            if obj.MaxWallClockTime == 0
                StatusOK = false;
                Message = sprintf('%s\n* Invalid MaxWallClockTime. MaxWallClockTime must be > 0.\n',Message);
            end
            
            if StatusOK
                obj.LastValidatedTime = datestr(now);
            else
                obj.LastValidatedTime = '';
            end
            
            % at least some active species defined
            if isempty(obj.ActiveSpeciesNames)
                StatusOK = false;
                Message = sprintf('%s\n* At least one active species must be defined\n',Message);
            end
                

            
        end %function
        
        function clearData(obj)
            if ~isempty(obj.VarModelObj)
                obj.VarModelObj = obj.VarModelObj.copyobj();
            end
            % AG: @Justin - removing the lines below. New instance should
            % point to the same QSP.Model
%             if ~isempty(obj.ModelObj_)
%                 obj.ModelObj_ = obj.ModelObj_.copyobj();
%             end            
        end
    end
    
    %% Protected Methods
    methods (Access=protected)
        function copyProperty(obj,Property,Value)
            if isprop(obj,Property)
                obj.(Property) = Value;
            end
        end %function
        
        [StatusOK Message] = constructModel(obj)
        
%         function upToDate = checkModelCurrent(obj)
%             % check just that the task was saved after the sbproj file was
%             % last modified
%             FileInfo = dir(obj.FilePath);
%             if length(FileInfo)>1
%                 upToDate=false;
%                 return
%             end
%             
%             if isempty(obj.LastSavedTime)
%                 upToDate = true;
%                 return
%             end
%             
%             if FileInfo.datenum > datenum(obj.ModelTimeStamp)
%                 upToDate = false;
%             else
%                 upToDate = true;
%             end
%         end
        
        function upToDate = checkExportedModelCurrent(obj)
            FileInfo = dir(obj.FilePath);
            if length(FileInfo)>1 || isempty(FileInfo)
                upToDate=false;
                return
            end
           
            if isempty(FileInfo.datenum) || ...
                    isempty(obj.ExportedModelTimeStamp) || ...
                    FileInfo.datenum > obj.ExportedModelTimeStamp || ...
                    obj.LastSavedTime > obj.ExportedModelTimeStamp || ...
                    isempty(obj.VarModelObj)
                upToDate = false;
            else
                upToDate = true;
            end

        end
    end
    
   
    %% Methods
    methods
        
        function ModelNames = getModelList(obj)
            
            if ~isempty(obj.ModelObj)
                ModelNames = obj.ModelObj.ModelList;
            else
                ModelNames = {};
            end
            
        end %function
        
        function [StatusOk,Message] = importModel(obj,ProjectPath,ModelName)
            
            % Defaults
            StatusOk = true;
            Message = '';
            
            % Clean-up
            theseModels = obj.Session.Settings.Model;
            TheseFilePaths = {theseModels.FilePath};
            TheseFilePaths = TheseFilePaths(:);
            TheseModelNames = {theseModels.ModelName};
            TheseModelNames = TheseModelNames(:);
            
            % Delete any entries with empty model names
            IsEmpty = cellfun(@isempty,TheseModelNames);
            delete(theseModels(IsEmpty))
            theseModels(IsEmpty) = [];
            obj.Session.Settings.Model = theseModels;
            TheseFilePaths(IsEmpty) = [];
            TheseModelNames(IsEmpty) = [];
            
            % If model name is empty, use the model name from an existing
            % node
            if isempty(ModelName)
                MatchIdx = find(strcmpi(ProjectPath,TheseFilePaths),1,'first');
                if ~isempty(MatchIdx)
                    ModelName = TheseModelNames{MatchIdx};
                    obj.ModelName = ModelName;
                end
            else
                obj.ModelName = ModelName;

            end
            
            ThisData = [TheseFilePaths TheseModelNames];
        
            AllKeepIdx = [];
            SkipIdx = [];
            if ~isempty(ThisData)
                for rowIdx = 1:size(ThisData,1)
                    if ~ismember(rowIdx,SkipIdx)
                        KeepIdx = find(strcmpi(ThisData(rowIdx,1),TheseFilePaths) & strcmpi(ThisData(rowIdx,2),TheseModelNames));
                        AllKeepIdx = [AllKeepIdx,KeepIdx(1)]; %#ok<AGROW>
                        SkipIdx = [SkipIdx KeepIdx(2:end)]; %#ok<AGROW>
                    end
                end
            end
            delete(theseModels(SkipIdx));
            theseModels(SkipIdx) = [];
            obj.Session.Settings.Model = theseModels;
            
            TheseFilePaths = TheseFilePaths(AllKeepIdx);
            TheseModelNames = TheseModelNames(AllKeepIdx);
            
            % Check if a QSP.Model already exists by matching ProjectPath
            % and ModelName
            MatchIdx = [];
            if ~isempty(ProjectPath) && ~isempty(ModelName)
                
                % Find the matching model
                MatchIdx = find(...
                    ismember(TheseFilePaths,ProjectPath) & ...
                    ismember(TheseModelNames,ModelName));
            end
            
            if ~isfile(ProjectPath) % || isempty(ModelName)
                % Clear
                obj.ModelObj_ = QSP.Model.empty(0,1);
                
            elseif ~isempty(MatchIdx)
                % if the model is up-to-date then just use the existing
                % model, otherwise reimport and update the stored model
                
                projectDir = dir(ProjectPath);
                modelTimeStamp = projectDir.datenum;
                
                if theseModels(MatchIdx).ModelTimeStamp < modelTimeStamp
                    % out of date and needs to be reimported
                    thisObj = QSP.Model();
                    [StatusOK,Message] = importModel(thisObj,ProjectPath,ModelName);
                    % If import errors for 
                    if StatusOK
                        obj.ModelObj_ = thisObj;
                        % Store into Settings
                        obj.Session.Settings.Model(MatchIdx) = thisObj;
                    else
                        obj.ModelObj_ = QSP.Model.empty(0,1);
                        Message = sprintf('%s\nError encountered while loading model.', Message);
                    end
                else
                    % Assign to an existing model
                    obj.ModelObj_ = theseModels(MatchIdx);
                end
            else
                % Create a new model
                thisObj = QSP.Model();
                [StatusOK,Message] = importModel(thisObj,ProjectPath,ModelName);
                % If import errors for 
                if StatusOK
                    obj.ModelObj_ = thisObj;
                    % Store into Settings
                    obj.Session.Settings.Model(end+1) = thisObj;
                else
                    obj.ModelObj_ = QSP.Model.empty(0,1);
                end
            end
        end %function
        
%         function ModelNames = getModelList(obj)
%             % Check timestamp - make sure model is older than the task's
%             % LastSavedTime
%             
%             ModelSavedRecently = false;
%             FileInfo = dir(obj.FilePath);
%             if ~isempty(FileInfo)
%                 ModelLastSavedTime = FileInfo.datenum;
%                 % Check if the model was saved after the task
%                 if ModelLastSavedTime > datenum(obj.LastSavedTime)
%                     ModelSavedRecently = true;
%                 end
%             end
%             
%             ModelNames = {};
%             % If ModelList is empty or model was saved after the task was saved
%             if ~isempty(obj.FilePath) && ~isdir(obj.FilePath) && exist(obj.FilePath,'file') && ...
%                     (isempty(obj.ModelList) || ModelSavedRecently) 
%                 try
%                     AllModels = sbioloadproject(obj.FilePath);
%                 catch
%                     AllModels = [];
%                 end     
%                 if ~isempty(AllModels) && isstruct(AllModels)
%                     AllModels = cell2mat(struct2cell(AllModels));
%                     m1 = sbioselect(AllModels,'type','sbiomodel');
%                     if ~isempty(m1)
%                         ModelNames = get(m1,'Name');
%                     end
%                 end
%             elseif ~isempty(obj.FilePath) && ~isdir(obj.FilePath) && exist(obj.FilePath,'file')
%                 ModelNames = obj.ModelList;            
%             end
%             
%         end %function
%         
%         function [StatusOk,Message] = importModel(obj,ProjectPath,ModelName)
%             
%             % Defaults
%             StatusOk = true;
%             Message = '';
%             warning('off', 'SimBiology:sbioloadproject:Version')
%             
%             % Clear LastValidatedTime only if paths changed
%             if ~isequal(obj.FilePath,ProjectPath)                
%                 obj.LastValidatedTime = '';
%             end
%             % Store path
%             obj.FilePath = ProjectPath;
%             
%             % Load project
%             try
%                 AllModels = sbioloadproject(ProjectPath);
%             catch ME
%                 StatusOk = false;
%                 Message = ME.message;
%                 obj.ModelObj_ = [];
%                 obj.ModelName = '';
%                 obj.ModelList = {};
%                 obj.MaxWallClockTime = [];
%                 obj.OutputTimesStr = '';
%             end
%             
%             if StatusOk
%                 AllModels = cell2mat(struct2cell(AllModels));
%                 m1 = sbioselect(AllModels,'type','sbiomodel');
%                 
%                 if isempty(m1)
%                     StatusOk = false;
%                     Message = sprintf('Model "%s" not found in project',ModelName);
%                     obj.ModelObj_ = [];
%                     obj.ModelName = '';
%                     obj.ModelList = {};
%                     obj.MaxWallClockTime = [];
%                     obj.OutputTimesStr = '';
%                 else
%                     ThisModelList = {m1.Name};
%                     % Filter according to ModelName
%                     if ~isempty(ModelName)
%                         m1 = m1(strcmpi(ThisModelList,ModelName));
%                         %                     m1 = sbioselect(AllModels,'Name',ModelName,'type','sbiomodel');
%                     else
%                         m1 = m1(1);
%                     end
%                     ModelName = m1.Name;
%                 
%                     obj.ModelObj_ = m1;
%                     obj.ModelName = ModelName;
%                     obj.ModelList = ThisModelList;
%                     if isempty(obj.ModelTimeStamp)
%                         obj.MaxWallClockTime = m1.ConfigSet.MaximumWallClock;
%                     end
%                     obj.ModelTimeStamp = now;                    
%                     
%                     if isempty(obj.OutputTimesStr)
%                         % Use StopTime to compute
%                         StopTime = obj.ConfigSet.StopTime;
%                         % Update OutputTimesStr and actual value
%                         obj.OutputTimesStr = sprintf('[0:%2f/100:%2f]',StopTime,StopTime);
%                     end
%                 end %if
%                 
%                 
%             end %if
%         end %function
        
%         function [StatusOk,Message] = copyModel(obj,srcObj)            
%             
%             % Defaults
%             StatusOk = true;
%             Message = '';
%             
%             if isempty(obj.FilePath) || strcmpi(obj.FilePath,srcObj.FilePath)
%                 obj.FilePath = srcObj.FilePath;
%                 if ~isempty(srcObj.ModelObj_)
%                     obj.ModelObj_ = copyobj(srcObj.ModelObj_);
%                 else
%                     obj.ModelObj_ = QSP.Model.empty(0,1);
%                 end
%                 obj.ModelName = srcObj.ModelName;
%                 obj.MaxWallClockTime = srcObj.MaxWallClockTime;
%                 obj.OutputTimesStr = srcObj.OutputTimesStr;
%                 obj.ModelList = srcObj.ModelList;
%             else
%                 StatusOk = false;
%                 Message = 'Could not copy since source and destination SimBiology project filepaths are different.';
%             end
%             
%         end %function
        
        function [Value,MatchIndex] = getInvalidActiveVariantNames(obj)
            MatchIndex = ~ismember(obj.ActiveVariantNames,obj.VariantNames);
            Value = obj.ActiveVariantNames(MatchIndex);
        end %function
        
        function [Value,MatchIndex] = getInvalidActiveDoseNames(obj)
            MatchIndex = ~ismember(obj.ActiveDoseNames,obj.DoseNames);
            Value = obj.ActiveDoseNames(MatchIndex);
        end %function
        
        function [Value,MatchIndex] = getInvalidActiveSpeciesNames(obj)
            MatchIndex = ~ismember(obj.ActiveSpeciesNames,obj.SpeciesNames);
            Value = obj.ActiveSpeciesNames(MatchIndex);
        end %function
        
        function [Value,MatchIndex] = getInvalidInactiveRuleNames(obj)
            MatchIndex = ~ismember(obj.InactiveRuleNames,obj.RuleNames);
            Value = obj.InactiveRuleNames(MatchIndex);
        end %function
        
        function [Value,MatchIndex] = getInvalidInactiveReactionNames(obj)
            MatchIndex = ~ismember(obj.InactiveReactionNames,obj.ReactionNames);
            Value = obj.InactiveReactionNames(MatchIndex);
        end %function
        
        function [statusOK, Message] = update(obj)
            statusOK = true;
            Message = '';
            % check that the model is current and rebuild if necessary
            if ~obj.checkExportedModelCurrent()
                [statusOK, Message] = obj.constructModel();
                if ~statusOK
                    return
                end            
            end        
        end
    end
    
    %% Get Methods
    methods
        
        function Value = get.ModelObj(obj)
            % NOTE: importModel (obj.ModelObj_) is quick if NOT stale (all
            % timestamp validation occurs inside
            importModel(obj,obj.FilePath,obj.ModelName);
            Value = obj.ModelObj_;
        end
        
        function Value = get.ConfigSet(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.ConfigSet;
            else
                Value = [];
            end
        end
        
        function Value = get.VariantNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.VariantNames;
            else
                Value = cell(0,1);
            end
        end % get.VariantNames
        
        function Value = get.DoseNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.DoseNames;
            else
                Value = cell(0,1);
            end
        end % get.DoseNames
        
        function Value = get.SpeciesNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.SpeciesNames;
            else
                Value = cell(0,1);
            end
        end % get.SpeciesNames
        
        function Value = get.ParameterNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.ParameterNames;
            else
                Value = cell(0,1);
            end
        end % get.ParameterNames       
        
        function Value = get.ParameterValues(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.ParameterValues;
            else
                Value = cell(0,1);
            end
        end % get.ParameterNames          
        
        function Value = get.RuleNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.RuleNames;
            else
                Value = cell(0,1);
            end
        end % get.RuleNames
        
        function Value = get.ReactionNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.ReactionNames;
            else
                Value = cell(0,1);
            end
        end % get.ReactionNames
        
        function Value = get.OutputTimes(obj)
            Value = eval(obj.OutputTimesStr);
            
%            if ~isempty(obj.ModelObj)
%                 Value = obj.ModelObj.OutputTimes;
%                 Value = obj.VarModelObj.
%             else
%                 Value = [];
%            end
        end % get.OutputTimes
        
        function Value = get.DefaultOutputTimes(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.DefaultOutputTimes;
            else
                Value = [];
            end
        end % get.DefaultOutputTimes
        
        function Value = get.DefaultMaxWallClockTime(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.ParameterNames;
            else
                Value = 60;
            end
        end % get.DefaultMaxWallClockTime
        
    end %methods
    
    %% Set Methods
    methods
        
        function set.ActiveVariantNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.ActiveVariantNames = Value;
        end % set.ActiveVariantNames
        
        function set.ActiveDoseNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.ActiveDoseNames = Value;
        end % set.ActiveDoseNames
        
        function set.ActiveSpeciesNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.ActiveSpeciesNames = Value;
        end % set.ActiveSpeciesNames
        
        function set.InactiveRuleNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.InactiveRuleNames = Value;
        end % set.InactiveRuleNames
        
        function set.InactiveReactionNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.InactiveReactionNames = Value;
        end % set.InactiveReactionNames
        
        function set.OutputTimesStr(obj,Value)
            validateattributes(Value,{'char'},{});
            validateattributes(str2num(Value),{'numeric'},{});
            obj.OutputTimesStr = Value;
        end % set.OutputTimesStr
        
        function set.MaxWallClockTime(obj,Value)
            if ~isempty(Value)
                validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'});
            end
            obj.MaxWallClockTime = Value;
        end % set.MaxWallClockTime
        
        function set.RunToSteadyState(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.RunToSteadyState = Value;
        end % set.RunToSteadyState
        
        function set.TimeToSteadyState(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'});
            obj.TimeToSteadyState = Value;
        end % set.TimeToSteadyState
        
        function set.Resample(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.Resample = Value;
        end % set.Resample
        
    end %methods
    
end %classdef
