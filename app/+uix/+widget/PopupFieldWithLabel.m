classdef PopupFieldWithLabel < uix.abstract.Popup & uix.mixin.HasLabel
    
    
    %% Properties
    properties
        Validator = function_handle.empty(0,0)
    end
    
    
    %% Constructor
    methods
        function obj = PopupFieldWithLabel(varargin)
            
            % Create the parent widget
            obj = obj@uix.abstract.Popup();
            obj = obj@uix.mixin.HasLabel();
            
            % Now update some details in the GUI elements
            set(obj.hLabel,'Parent',obj.UIContainer);
            set(obj.HGPopupBox,'HorizontalAlignment','left');
            
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
                        popupX = labelW + sp + 1;
                        popupY = 1;
                        popupW = width - popupX + 1;
                        popupH = height;
                    case 'top'
                        sp = min(obj.Spacing, height/5);
                        labelX = 1;
                        labelY = floor((height+sp)/2);
                        labelW = width;
                        labelH = floor((height-sp)/2);
                        popupX = 1;
                        popupY = 1;
                        popupW = width;
                        popupH = labelH;
                    otherwise
                        error('not implemented: label on %s',obj.LabelLocation)
                end
                
                set(obj.hLabel, 'Position', [labelX labelY labelW labelH])
                set(obj.HGPopupBox, 'Position', [popupX popupY popupW popupH])
                
            end %if obj.IsConstructed
        end %function redraw(obj)
        
        
    end %methods
  
    
end % classdef