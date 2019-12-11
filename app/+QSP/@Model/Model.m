classdef Model < QSP.abstract.BaseProps
    % Model - Defines a Model object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Model
    %
    % Syntax:
    %           obj = QSP.Model
    %           obj = QSP.Model('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Model Properties:
    %
    %
    % QSP.Model Methods:
    %
    %
    %
    
    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 328 $  $Date: 2016-09-23 17:49:09 -0400 (Fri, 23 Sep 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties                
    end
    
    %% Protected Transient Properties
    properties (GetAccess=public, SetAccess=protected, Transient = true)
        mObj % SimBiology Model
        ModelName = ''
        
        ModelTimeStamp = [] % datenum
        
        ModelList = {}
        MaxWallClockTime = []
        OutputTimesStr = ''
    end    
    
    %% Dependent Properties
    properties(SetAccess=protected,Dependent=true)
        IsStale
        
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
        function obj = Model(varargin)
            % SpeciesData - Constructor for QSP.Model
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Model object.
            %
            % Syntax:
            %           obj = QSP.Model('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Model object
            %
            % Example:
            %    aObj = QSP.Model();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = SpeciesData(varargin)
        
    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            Summary = {};
            
        end %function
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid)
            
            StatusOK = true;
            Message = '';
            
        end %function
        
        function clearData(obj)
            
        end
    end %methods
    
    
    %% Protected Methods
    methods (Access=protected)
        function copyProperty(obj,Property,Value)
            if isprop(obj,Property)
                obj.(Property) = Value;
            end
        end %function
    end
        
    
    %% Methods
    methods
        
        function ModelNames = getModelList(obj)
            % Check timestamp - make sure model is older than the task's
            % LastSavedTime
            
            ModelNames = {};
            % If ModelList is empty or model was saved after the task was saved
            if ~isempty(obj.FilePath) && ~isdir(obj.FilePath) && exist(obj.FilePath,'file') && ...
                    (isempty(obj.ModelList) || obj.IsStale) 
                try
                    AllModels = sbioloadproject(obj.FilePath);
                catch
                    AllModels = [];
                end     
                if ~isempty(AllModels) && isstruct(AllModels)
                    AllModels = cell2mat(struct2cell(AllModels));
                    m1 = sbioselect(AllModels,'type','sbiomodel');
                    if ~isempty(m1)
                        ModelNames = get(m1,'Name');
                    end
                end
            elseif ~isempty(obj.FilePath) && ~isdir(obj.FilePath) && exist(obj.FilePath,'file')
                ModelNames = obj.ModelList;            
            end
            
        end %function
        
        function [StatusOk,Message] = importModel(obj,ProjectPath,ModelName)
            
            % Defaults
            StatusOk = true;
            Message = '';
            warning('off', 'SimBiology:sbioloadproject:Version')
            
            % Clear ModelTimeStamp only if paths changed => this triggers
            % IsStale = true
            if ~isequal(obj.FilePath,ProjectPath)                
                obj.ModelTimeStamp = [];
            end
            % Store path
            obj.FilePath = ProjectPath;            
            
            % Return if NOT stale
            if ~obj.IsStale
                return;
            end
            
            % Continue IF stale
            % Load project
            try
                AllModels = sbioloadproject(ProjectPath);
            catch ME
                StatusOk = false;
                Message = ME.message;
                obj.mObj = [];
                obj.ModelName = '';
                obj.ModelList = {};
                obj.MaxWallClockTime = [];
                obj.OutputTimesStr = '';
                obj.ModelTimeStamp = [];
            end
            
            if StatusOk
                AllModels = cell2mat(struct2cell(AllModels));
                m1 = sbioselect(AllModels,'type','sbiomodel');
                
                if isempty(m1)
                    StatusOk = false;
                    Message = sprintf('Model "%s" not found in project',ModelName);
                    obj.mObj = [];
                    obj.ModelName = '';
                    obj.ModelList = {};
                    obj.MaxWallClockTime = [];
                    obj.OutputTimesStr = '';
                    obj.ModelTimeStamp = [];
                else
                    ThisModelList = get(m1, 'Name');
                    % Filter according to ModelName
                    if ~isempty(ModelName) && any(strcmpi(ThisModelList,ModelName))
                        m1 = m1(strcmpi(ThisModelList,ModelName));
                        %                     m1 = sbioselect(AllModels,'Name',ModelName,'type','sbiomodel');
                    else
                        m1 = m1(1);
                    end
                    ModelName = m1.Name;
                
                    obj.mObj = m1;
                    obj.ModelName = ModelName;
                    obj.ModelList = ThisModelList;
                    if isempty(obj.ModelTimeStamp)
                        obj.MaxWallClockTime = m1.ConfigSet.MaximumWallClock;
                    end
                    % Update ModelTimeStamp
                    obj.ModelTimeStamp = now;                    
                    
                    if isempty(obj.OutputTimesStr)
                        % Use StopTime to compute
                        StopTime = obj.ConfigSet.StopTime;
                        % Update OutputTimesStr and actual value
                        obj.OutputTimesStr = sprintf('[0:%2f/100:%2f]',StopTime,StopTime);
                    end
                end %if
                
                
            end %if
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function Value = get.IsStale(obj)
            
            % Default: Stale
            Value = true;
            
            FileInfo = dir(obj.FilePath);
            if ~isempty(FileInfo)
                % If model was imported AFTER model filepath was saved => OK
                % ModelTimeStamp must be valid (numeric) and file must
                % exist to be FALSE (not stale)
                if ~isempty(obj.ModelTimeStamp) && obj.ModelTimeStamp > FileInfo.datenum
                    Value = false;
                end
            end
        end %function
        
        function Value = get.ConfigSet(obj)
            if ~isempty(obj.mObj)
                Value = getconfigset(obj.mObj,'active');
            else
                Value = [];
            end
        end
        
        function Value = get.VariantNames(obj)
            if ~isempty(obj.mObj)
                Value = getvariant(obj.mObj);
                Value = get(Value,'Name');
                if isempty(Value)
                    Value = cell(0,1);
                end
            else
                Value = cell(0,1);
            end
        end % get.VariantNames
        
        function Value = get.DoseNames(obj)
            if ~isempty(obj.mObj)
                Value = getdose(obj.mObj);
                Value = get(Value,'Name');
                if isempty(Value)
                    Value = cell(0,1);
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.DoseNames
        
        function Value = get.SpeciesNames(obj)
            if ~isempty(obj.mObj)
                Value = sbioselect(obj.mObj, 'Type', 'Species');
                Value = get(Value,'Name');
                if isempty(Value)
                    Value = cell(0,1);
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.SpeciesNames
        
        function Value = get.ParameterNames(obj)
            if ~isempty(obj.mObj)
                Value = sbioselect(obj.mObj,'Type','Parameter');                
                Value = get(Value,'Name');
                if isempty(Value)
                    Value = cell(0,1);
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.ParameterNames       
        
        function Value = get.ParameterValues(obj)
            if ~isempty(obj.mObj)
                Value = sbioselect(obj.mObj,'Type','Parameter');                                
                Value = get(Value,'Value');
                if isempty(Value)
                    Value = cell(0,1);
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.ParameterNames          
        
        function Value = get.RuleNames(obj)
            if ~isempty(obj.mObj)
                Value = sbioselect(obj.mObj, 'Type', 'Rule');
                Value = get(Value,'Rule');
                if isempty(Value)
                    Value = cell(0,1);                
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.RuleNames
        
        function Value = get.ReactionNames(obj)
            if ~isempty(obj.mObj)
                Value = sbioselect(obj.mObj, 'Type', 'Reaction');                
                Value = get(Value,'Reaction');
                if isempty(Value)
                    Value = cell(0,1);                
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.ReactionNames
        
        function Value = get.OutputTimes(obj)
            if isempty(obj.OutputTimesStr) && ~isempty(obj.mObj) && ~isempty(obj.ConfigSet)
                
                % Use StopTime to compute
                StopTime = obj.ConfigSet.StopTime;
                
                % Update OutputTimesStr and actual value
                obj.OutputTimesStr = sprintf('[0:%2f/100:%2f]',StopTime,StopTime);
                Value = 0:StopTime/100:StopTime;
                
            elseif isempty(obj.OutputTimesStr)
                % Use the default output times from the model if possible
                Value = obj.DefaultOutputTimes;
                
            else
                Value = evalin('base',obj.OutputTimesStr);
            end
            
        end % get.OutputTimes
        
        function Value = get.DefaultOutputTimes(obj)
            if ~isempty(obj.mObj) && ~isempty(obj.ConfigSet)
                Value = get(obj.ConfigSet.SolverOptions,'OutputTimes');
            else
                Value = [];
            end
        end % get.DefaultOutputTimes
        
        function Value = get.DefaultMaxWallClockTime(obj)
            if ~isempty(obj.mObj) && ~isempty(obj.ConfigSet)
                Value = obj.ConfigSet.MaximumWallClock;
            else
                Value = 60;
            end
        end % get.DefaultMaxWallClockTime
          
        function set.ModelName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.ModelName = Value;
        end
        
    end %methods
    
end %classdef
