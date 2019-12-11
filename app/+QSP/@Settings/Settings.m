classdef Settings < matlab.mixin.SetGet & uix.mixin.AssignPVPairs & uix.mixin.HasTreeReference
    % Settings - Defines a Settings object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Settings
    %
    % Syntax:
    %           obj = QSP.Settings
    %           obj = QSP.Settings('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Settings Properties:
    %
    %   Task - 
    %
    %   VirtualPopulation - 
    %
    %   Parameters - 
    %
    %   OptimizationData - 
    %
    %   VirtualPopulationData - 
    %
    % QSP.Settings Methods:
    %
    %    
    %
    
    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 319 $  $Date: 2016-09-10 21:44:01 -0400 (Sat, 10 Sep 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        Session = QSP.Session.empty(1,0)
        Task = QSP.Task.empty(1,0)
        VirtualPopulation = QSP.VirtualPopulation.empty(1,0)
        Parameters = QSP.Parameters.empty(1,0)
        OptimizationData = QSP.OptimizationData.empty(1,0)
        VirtualPopulationData = QSP.VirtualPopulationData.empty(1,0)
        VirtualPopulationGenerationData = QSP.VirtualPopulationGenerationData.empty(1,0)
    end
    
    %% Properties (Transient)
    properties (Transient=true)
        Model = QSP.Model.empty(1,0)
    end
    
    %% Properties
    properties
        LineStyleMap = {...
            '-',...
            '--',...
            ':',...
            '-.',...
            }
        LineMarkerMap = {
            '+',...
            'o',...
            '*',...
            '.',...
            'x',...
            'square',...
            'diamond',...
            'v',...
            '^',...
            '>',...
            '<',...
            'pentagram',...
            'hexagram',...
            };
    end
   
    %% Constructor
    methods
        function obj = Settings(varargin)
            % Settings - Constructor for QSP.Settings
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Settings object.
            %
            % Syntax:
            %           obj = QSP.Settings('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Settings object
            %
            % Example:
            %    aObj = QSP.Settings();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = Settings(varargin)
        
    end %methods
    
    
    %% Methods
    methods
        
        function obj = getParametersWithName(obj, Name)
            
            matchIdx = strcmp(Name, {obj.Parameters.Name});
            obj = obj.Parameters(matchIdx);
            
        end
        
       function obj = getVpopWithName(obj, Name)
            
            matchIdx = strcmp(Name, {obj.VirtualPopulation.Name});
            obj = obj.VirtualPopulation(matchIdx);
            
        end     
        
        function vObj = getValidSelectedVPops(obj,ItemNames)
            % Get selected VPops that are valid
            
            AllNames = {obj.VirtualPopulation.Name};
            % Make unique
            if iscell(ItemNames)
                ItemNames = unique(ItemNames);
            end
            [~,Loc] = ismember(ItemNames,AllNames);
            Loc(Loc == 0) = [];
            
            vObj = QSP.VirtualPopulation.empty(0,1);
            if ~isempty(Loc)                
                for idx = Loc
                    ThisStatusOk = validate(obj.VirtualPopulation(idx),false);
                    if ThisStatusOk
                        vObj = [vObj,obj.VirtualPopulation(idx)]; %#ok<AGROW>
                    end
                end
            end
            
        end %function
        
        function tObj = getValidSelectedTasks(obj,ItemNames)
            % Get selected tasks that are valid
            
            AllNames = {obj.Task.Name};
            % Make unique
            if iscell(ItemNames)
                ItemNames = unique(ItemNames);
            end
            [~,Loc] = ismember(ItemNames,AllNames);
            Loc(Loc == 0) = [];
            
            tObj = QSP.Task.empty(0,1);
            if ~isempty(Loc)
                for idx = Loc
                    ThisStatusOk = validate(obj.Task(idx),false);
                    if ThisStatusOk
                        tObj = [tObj,obj.Task(idx)]; %#ok<AGROW>
                    end
                end
            end
        end %function  
        
        function SpeciesList = getSpeciesFromValidSelectedTasks(obj,ItemTaskNames)
            % Get union species list from all selected tasks that are valid
            
            AllTaskNames = {obj.Task.Name};
            [~,Loc] = ismember(ItemTaskNames,AllTaskNames);
            Loc(Loc == 0) = [];
            % Get all active species names from VALID Tasks specified in Optimization
            % Items
            if ~isempty(Loc)
                ValidActiveSpeciesNames = {};
                for idx = Loc
                    ThisStatusOk = validate(obj.Task(idx),false);
                    if ThisStatusOk
                        ActiveSpeciesNames = obj.Task(idx).ActiveSpeciesNames;
                        ValidActiveSpeciesNames = vertcat(ValidActiveSpeciesNames,ActiveSpeciesNames(:)); %#ok<AGROW>
                    end
                end
                SpeciesList = unique(ValidActiveSpeciesNames);
            else
                SpeciesList = {};
            end
        end
        
    end 
    
    
    %% Get/Set Methods
    methods
      
        function set.LineStyleMap(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.LineStyleMap = Value;
        end
        
    end %methods
    
end %classdef
