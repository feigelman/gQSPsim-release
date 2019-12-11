classdef EditFieldWithLabel < uix.abstract.Editable & uix.mixin.HasLabel
    
    
    %% Properties
    properties
        FieldType = 'text'
        Validator = function_handle.empty(0,0)
    end
    
    properties (Hidden=true)
        ShowDialogOnError = true;
    end
    

    %% Constructor
    methods
        function obj = EditFieldWithLabel(varargin)
            
            % Create the parent widget
            obj = obj@uix.abstract.Editable();
            obj = obj@uix.mixin.HasLabel();
            
            % Now update some details in the GUI elements
            set(obj.hLabel,'Parent', obj.UIContainer);
            set(obj.HGEditBox,'HorizontalAlignment','left');
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.redraw();
            
        end % constructor
        
    end % Public methods
    
    
    %% Redraw graphics
    methods ( Access = 'protected' )
        
        function redraw(obj)
            if obj.IsConstructed
                
                sz = max(getpixelsize(obj), [5 5]);
                width = sz(1);
                height = sz(2);
                
                switch obj.LabelLocation
                    case 'left'
                        sp = min(obj.Spacing, width/5);
                        labelX = 1;
                        labelY = 1;
                        labelW = min(obj.LabelWidth, width-3);
                        labelH = height;
                        editX = labelW + sp + 1;
                        editY = 1;
                        editW = width - editX + 1;
                        editH = height;
                    case 'top'
                        sp = min(obj.Spacing, height/5);
                        labelX = 1;
                        labelY = floor((height+sp)/2);
                        labelW = width;
                        labelH = floor((height-sp)/2);
                        editX = 1;
                        editY = 1;
                        editW = width;
                        editH = labelH;
                    otherwise
                        error('not implemented: label on %s',obj.LabelLocation)
                end
                
                set(obj.hLabel, 'Position', [labelX labelY labelW labelH])
                set(obj.HGEditBox, 'Position', [editX editY editW editH])
                
            end %if obj.IsConstructed
        end %function redraw(obj)
        
        
    end %methods
    
    
    %% Helper methods
    methods ( Access = 'protected' )
        
        function ok = checkValue(obj,value)
            % This method must be implemented per the base class
            % Make sure number is valid
            ok = true;
            if ~isempty(obj.Validator)
                try
                    obj.Validator(value);
                catch err
                    ok = false;
                    if obj.ShowDialogOnError
                        hDlg = errordlg(err.message,obj.LabelString,'modal');
                        uiwait(hDlg);
                    end
                end
            end
        end % checkValue
        
        
        function value = interpretStringAsValue(obj,str)
            % This method must be implemented per the base class
            switch obj.FieldType
                case 'text'
                    value = str;
                case {'number','matrix'}
                    value = str2num(str); %#ok<ST2NM>
                case 'eval'
                    value = eval(str);
            end
        end % interpretStringAsValue
        
        
        function str = interpretValueAsString(obj,value)
            % This method must be implemented per the base class
            switch obj.FieldType
                case 'text'
                    str = value;
                case 'number'
                    str = num2str(value);
                case 'matrix'
                    str = mat2str(value);
                case 'eval'
                    str = value;
            end
        end % interpretValueAsString
        
    end % Protected methods    
    
  
    %% Get/Set methods
    methods  
        
        % FieldType
        function set.FieldType(obj,value)
            value = validatestring(value,{'text','number','matrix','eval'});
            obj.FieldType = value;
        end
        
    end % Get/Set methods
    
end % classdef