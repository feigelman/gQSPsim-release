classdef MouseEvent < uix.utility.EventData
    % MouseEvent - class to provide eventdata to listeners
    % ---------------------------------------------------------------------
    % Abstract:
    %
    % Syntax:
    %           obj = uix.utility.MouseEvent
    %           obj = uix.utility.MouseEvent('Property','Value',...)
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
        HitObject matlab.graphics.Graphics
        MouseSelection matlab.graphics.Graphics
        Axes matlab.graphics.axis.Axes
        AxesPoint double
        Figure matlab.ui.Figure
        FigurePoint double
        ScreenPoint double
    end %properties
  
    
    %% Constructor / destructor
    methods
        function obj = MouseEvent(varargin)
            obj@uix.utility.EventData(varargin{:});
        end %constructor
    end %methods
    
end % classdef