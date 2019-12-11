classdef ListBuilder < uix.abstract.Widget & uix.mixin.HasCallback
    % ListBuilder - A widget for adding/removing items from a list
    % ---------------------------------------------------------------------
    % Create a widget that allows you to add/remove items from a listbox
    %
    % Syntax:
    %           w = uix.widget.ListBuilder('Property','Value',...)
    %
    % Properties:
    %
    %   AllItems - cell array of all items to select from [cell of strings]
    %
    %   AddedIndex - numeric indices of added items from AllItems [column
    %   matrix]
    %
    %   AddedItems (dependent) - cell array of current added items,
    %   based on AllItems and AddedIndex [cell of strings]
    %
    %   AllowCopy - flag whether to display a copy button on the widget. If
    %   AllowDuplicates is true, copy adds additional copies of the
    %   selected items to the list. If not, you must define the copy
    %   behavior in a custom Callback. [true|(false)]
    %
    %   AllowDuplicates - flag whether allow items to be selected multiple
    %   times in the widget. This is useful if you are using the widget as
    %   an ordered list and may want to use items multiple times.
    %   [true|(false)]
    %
    %   AllowOrdering - flag whether to allow changing the order of items
    %   in the list by moving them up and down [true|(false)]
    %
    %   SelectedListIndex - numeric indices of currently selected (highlighted)
    %   items in the list [column matrix]
    %
    %   SelectedItems (dependent) - cell array of current added and
    %   highlighted items, based on AllItems, AddedIndex and SelectedListIndex
    %   [cell of char]
    %
    % Inherited Properties:
    %
    %   BeingDeleted - Is the object in the process of being deleted
    %   [on|off]
    %
    %   DeleteFcn - Callback to execute when the object is deleted
    %   [function_handle]
    %
    %   Enable - allow interaction with this widget [on|off]
    %
    %   IsConstructed - indicate whether construction is complete
    %   [true|false]. Set this true at the end of your constructor method.
    %
    %   Parent - Handle of the parent container or figure [handle]
    %
    %   Position - Position [left bottom width height]
    %
    %   Tag - Tag [char]
    %
    %   Type - The object type (class) [char]
    %
    %   Units - Position units
    %   [inches|centimeters|normalized|points|pixels|characters]
    %
    %   UIContextMenu - Context menu for the object
    %
    %   Visible - Is the control visible on-screen [on|off]
    %
    %   Callback - Optional callback for selection, list changes, copy,
    %   etc.
    %
    % Methods:
    %       none
    %
    % Examples:
    %
    %     AllItems = {'Alpha';'Bravo';'Charlie';'Delta';'Echo';'Foxtrot'};
    %     AddedIndex = 2:numel(AllItems);
    %     fig = figure;
    %     w = uix.widget.ListBuilder('Parent',fig,'AllItems',AllItems,'AddedIndex',AddedIndex);
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 272 $
    %   $Date: 2016-08-31 12:42:59 -0400 (Wed, 31 Aug 2016) $
    % ---------------------------------------------------------------------
    
    %RAJ - TO DO
    % Make a better dialog for selection
    % Write updateSelectionForNewItems method
    % Consider replacing ButtonVis with just toggling button visibilities
    
    %% Properties
    properties (AbortSet=true)
        AllItems = cell(0,1)
        AddedIndex = zeros(0,1)
    end
    properties (Dependent=true, SetAccess=private)
        AddedItems
    end
    properties
        AllowCopy = false
        AllowDuplicates = false
        AllowOrdering = false
        AllowEdit = false
        ButtonPosition = 'bottom'
        CustomButtonsMode = false
    end
    properties (Dependent=true, AbortSet=true)
        SelectedListIndex
    end
    properties (Dependent=true, SetAccess=private)
        SelectedAllIndex
        SelectedItems
    end
    properties (SetAccess=protected, GetAccess=protected)
        ButtonVis = true(1,6)
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ListBuilder( varargin )
            
            % Create the parent widget
            obj = obj@uix.abstract.Widget();
            
            % Create the base graphics
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Set button visibilities
            obj.ButtonVis(3) = obj.AllowCopy;
            obj.ButtonVis(4) = obj.AllowEdit;
            obj.ButtonVis(5:6) = obj.AllowOrdering;
            for idx = 1:numel(obj.h.Button)
                set(obj.h.Button(idx), 'Visible',...
                    uix.utility.tf2onoff(obj.ButtonVis(idx)) )
            end
            
            % Do the following only if obj is a ListBuilder and not a
            % subclass of ListBuilder
            if strcmp(class(obj), 'uix.widget.ListBuilder') %#ok<STISA>
                
                % Assign the construction flag
                obj.IsConstructed = true;
                
                % Redraw the widget
                obj.redraw();
                
            end
            
        end %constructor
        
    end %methods - constructor/destructor
    
    
    %% Create and Redraw graphics
    methods ( Access = 'protected' )
        
        function create(obj)
            
            % Icons
            ButtonInfo = {
                uix.utility.loadIcon( 'add_24.png' ), @(h,e)onAddButtonPressed(obj,h,e), 'Add a new item to the list.'
                uix.utility.loadIcon( 'delete_24.png' ), @(h,e)onRemoveButtonPressed(obj,h,e), 'Delete the highlighted item from the list.'
                uix.utility.loadIcon( 'copy_24.png' ), @(h,e)onCopyButtonPressed(obj,h,e), 'Add copies of the highlighted item to the list.'
                uix.utility.loadIcon( 'edit_24.png' ), @(h,e)onEditButtonPressed(obj,h,e), 'Edit the highlighted item.'
                uix.utility.loadIcon( 'arrow_up_24.png' ), @(h,e)onUpButtonPressed(obj,h,e), 'Move the highlighted item up.'
                uix.utility.loadIcon( 'arrow_down_24.png' ), @(h,e)onDownButtonPressed(obj,h,e), 'Move the highlighted item down.'
                };
            
            % List
            obj.h.Listbox = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Style', 'listbox', ...
                'FontSize', 10, ...
                'Max', 2, ...
                'Callback', @(h,e)onListSelection(obj,h,e));
            
            % Buttons
            for idx = size(ButtonInfo,1):-1:1
                obj.h.Button(idx) = uicontrol( ...
                    'Parent', obj.UIContainer, ...
                    'Style', 'pushbutton', ...
                    'CData', ButtonInfo{idx,1}, ...
                    'TooltipString', ButtonInfo{idx,3},...
                    'Callback', ButtonInfo{idx,2} );
            end
            
        end %function create(obj)
        
        
        function redraw(obj)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [width,height] = obj.getpixelsize;
                Button_LHS = strcmp(obj.ButtonPosition, 'left');
                
                % Position buttons
                nbut = numel(obj.h.Button);
                butW = 28;
                butH = 28;
                if Button_LHS
                    butX = 1+obj.Padding;
                    butY = height - obj.Padding - butH;
                    for idx = 1:nbut
                        if obj.ButtonVis(idx)
                            set(obj.h.Button(idx), 'Position', [butX butY butW butH]);
                            butY = butY - butH - obj.Spacing;
                        end
                    end
                else
                    butX = 1+obj.Padding;
                    butY = 1+obj.Padding;
                    for idx = 1:nbut
                        if idx>numel(obj.ButtonVis) || obj.ButtonVis(idx)
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
                
                % Update the listbox text and selection
                ListboxStr = obj.AllItems(obj.AddedIndex);
                NewSel = obj.SelectedListIndex;
                if isempty(ListboxStr)
                    NewSel = [];
                elseif ~isempty(NewSel)
                    NewSel = NewSel( NewSel <= numel(ListboxStr) );
                    if isempty(NewSel)
                        NewSel = numel(ListboxStr);
                    end
                end
                set(obj.h.Listbox, 'String', ListboxStr, 'Value', NewSel);
                
                % Update enables
                if strcmp(obj.Enable,'on')
                    
                    % How many added and how many selected?
                    NumAll = numel(obj.AllItems);
                    NumAdd = numel(obj.AddedIndex);
                    NumSel = numel(NewSel);
                    
                    % Listbox always on if widget enabled
                    set(obj.h.Listbox, 'Enable', 'on')
                    
                    % Button 1 - Add
                    ThisEnable = obj.CustomButtonsMode || obj.AllowDuplicates || obj.AllowCopy || NumAdd<NumAll;
                    set(obj.h.Button(1), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                    % Button 2 - Delete
                    ThisEnable = NumSel>0;
                    set(obj.h.Button(2), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                    % Button 3 - Copy
                    ThisEnable = obj.AllowCopy && NumSel>0;
                    set(obj.h.Button(3), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                    % Button 4 - Edit
                    ThisEnable = obj.AllowEdit && NumSel==1;
                    set(obj.h.Button(4), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                    % Button 5 - Up
                    ThisEnable = obj.AllowOrdering && NumSel>0 && NewSel(end)>NumSel;
                    set(obj.h.Button(5), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                    % Button 6 - Down
                    ThisEnable = obj.AllowOrdering && NumSel>0 && NewSel(1)<=(NumAdd-NumSel);
                    set(obj.h.Button(6), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                else
                    % Whole widget disabled
                    set(obj.h.Listbox, 'Enable', 'off')
                    set(obj.h.Button, 'Enable', 'off')
                end
                
            end %if ~isempty(obj.h)
        end %function redraw(obj)
        
        
    end %methods
    
    
    %% Callback methods
    methods ( Access = 'protected' )
        
        function onAddButtonPressed(obj,~,~)

            StatusOk = true;
            
            % What mode are we using
            if ~obj.CustomButtonsMode
                
                % Which items may be added? Depends if duplicates are allowed.
                idxAdd = 1:numel(obj.AllItems);
                if ~obj.AllowDuplicates
                    % Only items that are not yet added
                    idxAdd = setdiff(idxAdd, obj.AddedIndex);
                end
                AddItems = obj.AllItems(idxAdd);
                
                % Are there potential items to add?
                StatusOk = ~isempty(AddItems);
                
                % Prompt for the list
                if StatusOk
                    %RAJ - replace with improved dialog later
                    [NewSelection, StatusOk] = listdlg( ...
                        'PromptString', 'Select items', ...
                        'ListString', AddItems);
                else
                    hDlg = errordlg('No items to add','Add','modal');
                    uiwait(hDlg);
                end
                
                % Verify the user didn't cancel
                if StatusOk
                    
                    % Insert the new indices
                    obj.insertIndices( idxAdd(NewSelection) );
                    
                end %if StatusOk
                
                Items = obj.AllItems( idxAdd(NewSelection) );
                
                evt = struct('Source',obj,...
                    'Interaction', 'Add',...
                    'NewItems', Items,...
                    'NewItemsIndex',idxAdd(NewSelection),...
                    'SelectedItems', obj.SelectedItems,...
                    'SelectedAllIndex', obj.SelectedAllIndex,...
                    'SelectedListIndex', obj.SelectedListIndex);
                
            else
                
                evt = struct('Source',obj,...
                    'Interaction', 'Add',...
                    'SelectedItems', obj.SelectedItems,...
                    'SelectedAllIndex', obj.SelectedAllIndex,...
                    'SelectedListIndex', obj.SelectedListIndex);
                
            end
            
            if StatusOk
                
                % Call the callback
                obj.callCallback(evt);
                
                % Redraw the component
                obj.redraw();
                
            end
            
        end %function onAddButtonPressed
        
        
        function onCopyButtonPressed(obj,~,~)
            
            % What mode are we using
            if ~obj.CustomButtonsMode
                % Insert the new indices
                obj.insertIndices( obj.SelectedAllIndex );
            end
            
            % Call the callback
            evt = struct('Source',obj,...
                'Interaction', 'Copy',...
                'SelectedItems', obj.SelectedItems,...
                'SelectedAllIndex', obj.SelectedAllIndex,...
                'SelectedListIndex', obj.SelectedListIndex);
            obj.callCallback(evt);
            
            % Redraw the component
            obj.redraw();
            
        end %function onCopyButtonPressed
        
        
        function onDownButtonPressed(obj,~,~)
            
            % Shift selection down 1
            idxMovedTo = shiftSelection(obj,1);
            
            % Call the callback
            Items = obj.AddedItems(idxMovedTo);
            evt = struct('Source',obj,...
                'Interaction', 'MoveDown',...
                'MovedItems', Items,...
                'SelectedItems', obj.SelectedItems,...
                'SelectedAllIndex', obj.SelectedAllIndex,...
                'SelectedListIndex', obj.SelectedListIndex);
            obj.callCallback(evt);
            
            % Redraw the component
            obj.redraw();
            
        end %function onDownButtonPressed
        
        
        function onEditButtonPressed(obj,~,~)
            
            % Call the callback
            evt = struct('Source',obj,...
                'Interaction', 'Edit',...
                'SelectedItems', obj.SelectedItems,...
                'SelectedAllIndex', obj.SelectedAllIndex,...
                'SelectedListIndex', obj.SelectedListIndex);
            obj.callCallback(evt);
            
            % Redraw the component
            obj.redraw();
            
        end %function onDownButtonPressed
        
        
        function onListSelection(obj,~,~)
            
            % Redraw the component
            obj.redraw();
            
            % Call the callback
            Items = obj.SelectedItems;
            evt = struct('Source',obj,...
                'Interaction', 'Select',...
                'SelectedItems', obj.SelectedItems,...
                'SelectedAllIndex', obj.SelectedAllIndex,...
                'SelectedListIndex', obj.SelectedListIndex);
            obj.callCallback(evt);
            
        end %function onListSelection
        
        
        function onRemoveButtonPressed(obj,~,~)
            
            % What is currently highlighted in the listbox?
            SelIdx = obj.SelectedListIndex;
            
            % Get the items to remove
            Items = obj.AllItems( obj.AddedIndex(SelIdx,:) );
            
            % What mode are we using
            if ~obj.CustomButtonsMode
                % Remove these items
                obj.AddedIndex(SelIdx,:) = [];
            end
            
            % Call the callback
            evt = struct('Source',obj,...
                'Interaction', 'Remove',...
                'RemovedItems', Items,...
                'SelectedItems', obj.SelectedItems,...
                'SelectedAllIndex', obj.SelectedAllIndex,...
                'SelectedListIndex', obj.SelectedListIndex);
            obj.callCallback(evt);
            
            % Redraw the component
            obj.redraw();
            
        end %function onRemoveButtonPressed
        
        
        function onUpButtonPressed(obj,~,~)
            
            % Shift selection up 1
            idxMovedTo = shiftSelection(obj,-1);
            
            % Call the callback
            Items = obj.AddedItems(idxMovedTo);
            evt = struct('Source',obj,...
                'Interaction', 'MoveDown',...
                'MovedItems', Items,...
                'SelectedItems', obj.SelectedItems,...
                'SelectedAllIndex', obj.SelectedAllIndex,...
                'SelectedListIndex', obj.SelectedListIndex);
            obj.callCallback(evt);
            
            % Redraw the component
            obj.redraw();
            
        end %function onUpButtonPressed
        
        
    end %methods - redraw graphics
    
    
    %% Helper methods
    methods (Access = protected)
        function updateSelectionForNewItems(obj,NewItems,OldItems)
            % Handle selection when the list of items changes
            
            %RAJ - this could be improved by checking membership/location
            %of the new and old items.
            % Ensure the selection does not exceed bounds
            obj.SelectedListIndex( obj.SelectedListIndex > numel(obj.AllItems) ) = [];
            
        end
        
        function idxMovedTo = shiftSelection(obj,Shift)
            
            % Get the new indices
            [idxNew, idxMovedTo] = uix.utility.shiftIndexInList(...
                obj.SelectedListIndex, numel(obj.AddedIndex), Shift);
            
            % Update the order in the listbox
            obj.AddedIndex = obj.AddedIndex(idxNew);
            
            % Update the selected items in the listbox
            obj.SelectedListIndex = idxMovedTo;
        end
        
        function insertIndices(obj,idxNew)
            
            % Where to insert?
            if ~obj.AllowOrdering
                %RAJ - improve this to sort the list
                InsertIdx = numel(obj.AddedIndex);
            elseif isempty(obj.SelectedListIndex)
                InsertIdx = numel(obj.AddedIndex);
            else
                InsertIdx = obj.SelectedListIndex(end);
            end
            
            % Update the selection
            NewIndex = [
                obj.AddedIndex(1:InsertIdx)
                idxNew(:)
                obj.AddedIndex((InsertIdx+1):end)];
            if ~obj.AllowOrdering
                NewIndex = sort(NewIndex);
            end
            obj.AddedIndex = NewIndex;
            
            
        end
        
    end
    
    
    %% Get/Set methods
    methods
        
        % AllItems
        function set.AllItems(obj,value)
            if ~isequal(obj.AllItems, value)
                validateattributes(value,{'cell'},{'column'})
                OldItems = obj.AllItems;
                obj.AllItems = value;
                obj.updateSelectionForNewItems(value,OldItems);
            end
        end
        
        % AddedIndex
        function set.AddedIndex(obj,value)
            value = value(:);
            if ~isequal(obj.AddedIndex, value)
                maxVal = numel(obj.AllItems); %#ok<MCSUP>
                validateattributes(value,{'numeric'},...
                    {'column', 'integer', 'positive', '<=', maxVal})
                obj.AddedIndex = value;
            end
        end
        
        % AddedItems
        function value = get.AddedItems(obj)
            value = obj.AllItems( obj.AddedIndex );
        end
        
        % AllowDuplicates
        function set.AllowDuplicates(obj,value)
            if obj.IsConstructed
                error('Property AllowDuplicates may not be changed after the ListBuilder is created.');
            end
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowDuplicates = value;
        end
        
        % AllowCopy
        function set.AllowCopy(obj,value)
            if obj.IsConstructed
                error('Property AllowCopy may not be changed after the ListBuilder is created.');
            end
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowCopy = value;
        end
        
        % AllowOrdering
        function set.AllowOrdering(obj,value)
            if obj.IsConstructed
                error('Property AllowOrdering may not be changed after the ListBuilder is created.');
            end
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowOrdering = value;
        end
        
        % AllowEdit
        function set.AllowEdit(obj,value)
            if obj.IsConstructed
                error('Property AllowEdit may not be changed after the ListBuilder is created.');
            end
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowEdit = value;
        end
        
        % ButtonPosition
        function set.ButtonPosition(obj,value)
            value = validatestring(value, {'left','bottom'});
            obj.ButtonPosition = value;
        end
        
        % SelectedListIndex
        function value = get.SelectedListIndex(obj)
            if obj.IsConstructed
                value = get( obj.h.Listbox, 'Value' );
            else
                value = zeros(0,1);
            end
        end
        function set.SelectedListIndex(obj,value)
            if obj.IsConstructed
                set( obj.h.Listbox, 'Value', value );
            end
        end
        
        % SelectedAllIndex
        function value = get.SelectedAllIndex(obj)
            if obj.IsConstructed && ~isempty(obj.AddedIndex)
                value = obj.AddedIndex(obj.SelectedListIndex);
            else
                value = zeros(0,1);
            end
        end
        
        % SelectedItems
        function value = get.SelectedItems(obj)
            value = obj.AllItems( obj.AddedIndex(obj.SelectedListIndex) );
        end
        
    end % Get/Set methods
    
    
end %classdef