classdef TaskVirtualPopulation < QSP.abstract.BaseProps
    % TaskVirtualPopulation - Defines a TaskVirtualPopulation object
    % ---------------------------------------------------------------------
    % Abstract: This object defines TaskVirtualPopulation
    %
    % Syntax:
    %           obj = QSP.TaskVirtualPopulation
    %           obj = QSP.TaskVirtualPopulation('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.TaskVirtualPopulation Properties:
    %
    %
    % QSP.TaskVirtualPopulation Methods:
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
        VPopName = ''
        Group=''
        MATFileName = ''
    end
        
    %% Constructor
    methods
        function obj = TaskVirtualPopulation(varargin)
            % TaskVirtualPopulation - Constructor for QSP.TaskVirtualPopulation
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.TaskVirtualPopulation object.
            %
            % Syntax:
            %           obj = QSP.TaskVirtualPopulation('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.TaskVirtualPopulation object
            %
            % Example:
            %    aObj = QSP.TaskVirtualPopulation();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = TaskVirtualPopulation(varargin)
        
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
        
        function set.VPopName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.VPopName = Value;
        end
        
    end %methods
    
end %classdef
