classdef VirtualPopulationData < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % VirtualPopulationData - Defines a VirtualPopulationData object
    % ---------------------------------------------------------------------
    % Abstract: This object defines VirtualPopulationData
    %
    % Syntax:
    %           obj = QSP.VirtualPopulationData
    %           obj = QSP.VirtualPopulationData('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.VirtualPopulationData Properties:
    %
    %
    % QSP.VirtualPopulationData Methods:
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
    
    %% Constructor
    methods
        function obj = VirtualPopulationData(varargin)
            % VirtualPopulationData - Constructor for QSP.VirtualPopulationData
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.VirtualPopulationData object.
            %
            % Syntax:
            %           obj = QSP.VirtualPopulationData('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.VirtualPopulationData object
            %
            % Example:
            %    aObj = QSP.VirtualPopulationData();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = VirtualPopulationData(varargin)
        
    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTimeStr;
                'Description',obj.Description;       
                'File Name',obj.RelativeFilePath;                         
                };
        end
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid) %#ok<INUSD>
            
            StatusOK = true;
            Message = sprintf('Acceptance Criteria: %s\n%s\n',obj.Name,repmat('-',1,75));
            if  obj.Session.UseParallel && ~isempty(getCurrentTask())
                return
            end
            
            if isdir(obj.FilePath) || ~exist(obj.FilePath,'file')
                StatusOK = false;
                Message = sprintf('%s\n* Virtual Population data file "%s" is invalid or does not exist',Message,obj.FilePath);
            else
                % Import data
                [ThisStatusOk,ThisMessage,Header] = importData(obj,obj.FilePath);
                if ~ThisStatusOk
                    Message = sprintf('%s\n* Error loading data "%s". %s\n',Message,obj.FilePath,ThisMessage);
                    StatusOK = false;
                elseif ~all(ismember({'GROUP','TIME','DATA','LB','UB'}, upper(Header)))
                    % Validate headers
                    Message = sprintf('%s\n* Acceptance criteria file contains incorrect headers. It must contain the columns Group, Time, Data, LB, and UB.\n\n %s\n',ThisMessage);
                    StatusOK = false;
                end
                
            end
            
        end
        
        function clearData(obj)
        end
    end
    
    %% Methods
    methods
        function [StatusOk,Message,Header,Data] = importData(obj,DataFilePath)            
            % Defaults
            StatusOk = true;
            Message = '';            
            
            % Load from file
            try
                Raw = readtable(DataFilePath);
                Raw = [Raw.Properties.VariableNames;table2cell(Raw)];
            catch ME
                Raw = {};
                StatusOk = false;
                Message = sprintf('Unable to read from Excel file:\n\n%s',ME.message);
            end
            
            if size(Raw,1) > 1
                Header = Raw(1,:);
                Data = Raw(2:end,:);
            else
                Header = {};
                Data = {};
            end
            obj.FilePath = DataFilePath;
            
        end %function
        
    end
    
end %classdef
