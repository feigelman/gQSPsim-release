classdef (Abstract) HasLabel < matlab.mixin.SetGet 
    
   %% Properties
    properties (Dependent=true)
        LabelBackgroundColor     % Color for text background
        LabelForegroundColor     % Color for text
        LabelFontAngle           % Text font angle [normal|italic|oblique]
        LabelFontName            % Text font name
        LabelFontSize            % Text font size
        LabelFontUnits           % Text font units [inches|centimeters|normalized|points|pixels]
        LabelFontWeight          % Text font weight [light|normal|demi|bold]
        LabelString
        LabelTooltip
    end % Calculated properties
    
    properties
        LabelLocation char = 'left';
        LabelWidth double = 100;
    end

    properties (GetAccess=protected, SetAccess=protected)
        hLabel
    end % Protected properties
    
    
    %% Constructor
    methods
        function obj = HasLabel(varargin)
            
            % Create an unparented label. Subclass can parent it.
            obj.hLabel = matlab.ui.control.UIControl( ...
                'Visible', 'on', ...
                'Style', 'text', ...
                'HorizontalAlignment','left',...
                'FontSize',10);
            
        end % constructor
        
    end % Public methods
    
  
    %% Get/Set methods
    methods  
        
        % FontAngle
        function value = get.LabelFontAngle(obj)
            value = get(obj.hLabel,'FontAngle');
        end
        function set.LabelFontAngle(obj,value)
            set(obj.hLabel,'FontAngle',value);
        end
        
        % FontName
        function value = get.LabelFontName(obj)
            value = get(obj.hLabel,'FontName');
        end
        function set.LabelFontName(obj,value)
            set(obj.hLabel,'FontName',value);
        end
        
        % FontSize
        function value = get.LabelFontSize(obj)
            value = get(obj.hLabel,'FontSize');
        end
        function set.LabelFontSize(obj,value)
            set(obj.hLabel,'FontSize',value);
        end
        
        % FontUnits
        function value = get.LabelFontUnits(obj)
            value = get(obj.hLabel,'FontUnits');
        end
        function set.LabelFontUnits(obj,value)
            set(obj.hLabel,'FontUnits',value);
        end
        
         % FontWeight
        function value = get.LabelFontWeight(obj)
            value = get( obj.hLabel, 'FontWeight' );
        end
        function set.LabelFontWeight(obj,value)
            set(obj.hLabel,'FontWeight',value);
        end
 
        % BackgroundColor
        function value = get.LabelBackgroundColor(obj)
            value = get(obj.hLabel,'BackgroundColor');
        end 
        function set.LabelBackgroundColor(obj,value)
            set( obj.hLabel, 'BackgroundColor', value );
        end
        
        % ForegroundColor
        function value = get.LabelForegroundColor(obj)
            value = get(obj.hLabel,'ForegroundColor');
        end
        function set.LabelForegroundColor(obj,value)
            set( obj.hLabel, 'ForegroundColor', value );
        end
        
        % LabelString
        function value = get.LabelString(obj)
            value = get(obj.hLabel,'String');
        end
        function set.LabelString(obj,value)
            set(obj.hLabel,'String',value);
        end
        
        % Tooltip
        function value = get.LabelTooltip(obj)
            value = get(obj.hLabel,'Tooltip');
        end
        function set.LabelTooltip(obj,value)
            set( obj.hLabel, 'Tooltip', value );
        end

        % LabelLocation
        function set.LabelLocation(obj,value)
            value = validatestring(value,{'left','right','top','bottom'});
            obj.LabelLocation = value;
            switch value
                case 'left'
                    set(obj.hLabel,'HorizontalAlignment','left') %#ok<MCSUP>
                case 'right'
                    set(obj.hLabel,'HorizontalAlignment','left') %#ok<MCSUP>
                case {'bottom','top'}
                    set(obj.hLabel,'HorizontalAlignment','left') %#ok<MCSUP>
            end
        end
        
        % LabelWidth
        function set.LabelWidth(obj,value)
            validateattributes(value,{'double'},{'scalar','finite','positive'})
            obj.LabelWidth = value;
        end
        
    end % Get/Set methods
    
    
end % classdef
    