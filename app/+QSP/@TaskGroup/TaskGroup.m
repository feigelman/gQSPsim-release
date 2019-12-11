classdef TaskGroup < QSP.abstract.BaseProps
    % TaskGroup - Defines a TaskGroup object
    % ---------------------------------------------------------------------
    % Abstract: This object defines TaskGroup
    %
    % Syntax:
    %           obj = QSP.TaskGroup
    %           obj = QSP.TaskGroup('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.TaskGroup Properties:
    %
    %
    % QSP.TaskGroup Methods:
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
        TaskName = ''
        GroupID = ''
    end
        
    %% Constructor
    methods
        function obj = TaskGroup(varargin)
            % TaskGroup - Constructor for QSP.TaskGroup
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.TaskGroup object.
            %
            % Syntax:
            %           obj = QSP.TaskGroup('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.TaskGroup object
            %
            % Example:
            %    aObj = QSP.TaskGroup();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = TaskGroup(varargin)
        
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
    end
        
    
    %% Set Methods
    methods
        
        function set.TaskName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.TaskName = Value;
        end
        
        function set.GroupID(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.GroupID = Value;
        end
        
    end %methods
    
end %classdef
