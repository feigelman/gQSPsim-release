classdef (Abstract) Editable < uix.abstract.Widget
    % Editable  A base class for the editable text widgets
    % ---------------------------------------------------------------------
    % This is an abstract base class and cannot be instantiated.
    % It provides the following properties for its descendents:
    %     * Font styles (name, size, weight etc)
    %     * Edit-box colors (Foreground & Background)
    %     * Callback
    %     * The HG editbox and button
    %
    % uix.abstract.Editable inherits properties and methods from
    % uix.abstract.Widget, and adds the following:
    %
    % uix.abstract.Editable Properties:
    %
    %   Callback - Function to call when the value changes
    %
    %   TextEditable - Can the text be manually edited
    %
    %   Value - Current value shown in the widget
    %
    %   BackgroundColor - Color for text background
    %
    %   ForegroundColor - Color for text
    %
    %   FontAngle - Text font angle [normal|italic|oblique]
    %
    %   FontName - Text font name
    %
    %   FontSize - Text font size
    %
    %   FontUnits - Text font units [inches|centimeters|normalized|points|pixels]
    %
    %   FontWeight - Text font weight [light|normal|demi|bold]
    %
    %   HorizontalAlignment - Text alignment [left|center|right]
    %
    %   Tooltip - Tooltip for the eit field
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
    %   $Revision: 284 $
    %   $Date: 2016-09-01 13:55:31 -0400 (Thu, 01 Sep 2016) $
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
        TextEditable = 'on' % Can the text be manually edited
    end
    properties (SetObservable=true)
        Value = []          % Current value shown in the widget
    end
    
    properties (Hidden=true)
        HGEditBox = []
    end % Protected properties
    
    
    %% Abstract methods
    methods( Abstract = true, Access = 'protected' )
        
        ok = checkValue(obj,value) % Decide if the value is valid
        value = interpretStringAsValue(obj,str) % Convert a string to a sensible value
        str = interpretValueAsString(obj,value) % Print the value as a string
        
    end % abstract methods
    
    
    %% Public methods
    methods
        
        function obj = Editable( varargin )
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj = obj@uix.abstract.Widget( varargin{:} );
            
            % Create the context menu
            contextMenu = uicontextmenu( ...
                'Parent', ancestor( obj.UIContainer, 'figure' ), ...
                'Tag', 'UIWidgets:Editable:ContextMenu' );
            
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
            
            % Create the editbox
            obj.HGEditBox = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Enable', obj.Enable, ...
                'FontSize',10, ...
                'Style','edit', ...
                'BackgroundColor', [1 1 1], ...
                'Callback', @(h,e)obj.onTextEdit(), ...
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
            if isempty( obj.HGEditBox )
                % Not yet setup
                return;
            end
            
            sz = getpixelsize( obj );
            set( obj.HGEditBox, 'Position', [1 1 sz] );
        end % redraw
        
    end %methods
    
    
    %% Helper methods
    methods (Hidden=true)
        
        function onTextEdit(obj)
            
            str = get(obj.HGEditBox,'String');
            value = obj.interpretStringAsValue(str);
            
            % Validate
            ok = checkValue(obj,value);
            if ok
                % Trigger callback if value changed
                if ~isequal( obj.Value, value )
                    evt = struct( 'Source', obj, ...
                        'Interaction', 'Edit', ...
                        'OldValue', obj.Value, ...
                        'NewValue', value );
                    obj.Value = obj.interpretValueAsString(value);
                    uix.utility.callCallback(obj.Callback,obj,evt);
                end
            else
                % Value was invalid, so revert
                set( obj.HGEditBox, 'String', obj.interpretValueAsString( obj.Value ) );
            end
            
        end % onTextEdit
    end
    
    
    methods ( Access = 'protected' )
        
        function onEnableChanged(obj,~,eventData)
            %onEnableChanged: Callback that fires when the widget is enabled/disabled
            set( findall( obj.UIContainer, 'Type', 'UIControl' ), 'Enable', eventData.Value );
            if strcmpi( eventData.Value, 'on' )
                % If the text isn't editable, set it to be inactive
                if strcmpi( obj.TextEditable, 'off' )
                    set( obj.HGEditBox, 'Enable', 'Inactive' );
                end
                % If the child class has some elements disabled for other
                % reasons, give it chance to redraw them.
                obj.redraw();
            end
        end % onEnableChanged
        
        
        function onCutMenu( obj, ~, ~ )
            % User wants to cut to clipboard
            clipboard( 'copy', get( obj.HGEditBox, 'String' ) );
            set( obj.HGEditBox, 'String', '' );
            % Now pretend the text was manually edited
            obj.onTextEdit( obj.HGEditBox, [] );
        end % onCutMenu
        
        
        function onCopyMenu( obj, ~, ~ )
            % User wants to copy to clipboard
            clipboard( 'copy', get( obj.HGEditBox, 'String' ) );
        end % onCopyMenu
        
        
        function onPasteMenu( obj, src, evt )
            % Use wants to paste something in
            str = clipboard( 'paste' );
            % If the string is mutliline, keep only the first
            if any( str == sprintf( '\n' ) )
                str = str(1:find(str == sprintf('\n'),1,'first')-1);
            end
            
            set( obj.HGEditBox, 'String', str );
            
            % Now pretend the text was manually edited
            obj.onTextEdit( src, evt )
        end % onPasteMenu
        
        
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        % FontAngle
        function value = get.FontAngle(obj)
            value = get(obj.HGEditBox,'FontAngle');
        end
        function set.FontAngle(obj,value)
            set(obj.HGEditBox,'FontAngle',value);
        end
        
        % FontName
        function value = get.FontName(obj)
            value = get(obj.HGEditBox,'FontName');
        end
        function set.FontName(obj,value)
            set(obj.HGEditBox,'FontName',value);
        end
        
        % FontSize
        function value = get.FontSize(obj)
            value = get(obj.HGEditBox,'FontSize');
        end
        function set.FontSize(obj,value)
            set(obj.HGEditBox,'FontSize',value);
        end
        
        % FontUnits
        function value = get.FontUnits(obj)
            value = get(obj.HGEditBox,'FontUnits');
        end
        function set.FontUnits(obj,value)
            set(obj.HGEditBox,'FontUnits',value);
        end
        
        % FontWeight
        function value = get.FontWeight(obj)
            value = get( obj.HGEditBox, 'FontWeight' );
        end
        function set.FontWeight(obj,value)
            set(obj.HGEditBox,'FontWeight',value);
        end
        
        % HorizontalAlignment
        function alignment = get.HorizontalAlignment(obj)
            alignment = get(obj.HGEditBox,'HorizontalAlignment');
        end
        function set.HorizontalAlignment(obj,alignment)
            set( obj.HGEditBox, 'HorizontalAlignment', alignment );
        end
        
        % BackgroundColor
        function value = get.BackgroundColor(obj)
            value = get(obj.HGEditBox,'BackgroundColor');
        end
        function set.BackgroundColor(obj,value)
            set( obj.HGEditBox, 'BackgroundColor', value );
        end
        
        % ForegroundColor
        function value = get.ForegroundColor(obj)
            value = get(obj.HGEditBox,'ForegroundColor');
        end
        function set.ForegroundColor(obj,value)
            set( obj.HGEditBox, 'ForegroundColor', value );
        end
        
        % Tooltip
        function value = get.Tooltip(obj)
            value = get(obj.HGEditBox,'Tooltip');
        end
        function set.Tooltip(obj,value)
            set( obj.HGEditBox, 'Tooltip', value );
        end
        
        % TextEditable
        function set.TextEditable(obj,value)
            if ~any( strcmpi( value, {'on','off'} ) )
                error( 'uix:abstract:Editable:BadOnOffValue', 'Property ''TextEditable'' must be ''on'' or ''off''' );
            end
            obj.TextEditable = lower( value );
            obj.onEnableChanged( obj, struct( 'Value', obj.Enable ) );
        end
        
        function set.Value(obj,value)
            if ~ischar(value)
                value = obj.interpretValueAsString(value);
            end
            if checkValue(obj, value)
                obj.Value = value;
                if ~isequal( value, get(obj.HGEditBox,'String') ) %#ok<MCSUP>
                    set( obj.HGEditBox, 'String', value ); %#ok<MCSUP>
                end
            end
        end
        
    end % Data access methods
    
end % classdef