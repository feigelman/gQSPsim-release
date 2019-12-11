classdef (Abstract) BasicBaseProps < matlab.mixin.SetGet & uix.mixin.AssignPVPairs
    % BaseProps  A base class for the base properties for the backend
    % ---------------------------------------------------------------------
    % This is an abstract base class and cannot be instantiated.
    % It provides the following properties for its descendents:
    %     * Name
    %     * RelativeFilePath
    %     * Description
    %     * LastUpdate
    %
    % uix.abstract.BaseProps inherits properties and methods from
    % matlab.mixin.SetGet & uix.mixin.AssignPVPairs, and adds the following:
    %
    % uix.abstract.BaseProps Properties:
    %
    %     Name - Name of the object
    %
    %     RelativeFilePath - Path to the corresponding file
    %
    %     Description - Description of the usage
    %
    %     LastUpdate - The timestamp of the last property updated
    %
    %
    % Methods you must define in subclasses:
    %
    %   getSummary, validate
    %
    
    %   Copyright 2008-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $
    %   $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        Name = ''    % Name
        Description = '' % Description
    end
    
    %% Dependent properties
    properties (Dependent=true)
        LastSavedTimeStr
    end
    
    %% Protected Properties
    properties (SetAccess=protected)
        LastSavedTime = [] % Time at which the view was last saved        
        LastValidatedTime = ''
    end
    
    %% Public methods
    methods
        function obj = BasicBaseProps( varargin )
            
            % Assign PV pairs to properties
            obj.assignPVPairs(varargin{:});
            
        end % constructor       
                
    end % Public methods
    
    %% Abstract methods
    methods( Abstract = true, Access = 'public' )
        
        Summary = getSummary(obj) % Cell array of strings (nx2) containing summary of obj; First column contains group name and second column contains value as string
        
        [StatusOK, Message] = validate(obj,FlagRemoveInvalid) % Validate current properties
        
        clearData(obj) % remove all data after copying
    end % abstract methods
    
    %% Methods
    methods
        
        function updateLastSavedTime(obj)
            
            obj.LastSavedTime = now;
            
        end %function        
        
        function Value = isPublicPropsEqual(obj,secondObj)
            % Initialize
            Value = true;
            % TODO: Enhance to look at nested objects (Sim, Optim, VPopGen)
            
            if ~isequal(class(obj),class(secondObj))
                Value = false;
            else
                mc = metaclass(obj);
                pList = mc.PropertyList;
                isPublicProp = ...
                    strcmp({pList.SetAccess}, 'public') ...
                    & strcmp({pList.GetAccess}, 'public');
                isOkProp = isPublicProp & ...
                    ~([pList.Constant] | [pList.Dependent] | [pList.NonCopyable] | [pList.Transient]);
                
                % Filter props to compare
                pList = pList(isOkProp);
                
                % Iterate through pList
                for index = 1:numel(pList)
                    if ~isprop(secondObj,(pList(index).Name))
                        Value = false;
                        break;
                    else
                        if ~isequal(obj.(pList(index).Name),secondObj.(pList(index).Name))
                            Value = false;
                            break;
                        end
                        
                    end
                end
            end
            
        end %function
        
    end % methods
    
    %% Get/Set methods
    methods
        
        function set.Name(obj,value)
            validateattributes(value,{'char'},{})
            obj.Name = value;
        end
        
        function set.Description(obj,value)
            validateattributes(value,{'char'},{})
            obj.Description = value;
        end
        
        function set.LastSavedTime(obj,value)    
            if ischar(value)
                if isempty(value)
                    value = [];
                else
                    value = datenum(value);
                end
            end
            obj.LastSavedTime = value;
        end
        
        function value = get.LastSavedTimeStr(obj)
            value = datestr(obj.LastSavedTime);
        end        
        
    end
    
end % classdef