classdef (Abstract) AppWindow < handle & matlab.mixin.SetGet & uix.mixin.AssignPVPairs
    % AppWindow  A base class for an application main window
    % ---------------------------------------------------------------------
    % This is an abstract base class and cannot be instantiated. It
    % provides the basic properties needed for an application main window.
    %
    % Properties:
    %
    %   AppName - The name of the app, which is typically displayed on the
    %   title bar of the window ['AppWindow']
    %
    %   BeingDeleted (read-only) - Is the object in the process of being
    %   deleted [on|(off)]
    %
    %   DeleteFcn - Callback to execute when the object is deleted
    %
    %   Figure - figure window for the app
    %
    %   h - handles structure for subclasses to place widgets, uicontrols,
    %   etc. within the app
    %
    %   IsConstructed - indicate whether construction is complete
    %   [true|(false)]. Set this true at the end of your constructor method.
    %
    %   Listeners - array of listeners for the app
    %
    %   Position - Position (left bottom width height) [100 100 500 500]
    %
    %   Tag - Tag ['']
    %
    %   Title - Title to display on the figure title bar [char]
    %
    %   Type (read-only) - The object type (class) [char]
    %
    %   TypeStr (read-only) - The object type as a valid identifier string,
    %   as used for storing preferences for the app.
    %
    %   Units - Position units
    %   [inches|centimeters|normalized|points|(pixels)|characters]
    %
    %   UIContextMenu - Context menu for the object
    %
    %   Visible - Is the window visible on-screen [on|(off)]
    %
    % Methods of uix.abstract.AppWindow. Each of these methods
    % may be overloaded by subclasses:
    %
    %   onExit(obj) - called when the app is exited/closed
    %
    %   onResized(obj) - called when the figure is resized
    %
    %   onVisibleChanged(obj) - called when the figure visibility is
    %   changed
    %
    %   onContainerBeingDestroyed(obj) - called when the figure is being
    %   destroyed
    %
    %
    
    %   Copyright 2008-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 273 $
    %   $Date: 2016-08-31 12:48:38 -0400 (Wed, 31 Aug 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        AppName = 'AppWindow' 
    end
    
    properties (SetAccess=immutable)
        Type
        TypeStr = '';
    end
    
    properties (Dependent=true, AbortSet=true)
        DeleteFcn = []
        Units
        Position
        Tag
        UIContextMenu = []
        Visible
    end
    
    properties (Dependent=true, SetAccess=protected)
        Title
        BeingDeleted
    end
    
    properties (SetAccess=protected, GetAccess=protected)
        h = struct() %For widgets to store internal handles
        IsConstructed = false
        Figure = matlab.ui.Figure.empty(0,1);
        Listeners = event.listener.empty(0,1);
    end
    
    
    %% Constructor and Destructor
    methods
        
        function obj = AppWindow(varargin)
            
            % Set type
            obj.Type = class(obj);
            obj.TypeStr = matlab.lang.makeValidName(obj.Type);
            
            % Load last figure position
            Position = getpref(obj.TypeStr,'Position',[100 100 500 500]);
            
            % Create the figure window
            obj.Figure = figure(...
                'Name', '', ...
                'MenuBar', 'none', ...
                'Toolbar', 'none', ...
                'DockControls','off', ...
                'NumberTitle', 'off', ...
                'IntegerHandle','off',...
                'HandleVisibility', 'callback', ...
                'Color', get(0,'DefaultUIControlBackgroundColor'), ...
                'Visible', 'off',...
                'Position',Position,...
                'DeleteFcn',@(h,e)delete(obj),...
                'CloseRequestFcn',@(h,e)onExit(obj), ...
                'UserData',obj);
            
            % Store the object in the figure to keep it from being deleted

            % Ensure it's on the screen, in case display settings changed
            movegui(obj.Figure,'onscreen')
            
            % Assign PV pairs to properties
            obj.assignPVPairs(varargin{:});
            
            % Create listeners to resizing or deletion of container
            obj.Listeners = [
                event.listener(obj.Figure, 'SizeChanged', @(h,e)onResized(obj))
                event.listener(obj.Figure, 'ObjectBeingDestroyed', @(h,e)onContainerBeingDestroyed(obj))
                ];
            
        end
        
        
        function delete(obj)
            
            % Is this object still valid?
            if ~isempty(obj.Figure) && isvalid(obj.Figure)
                
                % Save last position
                setpref(obj.TypeStr,'Position',obj.Position)
                
                % Delete the figure
                delete(obj.Figure);
                
            end
            
        end % delete
        
    end
    
    
    %% Callbacks
    methods (Access=protected)
        
        %RAJ - are each of these required?
        
        function onExit(obj)
            obj.delete();
        end %function
        
        function onResized(obj) %#ok<MANU>
            %onResized: Callback that fires when the widget is resized.
        end %function
        
        function onVisibleChanged(obj) %#ok<MANU>
            %onVisibleChanged: Callback that fires when the widget is
            %shown/hidden
        end %function
        
        function onContainerBeingDestroyed(obj)
            %onContainerBeingDestroyed  Callback that fires when the
            %container dies
            delete(obj);
        end %function
        
    end % Protected methods
    
    
    
    %% Public methods
    methods
        
        function hgobj = double(obj)
            %double: Convert to an HG double handle.
            %
            %  D = double(W) converts a widget W to an HG handle D.
            hgobj = obj.Figure;
        end % double
        
        function pos = getpixelposition(obj, recursive)
            %getpixelposition: get the absolute pixel position
            %
            %   POS = GETPIXELPOSITION(C) gets the absolute position of the container C
            %   within its parent container. The returned position is in pixels.
            %
            %   POS = GETPIXELPOSITION(C,RECURSE) when RECURSE is set true
            %   will recursively scan the parents of the widget so as to
            %   return the position relative to the figure window.
            if nargin > 1
                % NB: If recursive is false the position part is relative
                % to immediate parent.
                pos = getpixelposition(obj.Figure, recursive);
            else
                pos = getpixelposition(obj.Figure);
            end
        end % getpixelposition
        
        function [w,h] = getpixelsize(obj)
            %getpixelsize: get the widget size [width,height] in pixels
            %
            %   POS = GETPIXELSIZE(C) or [W,H] = GETPIXELSIZE(C) returns
            %   the size [width,height] of this widget in pixels,
            %   regardless of the widget units.
            pos = getpixelposition(obj.Figure, false);
            if nargout==1
                w = pos(3:4);
            else
                w = pos(3);
                h = pos(4);
            end
        end % getpixelsize
        
    end % Public methods
    
    
    
    %% Redraw methods
    methods (Access=protected)
        
        function redraw(obj) %#ok<MANU>
        end %function
        
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        % AppName
        function set.AppName(obj,value)
            obj.AppName = value;
            obj.redraw();
        end
        
        % BeingDeleted
        function value = get.BeingDeleted(obj)
            value = get(obj.Figure, 'BeingDeleted');
        end
        
        % DeleteFcn
        function value = get.DeleteFcn(obj)
            value = get(obj.Figure, 'DeleteFcn');
        end
        function set.DeleteFcn(obj,value)
            set(obj.Figure, 'DeleteFcn', value);
        end
        
        % Position
        function value = get.Position(obj)
            value = get(obj.Figure, 'Position');
        end
        function set.Position(obj,value)
            set(obj.Figure, 'Position', value);
        end
        
        % Tag
        function value = get.Tag(obj)
            value = get(obj.Figure, 'Tag');
        end
        function set.Tag(obj, value)
            set(obj.Figure, 'Tag', value);
        end
        
        % Title
        function value = get.Title(obj)
            value = get(obj.Figure, 'Name');
        end
        function set.Title(obj, value)
            set(obj.Figure, 'Name', value);
        end
        
        % UIContextMenu
        function value = get.UIContextMenu(obj)
            value = get(obj.Figure, 'UIContextMenu');
        end
        function set.UIContextMenu(obj,value)
            set(obj.Figure, 'UIContextMenu', value);
        end
        
        % Units
        function value = get.Units(obj)
            value = get(obj.Figure, 'Units');
        end
        function set.Units(obj,value)
            set(obj.Figure, 'Units', value);
        end
        
        % Visible
        function value = get.Visible(obj)
            value = get(obj.Figure, 'Visible');
        end
        function set.Visible(obj,value)
            set(obj.Figure, 'Visible', value);
            obj.onVisibleChanged(obj);
            obj.redraw();
        end
        
    end % Get/Set methods
    
    
end % classdef
