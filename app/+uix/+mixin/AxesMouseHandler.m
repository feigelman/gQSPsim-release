classdef AxesMouseHandler < handle
    % AxesMouseHandler -
    % ---------------------------------------------------------------------
    % Abstract:
    %
    % Syntax:
    %           obj = AxesMouseHandler
    %           obj = AxesMouseHandler('Property','Value',...)
    %
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 1688 $  $Date: 2017-07-19 11:44:01 -0400 (Wed, 19 Jul 2017) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet)
        EnableMouseHandler logical = true
        ClickableAxes matlab.graphics.axis.Axes
    end
    
    properties (SetAccess=private)
        MouseSelection % matlab.graphics.Graphics
        MouseSelectionType char
        MouseAxes % matlab.graphics.Graphics
        MouseDragDelta  double = nan(1,3) % mouse drag difference
        MousePressPoint double = nan(1,3) % mouse press location
        MouseReleasePoint double = nan(1,3) % mouse press location
    end
    
    properties (Access=private)
        MousePressListener event.listener % mouse press listener
        MouseReleaseListener event.listener % mouse release listener
        MouseMotionListener event.listener % mouse motion listener
        AxesFigureObserver uix.FigureObserver % observer
        AxesFigureListener event.listener % listener
    end
    
    
    
    %% Protected Methods - Override these as needed
    methods (Access = protected)
        
        function onMousePress(obj, evt) %#ok<INUSD>
            
        end %function
        
        
        function onMouseRelease(obj, evt) %#ok<INUSD>
            
        end %function
        
        
        function onMouseDrag(obj, evt) %#ok<INUSD>
            
        end %function
        
    end %methods
    
    
    
    %% Private Methods
    methods (Access=private)
        
        function onMousePress_private(obj,e)
            
            % Was something clicked?
            hitObject = e.HitObject;
            if ~isempty(hitObject)
                
                % What axes does it belong to?
                hitAxes = ancestor(hitObject,'axes');
                if isempty(hitAxes)
                    hitAxes = matlab.graphics.axis.Axes.empty(0,0);
                end
                
                % Is it a monitored axes?
                if any( ismember(hitAxes, obj.ClickableAxes) )
                    
                    % Get the figure and graphics root
                    hitFigure = e.Source;
                    %hitFigure = ancestor(hitObject,'figure');
                    root = groot();
                    
                    % Update data
                    %currentPoint = hitAxes.CurrentPoint(1,:);
                    currentPoint = e.IntersectionPoint;
                    obj.MousePressPoint = currentPoint;
                    obj.MouseReleasePoint = nan(1,3);
                    obj.MouseSelection = hitObject;
                    obj.MouseSelectionType = hitFigure.SelectionType;
                    obj.MouseAxes = hitAxes;
                    
                    % Prepare eventdata
                    evt = uix.utility.MouseEvent(...
                        'Interaction','MousePress',...
                        'MouseSelection',obj.MouseSelection,...
                        'SelectionType',obj.MouseSelectionType,...
                        'HitObject',hitObject,...
                        'Axes',hitAxes,...
                        'AxesPoint',currentPoint,...
                        'MousePressPoint',obj.MousePressPoint,...
                        'Figure',hitFigure,...
                        'FigurePoint',e.Point,...
                        'ScreenPoint',root.PointerLocation);
                    
                    % Call method
                    obj.onMousePress(evt);
                else
                    obj.MousePressPoint = nan(1,3);
                    obj.MouseReleasePoint = nan(1,3);
                    obj.MouseSelection = gobjects(0);
                    obj.MouseSelectionType = '';
                    obj.MouseAxes = gobjects(0);
                end %if any( hitAxes == obj.ClickableAxes )
                
            end %if ~isempty(e.HitObject)
            
        end %function
        
        
        function onMouseRelease_private(obj,e)
            
            % What was hit?
            hitObject = e.HitObject;
            hitAxes = ancestor(hitObject,'axes');
            if isempty(hitAxes)
                hitAxes = matlab.graphics.axis.Axes.empty(0,0);
            end
            
            % Get the figure and graphics root
            hitFigure = e.Source;
            %hitFigure = ancestor(hitObject,'figure');
            root = groot();
            
            % Update data
            %currentPoint = hitAxes.CurrentPoint(1,:);
            currentPoint = e.IntersectionPoint;
            obj.MouseDragDelta = currentPoint - obj.MousePressPoint;
            obj.MouseReleasePoint = currentPoint;
            obj.MouseSelection = hitObject;
            obj.MouseAxes = hitAxes;
            
            % Prepare eventdata
            evt = uix.utility.MouseEvent(...
                'Interaction','MouseRelease',...
                'MouseSelection',obj.MouseSelection,...
                'SelectionType',obj.MouseSelectionType,...
                'HitObject',hitObject,...
                'Axes',hitAxes,...
                'AxesPoint',currentPoint,...
                'MousePressPoint',obj.MousePressPoint,...
                'MouseReleasePoint',obj.MouseReleasePoint,...
                'MouseDragDelta',obj.MouseDragDelta,...
                'Figure',hitFigure,...
                'FigurePoint',e.Point,...
                'ScreenPoint',root.PointerLocation);
            
            % Call method
            obj.onMouseRelease(evt);
            
            % Now set properties back to defaults
            obj.MousePressPoint = nan(1,3);
            obj.MouseReleasePoint = nan(1,3);
            obj.MouseSelection = gobjects(0);
            obj.MouseSelectionType = '';
            obj.MouseAxes = hitAxes;
            
        end %function
        
        
        function onMouseMotion_private(obj,e)
            
            % Is something being dragged?
            if ~isempty(obj.MouseSelection)
                
                % What was hit?
                hitObject = e.HitObject;
                hitAxes = ancestor(hitObject,'axes');
                
                % Is it the current axes?
                if any( ismember(hitAxes, obj.MouseAxes) )
                    
                    % Get the figure and graphics root
                    hitFigure = e.Source;
                    %hitFigure = ancestor(hitObject,'figure');
                    root = groot();
                    
                    % Update data
                    %currentPoint = hitAxes.CurrentPoint(1,:);
                    currentPoint = e.IntersectionPoint;
                    obj.MouseDragDelta = currentPoint - obj.MousePressPoint;
                    obj.MouseSelection = hitObject;
                    obj.MouseAxes = hitAxes;
                    
                    % Prepare eventdata
                    evt = uix.utility.MouseEvent(...
                        'Interaction','MouseDrag',...
                        'MouseSelection',obj.MouseSelection,...
                        'SelectionType',obj.MouseSelectionType,...
                        'HitObject',hitObject,...
                        'Axes',obj.MouseAxes,...
                        'AxesPoint',currentPoint,...
                        'MousePressPoint',obj.MousePressPoint,...
                        'MouseDragDelta',obj.MouseDragDelta,...
                        'Figure',hitFigure,...
                        'FigurePoint',e.Point,...
                        'ScreenPoint',root.PointerLocation);
                    
                    % Call method
                    obj.onMouseDrag(evt);
                    
                end %if any( hitAxes == obj.MouseAxes )
                
            end %if ~isempty(obj.MouseSelection)
            
        end %function
        
        
        function onAxesFigureChanged(obj)
            
            % Use first axes
            if ~isempty(obj.AxesFigureObserver)
                hFigure = obj.AxesFigureObserver(1).Figure;
            else
                hFigure = [];
            end
            
            if obj.EnableMouseHandler && ~isempty(hFigure)
                obj.MousePressListener = event.listener( hFigure, ...
                    'WindowMousePress', @(h,e)onMousePress_private(obj,e) );
                obj.MouseReleaseListener = event.listener( hFigure, ...
                    'WindowMouseRelease', @(h,e)onMouseRelease_private(obj,e) );
                obj.MouseMotionListener = event.listener( hFigure, ...
                    'WindowMouseMotion', @(h,e)onMouseMotion_private(obj,e) );
            else
                obj.MousePressListener = event.listener.empty(0,0);
                obj.MouseReleaseListener = event.listener.empty(0,0);
                obj.MouseMotionListener = event.listener.empty(0,0);
            end
            
        end %function
        
        
        function onClickableAxesChanged(obj)
            
            delete(obj.AxesFigureObserver);
            delete(obj.AxesFigureListener);
            
            % Listen to figure changes for the ClickableAxes
            if obj.EnableMouseHandler
                for index = 1:numel(obj.ClickableAxes)
                    obj.AxesFigureObserver(index) = uix.FigureObserver( obj.ClickableAxes(index) );
                    obj.AxesFigureListener(index) = event.listener(obj.AxesFigureObserver(index), ...
                        'FigureChanged',@(h,e)onAxesFigureChanged(obj) );
                end
            else
                obj.AxesFigureObserver = uix.FigureObserver.empty(0,0);
                obj.AxesFigureListener = event.listener.empty(0,0);
            end %if obj.EnableMouseHandler
            
            % Update the mouse listeners
            obj.onAxesFigureChanged();
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function set.ClickableAxes(obj,value)
            obj.ClickableAxes = value;
            obj.onClickableAxesChanged();
        end
        
        function set.EnableMouseHandler(obj,value)
            obj.EnableMouseHandler = value;
            obj.onClickableAxesChanged();
        end
        
    end %methods
    
    
end % classdef