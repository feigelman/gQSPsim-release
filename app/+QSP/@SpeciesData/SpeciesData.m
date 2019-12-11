classdef SpeciesData < QSP.abstract.BaseProps
    % SpeciesData - Defines a SpeciesData object
    % ---------------------------------------------------------------------
    % Abstract: This object defines SpeciesData
    %
    % Syntax:
    %           obj = QSP.SpeciesData
    %           obj = QSP.SpeciesData('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.SpeciesData Properties:
    %
    %
    % QSP.SpeciesData Methods:
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
        SpeciesName = ''
        DataName = ''
        FunctionExpression = ''    
        ObjectiveName = 'defaultObj'
    end
    
    %% Constructor
    methods
        function obj = SpeciesData(varargin)
            % SpeciesData - Constructor for QSP.SpeciesData
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.SpeciesData object.
            %
            % Syntax:
            %           obj = QSP.SpeciesData('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.SpeciesData object
            %
            % Example:
            %    aObj = QSP.SpeciesData();
            
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
        
        function Value = evaluate(obj,Data)
            if isempty(Data)
                Value = [];
                return
            end
            Value = zeros(size(Data));
            lambda = str2func(['@(x)' obj.FunctionExpression]);
            for k=1:size(Data,2)
                Value(:,k) = feval(lambda,Data(:,k));
            end
        end %function
        
        function clearData(obj)
            
        end
    end
    
    
    %% Set Methods
    methods
        
        function set.SpeciesName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.SpeciesName = Value;
        end
        
        function set.DataName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.DataName = Value;
        end
        
        function set.FunctionExpression(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.FunctionExpression = Value;
        end
        
    end %methods
    
end %classdef
