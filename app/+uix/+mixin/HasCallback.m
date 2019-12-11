classdef (Abstract) HasCallback < handle
    % HasCallback - Mixin to provide a callback for a widget
    % ---------------------------------------------------------------------
    % This mixin class provides a callback for a widget.
    %
    % The class must inherit this object to access the Callback property
    % and callCallback method. The callback must be stored as a function
    % handle, such as:
    %
    %   obj.Callback = @(src,evt)foo(obj,evt);
    %
    % or if you do not want to provide event data:
    %
    %   obj.Callback = @(src,evt)foo(obj);
    %
    % Call the callback with custom event data like this:
    %
    %   evt = struct('Source',obj,'Interaction','AddButtonPress');
    %   obj.Callback(obj,evt);
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 1384 $  $Date: 2016-07-08 10:13:44 -0400 (Fri, 08 Jul 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet=true)
        Callback function_handle = function_handle.empty(0,1)
    end
    
    
    %% Methods
    
    methods (Access=protected)
        
        function callCallback( obj, eventdata )
            % Call the function handle based callback
            if ~isempty(obj.Callback)
                if nargin>1
                    obj.Callback(obj, eventdata);
                else
                    obj.Callback(obj);
                end
            end
        end %function
        
    end %methods
    
    
    %% Get/set methods
    methods
        
        % Callback
        function set.Callback(obj,value)
            if isempty(value)
                obj.Callback = function_handle.empty(0,1);
            else
                obj.Callback = value;
            end
            
        end
        
    end
    
end %classdef