classdef ListWithButtons < uix.abstract.Widget & uix.mixin.HasCallback
    % ListWithButtons - A widget for adding/removing items from a list
    % ---------------------------------------------------------------------
    % Create a widget that allows you to add/remove items from a listbox
    %
    % Syntax:
    %           w = uix.widget.ListWithButtons('Property','Value',...)
    %
    % ListWithButtons inherits properties and methods from:
    %
    %   uix.abstract.Widget
    %   uix.mixin.HasCallback
    %
    % and adds the following:
    %
    % Properties:
    %
    %   Items - cell array of all items to display in the list [cell of
    %   strings]
    %
    %   SelectedItems (dependent) - cell array of currently selected 
    %   (highlighted) items [cell of char]
    %
    %   SelectedIndex - numeric indices of currently selected (highlighted)
    %   items in the list [column matrix]
    %
    %   AllowMultiSelect - flag whether to allow multi-selection in the
    %   list. [true|(false)]
    %
    %   AllowMove - flag whether to display a up/down buttons on the widget.
    %   You must define the behavior in the Callback. [true|(false)]
    %
    %   AllowCopy - flag whether to display a copy button on the widget.
    %   You must define the behavior in the Callback. [true|(false)]
    %
    %   AllowEdit - flag whether to display a copy button on the widget.
    %   You must define the behavior in the Callback. [true|(false)]
    %
    %   AllowPlot - flag whether to display a plot button on the widget.
    %   You must define the behavior in the Callback. [true|(false)]
    %
    %   AllowRun - flag whether to display a copy button on the widget.
    %   You must define the behavior in the Callback. [true|(false)]
    %
    %   ButtonPosition - location of the buttons. ['left'|('bottom')]
    %
    % Methods:
    %       none
    %
    % Examples:
    %
    %     f = figure;
    %     Items = {'Alpha';'Bravo';'Charlie';'Delta';'Echo';'Foxtrot'};
    %     l = uix.widget.ListWithButtons('Parent',f,...
    %         'Items', Items, ...
    %         'AllowMultiSelect', true, ...
    %         'AllowMove', true, ...
    %         'AllowCopy', true, ...
    %         'AllowEdit', true, ...
    %         'AllowPlot', true, ...
    %         'AllowRun', true, ...
    %         'ButtonPosition','bottom');
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 272 $
    %   $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet=true)
        Items cell = cell(0,1)
    end
    
    properties (Dependent=true, SetAccess=private)
        SelectedItems
    end
    
    properties (Dependent=true, AbortSet=true)
        SelectedIndex
    end
    
    properties (AbortSet=true)
        AllowMultiSelect = false
        AllowMove logical = false
        AllowCopy logical = false
        AllowEdit logical = false
        AllowPlot logical = false
        AllowRun logical = false
        ButtonPosition char = 'bottom'
    end
    
    properties (GetAccess=protected, SetAccess=protected)
        ButtonInfo = {
            'Add',      uix.utility.loadIcon('add_24.png'),         'Add a new item to the list.'
            'Delete',   uix.utility.loadIcon('delete_24.png'),      'Delete the highlighted item from the list.'
            'MoveUp',   uix.utility.loadIcon('arrow_up_24.png'),    'Move the highlighted item up.'
            'MoveDown', uix.utility.loadIcon('arrow_down_24.png'),  'Move the highlighted item down.'
            'Copy',     uix.utility.loadIcon('copy_24.png'),        'Add copies of the highlighted item to the list.'
            'Edit',     uix.utility.loadIcon('edit_24.png'),        'Edit the highlighted item.'
            'Plot',     uix.utility.loadIcon('plot_24.png'),        'Plot the selected item.'
            'Run',      uix.utility.loadIcon('play_24.png'),         'Run the selected item.'
            };
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ListWithButtons(varargin)
            
            % Create the parent widget
            obj = obj@uix.abstract.Widget();
            
            % Create the base graphics
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.redraw();
            
        end %constructor
        
    end %methods - constructor/destructor
    
    
    %% Create and Redraw graphics
    methods (Access = 'protected')
        
        function create(obj)
            
            % List
            obj.h.Listbox = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Style', 'listbox', ...
                'FontSize', 10, ...
                'Max', 1+obj.AllowMultiSelect, ...
                'Callback', @(h,e)onUserAction(obj,'Select'));
            
            % Buttons
            for idx = size(obj.ButtonInfo,1):-1:1
                obj.h.Button(idx) = uicontrol( ...
                    'Parent', obj.UIContainer, ...
                    'Style', 'pushbutton', ...
                    'CData', obj.ButtonInfo{idx,2}, ...
                    'TooltipString', obj.ButtonInfo{idx,3},...
                    'Callback', @(h,e)onUserAction(obj,obj.ButtonInfo{idx,1}) );
            end
            
        end %function create(obj)
        
        
        function redraw(obj)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Update enables and visibilities
                if strcmp(obj.Enable,'on')
                    % How many added and how many selected?
                    NumItems = numel(obj.Items);
                    SelIdx = obj.SelectedIndex;
                    NumSel = numel(SelIdx);
                    
                    % Listbox always on if widget enabled
                    set(obj.h.Listbox, ...
                        'String', obj.Items, ...
                        'Enable', 'on')
                    
                    % Button Enables and Visibilities
                    set(obj.h.Button(1), ... %Add
                        'Visible', 'on', ...
                        'Enable', 'on' );
                    set(obj.h.Button(2), ... %Delete
                        'Visible', 'on', ...
                        'Enable', uix.utility.tf2onoff(NumSel>0) );
                    set(obj.h.Button(3), ... %MoveUp
                        'Visible', uix.utility.tf2onoff(obj.AllowMove),...
                        'Enable', uix.utility.tf2onoff(NumSel>0 && SelIdx(end)>NumSel) );
                    set(obj.h.Button(4), ... %MoveDown
                        'Visible', uix.utility.tf2onoff(obj.AllowMove),...
                        'Enable', uix.utility.tf2onoff(NumSel>0 && SelIdx(1)<=(NumItems-NumSel)) );
                    set(obj.h.Button(5), ... %Copy
                        'Visible', uix.utility.tf2onoff(obj.AllowCopy),...
                        'Enable', uix.utility.tf2onoff(NumSel>0) );
                    set(obj.h.Button(6), ... %Edit
                        'Visible', uix.utility.tf2onoff(obj.AllowEdit),...
                        'Enable', uix.utility.tf2onoff(NumSel==1) );
                    set(obj.h.Button(7), ... %Plot
                        'Visible', uix.utility.tf2onoff(obj.AllowPlot),...
                        'Enable', uix.utility.tf2onoff(NumSel==1) );
                    set(obj.h.Button(8), ... %Run
                        'Visible', uix.utility.tf2onoff(obj.AllowRun),...
                        'Enable', uix.utility.tf2onoff(NumSel==1) );
                else
                    % Whole widget disabled
                    set(obj.h.Listbox, 'Enable', 'off')
                    set(obj.h.Button, 'Enable', 'off')
                end
                
                % Get widget dimensions
                [width,height] = obj.getpixelsize;
                Button_LHS = strcmp(obj.ButtonPosition, 'left');
                
                % Position buttons
                ButtonVis = strcmp( get(obj.h.Button, 'Visible'), 'on' );
                nbut = numel(obj.h.Button);
                butW = 28;
                butH = 28;
                if Button_LHS
                    butX = 1+obj.Padding;
                    butY = height - obj.Padding - butH;
                    for idx = 1:nbut
                        if ButtonVis(idx)
                            set(obj.h.Button(idx), 'Position', [butX butY butW butH]);
                            butY = butY - butH - obj.Spacing;
                        end
                    end
                else
                    butX = 1+obj.Padding;
                    butY = 1+obj.Padding;
                    for idx = 1:nbut
                        if ButtonVis(idx)
                            set(obj.h.Button(idx), 'Position', [butX butY butW butH]);
                            butX = butX + butW + obj.Spacing;
                        end
                    end
                end
                
                % Position listbox
                if Button_LHS
                    listX = 1+obj.Padding+obj.Spacing+butW;
                    listY = 1+obj.Padding;
                    listW = max(width - obj.Padding - listX,0);
                    listH = max(height - obj.Padding - listY,0);
                    set(obj.h.Listbox, 'Position', [listX listY listW listH]);
                else
                    listX = 1+obj.Padding;
                    listY = 1+obj.Padding+obj.Spacing+butH;
                    listW = max(width - obj.Padding - listX,0);
                    listH = max(height - obj.Padding - listY,0);
                    set(obj.h.Listbox, 'Position', [listX listY listW listH]);
                end
                
            end %if ~isempty(obj.h)
        end %function redraw(obj)
        
        
    end %methods
    
    
    %% Callback methods
    methods (Hidden=true)
        
        function onUserAction(obj,Interaction)
            
            % Prepare eventdata
            evt = struct('Source',obj,...
                'Interaction', Interaction,...
                'SelectedItems', {obj.SelectedItems},...
                'SelectedIndex', {obj.SelectedIndex});
            
            % Take custom action
            switch Interaction
                case 'MoveDown'
                    [evt.NewOrder, evt.DestIndex] = uix.utility.shiftIndexInList(...
                        obj.SelectedIndex, numel(obj.Items), 1);
                    obj.Items = obj.Items(evt.NewOrder);
                    obj.SelectedIndex = evt.DestIndex;
                case 'MoveUp'
                    [evt.NewOrder, evt.DestIndex] = uix.utility.shiftIndexInList(...
                        obj.SelectedIndex, numel(obj.Items), -1);
                    obj.Items = obj.Items(evt.NewOrder);
                    obj.SelectedIndex = evt.DestIndex;
            end
                    
            % Call the callback
            obj.callCallback(evt);
            
        end %function onAddButtonPressed
        
    end %methods - redraw graphics

    
    %% Get/Set methods
    methods
        
        % Items
        function set.Items(obj,value)
            obj.Items = value;
            obj.redraw();
        end
        
        % SelectedIndex
        function value = get.SelectedIndex(obj)
            if isfield(obj.h,'Listbox') && isvalid(obj.h.Listbox)
                value = get(obj.h.Listbox, 'Value');
            else
                value = zeros(0,1);
            end
        end
        function set.SelectedIndex(obj,value)
            if isfield(obj.h,'Listbox') && isvalid(obj.h.Listbox)
                set(obj.h.Listbox, 'Value', value);
            end
            obj.redraw();
        end
        
        % SelectedItems
        function value = get.SelectedItems(obj)
            value = obj.Items( obj.SelectedIndex );
        end
        
        % AllowMultiSelect
        function set.AllowMultiSelect(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowMultiSelect = value;
            if isfield(obj.h,'Listbox') && isvalid(obj.h.Listbox)
                set(obj.h.Listbox, 'Max', 1+value);
            end
            obj.redraw();
        end
        
        % AllowMove
        function set.AllowMove(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowMove = value;
            obj.redraw();
        end
        
        % AllowCopy
        function set.AllowCopy(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowCopy = value;
            obj.redraw();
        end
        
        % AllowEdit
        function set.AllowEdit(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowEdit = value;
            obj.redraw();
        end
        
        % AllowPlot
        function set.AllowPlot(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowPlot = value;
            obj.redraw();
        end
        
        % AllowRun
        function set.AllowRun(obj,value)
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowRun = value;
            obj.redraw();
        end
        
        % ButtonPosition
        function set.ButtonPosition(obj,value)
            value = validatestring(value, {'left','bottom'});
            obj.ButtonPosition = value;
            obj.redraw();
        end
        
    end % Get/Set methods
    
    
end %classdef