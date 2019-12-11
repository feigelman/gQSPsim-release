classdef VirtualPopulationGenerationData < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % VirtualPopulationGenerationData - Defines a VirtualPopulationGenerationData object
    % ---------------------------------------------------------------------
    % Abstract: This object defines VirtualPopulationGenerationData
    %
    % Syntax:
    %           obj = QSP.VirtualPopulationGenerationData
    %           obj = QSP.VirtualPopulationGenerationData('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.VirtualPopulationGenerationData Properties:
    %
    %
    % QSP.VirtualPopulationGenerationData Methods:
    %
    %
    %
    
    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 322 $  $Date: 2016-09-11 23:01:33 -0400 (Sun, 11 Sep 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Public Properties
    
    %% Constructor
    methods
        function obj = VirtualPopulationGenerationData(varargin)
            % VirtualPopulationGenerationData - Constructor for QSP.VirtualPopulationGenerationData
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.VirtualPopulationGenerationData object.
            %
            % Syntax:
            %           obj = QSP.VirtualPopulationGenerationData('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.VirtualPopulationGenerationData object
            %
            % Example:
            %    aObj = QSP.VirtualPopulationGenerationData();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = VirtualPopulationGenerationData(varargin)
        
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
        
        function [StatusOK, Message,VpopGenHeader] = validate(obj,FlagRemoveInvalid) %#ok<INUSD>
            
            StatusOK = true;
            Message = sprintf('Virtual population generation Data: %s\n%s\n',obj.Name,repmat('-',1,75));
            VpopGenHeader = {};
            
            if isdir(obj.FilePath) || ~exist(obj.FilePath,'file')
                StatusOK = false;
                Message = sprintf('%s\n* Virtual population generation data file "%s" is invalid or does not exist',Message,obj.FilePath);
            else
                DestFormat = 'wide';
                % Import data
                [ThisStatusOk,ThisMessage,VpopGenHeader] = importData(obj,obj.FilePath,DestFormat);
                if ~ThisStatusOk
                    Message = sprintf('%s\n* Error loading data "%s". %s\n',Message,obj.FilePath,ThisMessage);
                end
                                
                if ~all(ismember(upper(VpopGenHeader), {'GROUP', 'TIME', 'SPECIES', 'TYPE', 'VALUE1', 'VALUE2'}))
                    StatusOK = false;
                    Message = sprintf('%s\n* Vpop generation data file must contain the columns Group, Time, Species, Type, Value1, and Value2\n', Message);
                end                
            end
            
        end
        
        function clearData(obj)
        end
    end
    
    %% Methods
    methods
        function [StatusOk,Message,Header,Data] = importData(obj,DataFilePath,varargin)            
            
            % Defaults
            StatusOk = true;
            Message = '';
            
            try
                Table = readtable(DataFilePath);                
            catch ME
                Table = table;
                StatusOk = false;
                Message = sprintf('Unable to read from Excel file:\n\n%s',ME.message);
            end
            
            if ~isempty(Table)
                Header = Table.Properties.VariableNames;
                Data = table2cell(Table);
               
            else
                Header = {};
                Data = {};
            end
           
            obj.FilePath = DataFilePath;
            
        end %function
        
    end
        
    %% Get/Set Methods
    methods
        
    end %methods
    
end %classdef
