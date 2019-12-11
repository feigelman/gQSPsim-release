classdef Profile < QSP.abstract.BaseProps
    % Profile - Defines a complete Profile
    % ---------------------------------------------------------------------
    % Abstract: This object defines a complete Profile setup
    %
    % Syntax:
    %           obj = QSP.Profile
    %           obj = QSP.Profile('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Profile Properties:
    %
    %    Description - Description of item
    %
    %    Show - Flag to toggle visibility on/off
    %
    %
    %
    % QSP.Profile Methods:
    %
    
    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 421 $  $Date: 2017-12-07 15:07:04 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties        
        Source = ''
        Show = true
        Values = cell(0,2)
%         RefreshFlag = true
    end
    
    
    %% Constructor
    methods
        function obj = Profile(varargin)
            % Profile - Constructor for QSP.Profile
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Profile object.
            %
            % Syntax:
            %           obj = QSP.Profile('Parameter1',Value1,...)
            %
            % Inputs:
            %           Profile-value pairs
            %
            % Outputs:
            %           obj - QSP.Profile object
            %
            % Example:
            %    aObj = QSP.Profile();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = Profile(varargin)
        
    end %methods
    
    
    %% Methods
    methods
        
        function Summary = getSummary(obj)
            
            Summary = {                
                obj.Show,...
                obj.Source,...
                obj.Description,...
                };            
            
        end %function
        
        function [StatusOK, Message] = validate(obj,~)
            StatusOK = true;
            Message = '';
            % Do nothing
        end
        
        function clearData(obj)
        end
    end
    
    
    %% Set Methods
    methods
        
        function set.Source(obj,Value)
            validateattributes(Value,{'char'},{})
            obj.Source = Value;
        end
        
        function set.Show(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.Show = Value;
        end
        
%         function set.Values(obj,Value)
%             validateattributes(Value,{'cell'},{'size',[nan 2]})
%             obj.Values = Value;
%         end
        
    end %methods
end %classdef
