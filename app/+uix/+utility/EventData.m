classdef EventData < event.EventData & dynamicprops & ...
        matlab.io.internal.mixin.HasPropertiesAsNVPairs
    % EventData - class to provide eventdata to listeners
    % ---------------------------------------------------------------------
    % Abstract:
    %
    % Syntax:
    %           obj = uix.utility.EventData()
    %           obj = uix.utility.EventData('Property','Value',...)
    %
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 1687 $  $Date: 2017-07-17 16:50:12 -0400 (Mon, 17 Jul 2017) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        Interaction char
    end %properties
    
    
    %% Constructor / destructor
    methods
        function obj = EventData(varargin)
            
            % Parse inputs
            [~,remArgs] = obj.parseInputs(varargin);
            
            % Add dynamic props
            dynProps = fieldnames(remArgs);
            for idx=1:numel(dynProps)
                thisProp = dynProps{idx};
                thisValue = remArgs.(thisProp);
                obj.addprop(thisProp);
                obj.(thisProp) = thisValue;
            end
            
        end %constructor
    end %methods
    
end % classdef