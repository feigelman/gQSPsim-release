classdef MultiPlatformTable < uix.abstract.Widget & uix.mixin.HasLabel
    % MultiPlatformTable  A base class for the MultiPlatformTable widgets
    %   Copyright 2008-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $
    %   $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (Dependent=true)
        ColumnName
        ColumnFormat
        ColumnEditable
        Data        
        SelectedRows
        TableContextMenu
    end
    properties
        UseButtons = true
        ButtonPosition = 'bottom'
        ButtonCallback = []
        CellEditCallback = []       % Function to call when the value changes
        CellSelectionCallback = []
        LabelHeight = 30
    end
    properties (SetAccess=private)
        SelectedRowsOverride
        UseJTable = true
    end
    properties (Hidden=true)
        HTable = []
    end
    properties (SetAccess=protected, GetAccess=protected)
        ButtonVis = true(1,3)
    end
    
    
    %% Public methods
    methods
        function obj = MultiPlatformTable( varargin )
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj = obj@uix.abstract.Widget( varargin{:} );
            obj = obj@uix.mixin.HasLabel();
            
            % Now update some details in the GUI elements
            set(obj.hLabel,'Parent', obj.UIContainer);
            
            % Set according to OS
%             if ispc
%                 obj.UseJTable = true;
%             else
%                 obj.UseJTable = false;
%             end

            obj.UseJTable = false;
            
            % Create the table
            if obj.UseJTable
                obj.HTable = uix.widget.Table(...
                    'Parent',obj.UIContainer,...                    
                    'Units','pixels',...
                    'Data',{},...       
                    'CellSelectionCallback',@(h,e)obj.onCellSelection(h,e),...
                    'CellEditCallback',@(h,e)obj.onCellEdit(h,e));
            else
                obj.HTable = uitable(...
                    'Parent',obj.UIContainer,...
                    'Units','pixels',...
                    'Data',{},...
                    'CellSelectionCallback',@(h,e)obj.onCellSelection(h,e),...
                    'CellEditCallback',@(h,e)obj.onCellEdit(h,e));                
            end
            
            % Icons
            ButtonInfo = {
                uix.utility.loadIcon( 'add_24.png' ), @(h,e)onAddButtonPressed(obj,h,e), 'Add a new row.'
                uix.utility.loadIcon( 'delete_24.png' ), @(h,e)onRemoveButtonPressed(obj,h,e), 'Delete the highlighted row.'                
                uix.utility.loadIcon( 'copy_24.png' ), @(h,e)onDuplicateButtonPressed(obj,h,e), 'Duplicate the highlighted row.'                
                };
            
            % Buttons
            for idx = size(ButtonInfo,1):-1:1
                obj.h.Button(idx) = uicontrol( ...
                    'Parent', obj.UIContainer, ...
                    'Style', 'pushbutton', ...
                    'CData', ButtonInfo{idx,1}, ...
                    'TooltipString', ButtonInfo{idx,3},...
                    'Visible', uix.utility.tf2onoff(obj.UseButtons),...
                    'Callback', ButtonInfo{idx,2} );
            end
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.redraw();
        end % constructor
        
        function setCellColor(obj,rowIdx,colIdx,Color)
            % Don't do anything if this is not a jTable
            if obj.UseJTable
                validateattributes(rowIdx,{'numeric'},{'scalar'});
                validateattributes(colIdx,{'numeric'},{'scalar'});
