classdef (Abstract) Popup < uix.abstract.Widget
    % Popup  A base class for the Popup text widgets
    % ---------------------------------------------------------------------
    % This is an abstract base class and cannot be instantiated.
    % It provides the following properties for its descendents:
    %     * Font styles (name, size, weight etc)
    %     * Popup-box colors (Foreground & Background)
    %     * Callback
    %     * The HG popup and button
    %
    % uix.abstract.Popup inherits properties and methods from
    % uix.abstract.Widget, and adds the following:
    %
    % uix.abstract.Popup Properties:
    %
    %     Callback - Function to call when the value changes
    %
    %     TextPopup - Can the text be manually edited
    %
    %     Value - Current value shown in the widget
    %
    %     BackgroundColor - Color for text background
    %
    %     ForegroundColor - Color for text
    %
    %     FontAngle - Text font angle [normal|italic|oblique]
    %
    %     FontName - Text font name
    %
    %     FontSize - Text font size
    %
    %     FontUnits - Text font units [inches|centimeters|normalized|points|pixels]
    %
    %     FontWeight - Text font weight [light|normal|demi|bold]
    %
    %     HorizontalAlignment - Text alignment [left|center|right]
    %
    %     Tooltip - Tooltip for the eit field
    %
    % Methods you may overload in subclasses:
    %
    %   onResized, onVisibleChanged, onEnableChanged,
    %   onContainerBeingDestroyed, onButtonClicked, checkValue,
    %   interpretStringAsValue, interpretValueAsString
    %
    % Methods you must define in subclasses:
    %   
    %   redraw
    %
    
    %   Copyright 2008-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 272 $
    %   $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (Dependent=true)
        BackgroundColor     % Color for text background
    end
    properties
        Callback = []       % Function to call when the value changes
    end
    properties (Dependent=true)
        ForegroundColor     % Color for text
        FontAngle           % Text font angle [normal|italic|oblique]
        FontName            % Text font name
        FontSize            % Text font size
        FontUnits           % Text font units [inches|centimeters|normalized|points|pixels]
        FontWeight          % Text font weight [light|normal|demi|bold]
        HorizontalAlignment % Text alignment [left|center|right]
        Tooltip
    end % Calculated properties
    properties
        TextPopup = 'on' % Can the text be manually edited
    end
    properties (SetObservable=true)
        String = {}        % Current string options shown in the widget
        Value = 1          % Current value shown in the widget
    end

    properties (Hidden=true)
        HGPopupBox = []
    end % Protected properties
    
    
    %% Public methods
    methods
        function obj = Popup( varargin )
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj = obj@uix.abstract.Widget( varargin{:} );

            % Create the context menu
            contextMenu = uicontextmenu( ...
                'Parent', ancestor( obj.UIContainer, 'figure' ), ...
                'Tag', 'UIWidgets:Popup:ContextMenu' );
            
            % 2010-08-04 BJT: "cut" implies leaving an empty string, which
            % is not supported by most of the widgets and is therefore
            % confusing.
            % uimenu( contextMenu, ...
            %     'Label', 'Cut', ...
            %     'Callback', @obj.onCutMenu );
            uimenu( contextMenu, ...
                'Label', 'Copy value', ...
                'Callback', @obj.onCopyMenu );
            uimenu( contextMenu, ...
                'Label', 'Paste value', ...
                'Callback', @obj.onPasteMenu );
            
            % Create the Popupbox
            obj.HGPopupBox = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Enable', obj.Enable, ...
                'FontSize',10, ...
                'Style','popup', ...
                'BackgroundColor', [1 1 1], ...
                'Callback', @(h,e)obj.onTextPopup(), ...
                'UIContextMenu', contextMenu );
            
            % Finally, parse any input arguments
            if nargin>1
                set( obj, varargin{:} );
            end
            obj.redraw();
        end % constructor
        
    end %methods
    
    
    %% Redraw graphics
    methods ( Access = 'protected' )
        
        function redraw( obj )
            if isempty( obj.HGPopupBox )
                % Not yet setup
                return;
            end
            
            sz = getpixelsize( obj );
            set( obj.HGPopupBox, 'Position', [1 1 sz] );
        end % redraw
    
    end %methods
    
    
    %% Helper methods
    methods (Hidden=true)
        
        function onTextPopup(obj)
            
            str = get(obj.HGPopupBox,'String');
            value = get(obj.HGPopupBox,'Value');
            
            if ischar(str)
                value = 1;
            elseif iscell(value)
                value = max(1,value);
                value = min(value,numel(str));
            end
            
            % Trigger callback if value changed
            if ~isequal( obj.Value, value ) || ~isequal( obj.String, str )
                evt = struct( 'Source', obj, ...
                    'Interaction', 'Popup', ...
                    'OldValue', obj.Value, ...
                    'NewValue', value); % AG: Add string
                obj.Value = value;
                obj.String = str;
                uix.utility.callCallback(obj.Callback,obj,evt);
            end
            
        end % onTextPopup
    end
    
    
    methods ( Access = 'protected' )
        
        function onEnableChanged(obj,~,eventData)
            %onEnableChanged: Callback that fires when the widget is enabled/disabled
            set( findall( obj.UIContainer, 'Type', 'UIControl' ), 'Enable', eventData.Value );
            if strcmpi( eventData.Value, 'on' )
                % If the text isn't Popup, set it to be inactive
                if strcmpi( obj.TextPopup, 'off' )
                    set( obj.HGPopupBox, 'Enable', 'Inactive' );
                end
                % If the child class has some elements disabled for other
                % reasons, give it chance to redraw them.
                obj.redraw();
            end
       end % onEnableChanged
 
       
       function onCopyMenu( obj, ~, ~ )
           % User wants to copy to clipboard
           options = get( obj.HGPopupBox, 'String' );
           value = get(obj.HGPopupBox, 'Value' );
           clipboard( 'copy', options{value} );
       end % onCopyMenu
       
       
       function onPasteMenu( obj, src, evt )
           % Use wants to paste something in
           str = clipboard( 'paste' );
           
           % Do nothing
       end % onPasteMenu
       
       
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        % FontAngle
        function value = get.FontAngle(obj)
            value = get(obj.HGPopupBox,'FontAngle');
        end
        function set.FontAngle(obj,value)
            set(obj.HGPopupBox,'FontAngle',value);
        end
        
        % FontName
        function value = get.FontName(obj)
            value = get(obj.HGPopupBox,'FontName');
        end
        function set.FontName(obj,value)
            set(obj.HGPopupBox,'FontName',value);
        end
        
        % FontSize
        function value = get.FontSize(obj)
            value = get(obj.HGPopupBox,'FontSize');
        end
        function set.FontSize(obj,value)
            set(obj.HGPopupBox,'FontSize',value);
        end
        
        % FontUnits
        function value = get.FontUnits(obj)
            value = get(obj.HGPopupBox,'FontUnits');
        end
        function set.FontUnits(obj,value)
            set(obj.HGPopupBox,'FontUnits',value);
        end
        
         % FontWeight
        function value = get.FontWeight(obj)
            value = get( obj.HGPopupBox, 'FontWeight' );
        end
        function set.FontWeight(obj,value)
            set(obj.HGPopupBox,'FontWeight',value);
        end
        
        % HorizontalAlignment
        function alignment = get.HorizontalAlignment(obj)
            alignment = get(obj.HGPopupBox,'HorizontalAlignment');
        end
        function set.HorizontalAlignment(obj,alignment)
            set( obj.HGPopupBox, 'HorizontalAlignment', alignment );
        end
 
        % BackgroundColor
        function value = get.BackgroundColor(obj)
            value = get(obj.HGPopupBox,'BackgroundColor');
        end 
        function set.BackgroundColor(obj,value)
            set( obj.HGPopupBox, 'BackgroundColor', value );
        end
        
        % ForegroundColor
        function value = get.ForegroundColor(obj)
            value = get(obj.HGPopupBox,'ForegroundColor');
        end
        function set.ForegroundColor(obj,value)
            set( obj.HGPopupBox, 'ForegroundColor', value );
        end
        
        % Tooltip
        function value = get.Tooltip(obj)
            value = get(obj.HGPopupBox,'Tooltip');
        end
        function set.Tooltip(obj,value)
            set( obj.HGPopupBox, 'Tooltip', value );
        end
        
        % TextPopup
        function set.TextPopup(obj,value)
            if ~any( strcmpi( value, {'on','off'} ) )
                error( 'uix:abstract:Popup:BadOnOffValue', 'Property ''TextPopup'' must be ''on'' or ''off''' );
            end
            obj.TextPopup = lower( value );
            obj.onEnableChanged( obj, struct( 'Value', obj.Enable ) );
        end
        
        function set.String(obj,value)
            if ischar(value) || iscell(value)
                obj.String = value;
                if ~isequal( value, get(obj.HGPopupBox,'String') ) %#ok<MCSUP>
                    set( obj.HGPopupBox, 'String', value ); %#ok<MCSUP>
                end
            else
                obj.String = {};
            end
        end
        
        function set.Value(obj,value)
            obj.Value = value;
            if ~isequal( value, get(obj.HGPopupBox,'Value') ) %#ok<MCSUP>
                set( obj.HGPopupBox, 'Value', value ); %#ok<MCSUP>
            end
        end
        
    end % Data access methods
    
end % classdef