classdef NavigationEventData < event.EventData
    properties
        Name = ''        
    end
    
    methods
        function data = NavigationEventData(varargin)
            p = inputParser;
            p.KeepUnmatched = false;
            
            p.addParameter('Name','',@ischar);
            
            p.parse(varargin{:});
            
            data.Name = p.Results.Name;            
        end % function
    end % methods
end % classdef