%                 validateattributes(Color,{'numeric'},{'size',[1 3]});
                DataSize = size(obj.Data);
                if rowIdx >= 1 && rowIdx <= DataSize(1) && colIdx >= 1 && colIdx <= DataSize(2)                
                    obj.HTable.setCellColor(rowIdx,colIdx,Color);
                else
                    warning('Invalid indices passed into setCellColor. Skipping.');
                end
            end            
        end %function
        
    end %methods
    
    
    %% Redraw graphics
    methods ( Access = 'protected' )
        
        function redraw( obj )
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % UseButtons
                if isscalar(obj.UseButtons)
                    obj.ButtonVis = obj.UseButtons * ones(1,numel(obj.h.Button));
                elseif numel(obj.UseButtons) == numel(obj.h.Button)
                    obj.ButtonVis = obj.UseButtons;
                else
                    obj.ButtonVis = false;
                end
                    
                % Label height
                if ~isempty(obj.LabelString)
                    LabelHeight = obj.LabelHeight; %#ok<*PROP>
                    LabelWidth = obj.LabelWidth;
                else
                    LabelHeight = 0;
                    LabelWidth = 0;
                end 
                
                % Get sizes
                [width,height] = obj.getpixelsize;
                
                % Set label location
                switch obj.LabelLocation
                    case 'left'
                        labelX = 1;
                        labelY = height-LabelHeight;
                        labelW = min(LabelWidth, width-3);
                        labelH = LabelHeight;                        
                    case 'top'
                        labelX = 1;
                        labelY = height-LabelHeight;
                        labelW = width;
                        labelH = LabelHeight;
                        
                    otherwise
                        error('not implemented: label on %s',obj.LabelLocation)
                end
                
                set(obj.hLabel, 'Position', [labelX labelY labelW labelH])
                
                % Get widget dimensions
                Button_LHS = strcmp(obj.ButtonPosition, 'left');
                
                % Position buttons
                nbut = numel(obj.h.Button);
                butW = 28;
                butH = 28;
                if Button_LHS
                    if strcmpi(obj.LabelLocation,'left')
                        % left label
                        butX = 1+obj.Padding+LabelWidth;                        
                        butY = height - obj.Padding - butH;
                    else
                        % top label
                        butX = 1+obj.Padding;                        
                        butY = height - obj.Padding - butH - LabelHeight;
                    end
                    
                    for idx = 1:nbut
                        if obj.ButtonVis(idx)
                            set(obj.h.Button(idx), 'Position', [butX butY butW butH]);
                            butY = butY - butH - obj.Spacing;
                        end
                    end
                else
                    if strcmpi(obj.LabelLocation,'left')
                        % left label
                        butX = 1+obj.Padding+LabelWidth;                        
                    else
                        % top label
                        butX = 1+obj.Padding;                        
                    end
                    butY = 1+obj.Padding;
                    for idx = 1:nbut
                        if idx>numel(obj.ButtonVis) || obj.ButtonVis(idx)
                            set(obj.h.Button(idx), 'Position', [butX butY butW butH]);
                            butX = butX + butW + obj.Spacing;
                        end
                    end
                end
                
                % Position table
                if Button_LHS
                    if any(obj.ButtonVis) %obj.UseButtons
                        if strcmpi(obj.LabelLocation,'left')
                            % left label
                            tableX = 1+obj.Padding+obj.Spacing+butW+LabelWidth;
                        else
                            % top label
                            tableX = 1+obj.Padding+obj.Spacing+butW;
                        end
                    else
                        if strcmpi(obj.LabelLocation,'left')
                            % left label
                            tableX = 1+obj.Padding+obj.Spacing+LabelWidth;
                        else
                            % top label
                            tableX = 1+obj.Padding+obj.Spacing;
                        end
                    end
                    tableY = 1+obj.Padding;
                    tableW = max(width - obj.Padding - tableX,0);
                    if strcmpi(obj.LabelLocation,'left')
                        % left label
                        tableH = max(height - obj.Padding - tableY,0);
                    else
                        % top label
                        tableH = max(height - obj.Padding - tableY - LabelHeight,0);
                    end
                    set(obj.HTable, 'Position', [tableX tableY tableW tableH]);
                else
                    if strcmpi(obj.LabelLocation,'left')
                        % left label
                        tableX = 1+obj.Padding+LabelWidth;
                    else
                        % top label
                        tableX = 1+obj.Padding;
                    end
                    if any(obj.ButtonVis) %obj.UseButtons
                        tableY = 1+obj.Padding+obj.Spacing+butH;
                    else
                        tableY = 1+obj.Padding+obj.Spacing;
                    end
                    tableW = max(width - obj.Padding - tableX,0);
                    if strcmpi(obj.LabelLocation,'left')
                        % left label
                        tableH = max(height - obj.Padding - tableY,0);
                    else
                        % top label
                        tableH = max(height - obj.Padding - tableY - LabelHeight,0);
                    end
                    set(obj.HTable, 'Position', [tableX tableY tableW tableH]);
                end
                
                % Update enables
                if strcmp(obj.Enable,'on')
                    
                    % Button 1 - Add
                    ThisEnable = true;
                    set(obj.h.Button(1), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                    % Button 2 - Delete
                    ThisEnable = ~isempty(obj.Data);
                    set(obj.h.Button(2), 'Enable', uix.utility.tf2onoff(ThisEnable) );  
                    
                    % Button 3 - Duplicate
                    ThisEnable = ~isempty(obj.Data);
                    set(obj.h.Button(3), 'Enable', uix.utility.tf2onoff(ThisEnable) );  
                    
                else
                    % Whole widget disabled                    
                    set(obj.h.Button, 'Enable', 'off')
                end
                
                % Visibility
                for index = 1:numel(obj.h.Button)
                    set(obj.h.Button(index), 'Visible', uix.utility.tf2onoff(obj.ButtonVis(index)));
                end
                
            end %if ~isempty(obj.h)
            
        end % redraw
        
    end %methods
    
    
    %% Helper methods
    methods (Hidden=true)
        
        function onCellEdit(obj,~,evt)
            
            if obj.UseJTable
                onTableModelChanged(obj,[],eventData);
            else
                uix.utility.callCallback(obj.CellEditCallback,obj,evt);
            end
            
            % Redraw the component
            obj.redraw();
            
        end % onCellEdit
                
        function onCellSelection(obj,~,evt)
            
            if obj.UseJTable
                onSelectionChanged(obj,[],eventData);
            else
                uix.utility.callCallback(obj.CellSelectionCallback,obj,evt);
            end
            
            % Redraw the component
            obj.redraw();
            
        end % onCellSelection
        
        function onAddButtonPressed(obj,~,~)
            
            evt = struct( 'Source', obj, ...
                'Interaction', 'Add', ...                
                'Indices', obj.SelectedRows );
            uix.utility.callCallback(obj.ButtonCallback,obj,evt);
            
            % Redraw the component
            obj.redraw();
            
        end % onAddButtonPressed
            
        function onRemoveButtonPressed(obj,~,~)
            
            evt = struct( 'Source', obj, ...
                'Interaction', 'Remove', ...                
                'Indices', obj.SelectedRows );
            uix.utility.callCallback(obj.ButtonCallback,obj,evt);
            
            % Redraw the component
            obj.redraw();
            
        end %function onRemoveButtonPressed
        
        function onDuplicateButtonPressed(obj,~,~)
            
            evt = struct( 'Source', obj, ...
                'Interaction', 'Duplicate', ...                
                'Indices', obj.SelectedRows );
            uix.utility.callCallback(obj.ButtonCallback,obj,evt);
            
            % Redraw the component
            obj.redraw();
            
        end %function onRemoveButtonPressed       
        
    end
    
    %% Get/Set methods
    methods
        
        % ColumnName
        function value = get.ColumnName(obj)
            if obj.IsConstructed
                value = get(obj.HTable,'ColumnName');
            else
                value = {};
            end
        end
        function set.ColumnName(obj,value)
            if obj.IsConstructed
                set(obj.HTable,'ColumnName',value);            
            end
        end
        
        % ColumnFormat
        function value = get.ColumnFormat(obj)
            if ~isempty(obj.HTable)
                value = get(obj.HTable,'ColumnFormat');
            else
                value = {};
            end
        end
        function set.ColumnFormat(obj,value)
            if obj.IsConstructed
                if obj.UseJTable
                    for idx = 1:numel(value)
                        if ischar(value{idx}) && strcmpi(value{idx},'logical')
                            % Replace logical -> boolean
                            value{idx} = 'boolean';
                        elseif ischar(value{idx}) && any(strcmpi(value{idx},{'bank','numeric'}))
                            % Replace bank/numeric -> float
                            value{idx} = 'float';
                        end
                    end
                    
                    ThisColumnFormat = value;
                    IsCell = cellfun(@iscell,value);
                    
                    ColumnFormatData = cell(size(value));
                    ColumnFormatData(IsCell) = value(IsCell);
                    
                    ThisColumnFormat(IsCell) = {'popup'};
                    
                    set(obj.HTable,'ColumnFormat',ThisColumnFormat);            
                    set(obj.HTable,'ColumnFormatData',ColumnFormatData);        
                else
                    
                    for idx = 1:numel(value)
                        if isempty(value{idx})
                            value{idx} = 'char'; % Default
                        end
                        if ischar(value{idx}) && strcmpi(value{idx},'boolean')
                            % Replace boolean -> logical
                            value{idx} = 'logical';
                        elseif ischar(value{idx}) && strcmpi(value{idx},'float')
                            % Replace float -> numeric
                            value{idx} = 'numeric';
                        elseif iscell(value{idx}) && ~isrow(value{idx})
                            value{idx} = value{idx}';
                        end
                    end     
                    set(obj.HTable,'ColumnFormat',value);            
                end
            end
        end
        
        % ColumnEditable
        function value = get.ColumnEditable(obj)
            if obj.IsConstructed
                value = get(obj.HTable,'ColumnEditable');
            else
                value = {};
            end
        end
        function set.ColumnEditable(obj,value)
            if obj.IsConstructed
                set(obj.HTable,'ColumnEditable',value);            
            end
        end
        
        % Data
        function value = get.Data(obj)
            
            hEdit = obj.CellEditCallback ;
            obj.CellEditCallback = @(h,e) [];
            if obj.IsConstructed
                value = get(obj.HTable,'Data');
            else
                value = {};
            end
            obj.CellEditCallback = hEdit;
        end
        function set.Data(obj,value)
            if obj.IsConstructed
                set(obj.HTable,'Data',value);            
            end
        end
        
        % SelectedRows
        function value = get.SelectedRows(obj)
            if obj.IsConstructed
                if obj.UseJTable
                    value = get(obj.HTable,'SelectedRows');
                else
                    value = obj.SelectedRowsOverride;
                end
            else
                value = [];
            end
        end
        function set.SelectedRows(obj,value)
            if obj.IsConstructed
                if obj.UseJTable
                    set(obj.HTable,'SelectedRows',value);            
                    obj.SelectedRowsOverride = value;
                else
                    obj.SelectedRowsOverride = value;
                end
            end
        end
        
        % UIContextMenu
        function value = get.TableContextMenu(obj)
            if obj.IsConstructed
                value = get(obj.HTable,'UIContextMenu');
            else
                value = {};
            end
        end
        function set.TableContextMenu(obj,value)
            if obj.IsConstructed
                set(obj.HTable,'UIContextMenu',value);            
            end
        end
        
        % UseButtons
        function set.UseButtons(obj,value)
            validateattributes(value,{'logical'},{});
            obj.UseButtons = value;
        end
        
        % ButtonPosition
        function set.ButtonPosition(obj,value)
            value = validatestring(value, {'left','bottom'});
            obj.ButtonPosition = value;
        end
        
        % ButtonCallback
        function set.ButtonCallback(obj,value)
            if isempty(value)
                obj.ButtonCallback = function_handle.empty(0,1);
            else
                obj.ButtonCallback = value;
            end
        end
        
        % CellEditCallback
        function set.CellEditCallback(obj,value)
            if isempty(value)
                obj.CellEditCallback = function_handle.empty(0,1);
            else
                obj.CellEditCallback = value;
            end
        end
        
        % CellSelectionCallback
        function set.CellSelectionCallback(obj,value)
            if isempty(value)
                obj.CellSelectionCallback = function_handle.empty(0,1);
            else
                obj.CellSelectionCallback = value;
            end
        end
        
        % LabelHeight
        function set.LabelHeight(obj,value)
            validateattributes(value,{'numeric'},{'nonnegative','scalar'});
            obj.LabelHeight = value;
        end
    end
    
end % classdef