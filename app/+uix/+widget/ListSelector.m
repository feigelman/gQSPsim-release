classdef ListSelector < uix.abstract.Widget & uix.mixin.HasCallback
    % ListSelector - A widget for adding/removing items from a list
    % ---------------------------------------------------------------------
    % Create a widget that allows you to add/remove items from a listbox
    %
    % Syntax:
    %           w = uix.widget.ListSelector('Property','Value',...)
    %
    % Examples:
    %
    %     AllItems = {'Alpha';'Bravo';'Charlie';'Delta';'Echo';'Foxtrot'};
    %     AddedIndex = 2:numel(AllItems);
    %     fig = figure;
    %     w = uix.widget.ListSelector('Parent',fig,'AllItems',AllItems,'AddedIndex',AddedIndex);
    %
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
    %   AllowDuplicates - flag whether allow items to be selected multiple
    %   times in the widget. This is useful if you are using the widget as
    %   an ordered list and may want to use items multiple times.
    %   [true|(false)]
    %
    %   AllowOrdering - flag whether to allow changing the order of items
    %   in the list by moving them up and down [true|(false)]
    %
    %   SelectedIndex - numeric indices of currently selected (highlighted)
    %   items in the list [column matrix]
    %
    %   SelectedItems (dependent) - cell array of current added and
    %   highlighted items, based on AllItems, AddedIndex and SelectedIndex
    %   [cell of strings]
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
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 316 $
    %   $Date: 2016-09-09 13:26:15 -0400 (Fri, 09 Sep 2016) $
    % ---------------------------------------------------------------------
    
    %RAJ - TO DO
    % Make a better dialog for selection
    % Write updateSelectionForNewItems method
    
    %% Properties
    properties (AbortSet=true)
        AllItems = cell(0,1)
        AddedIndex = zeros(0,1)
    end
    properties (Dependent=true, SetAccess=private)
        AddedItems
    end
    properties
        AllowDuplicates = false
        AllowOrdering = false
    end
    properties (Dependent=true, AbortSet=true)
        SelectedIndex
        SelectedSrcIndex
    end
    properties (Dependent=true, SetAccess=private)
        SelectedItems
        SelectedSrcItems
    end
    properties (SetAccess=private, GetAccess=private)
        ButtonVis = true(1,5)
    end
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ListSelector( varargin )
            
            % Create the parent widget
            obj = obj@uix.abstract.Widget();
            
            % Create the base graphics
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Set button visibilities
            obj.ButtonVis(3:4) = obj.AllowOrdering;
            for idx = 1:numel(obj.h.Button)
                set(obj.h.Button(idx), 'Visible',...
                    uix.utility.tf2onoff(obj.ButtonVis(idx)) )
            end
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.redraw();
            
        end %constructor
        
    end %methods - constructor/destructor
    
    
    %% Create and Redraw graphics
    methods ( Access = 'protected' )
        
        function create(obj)
            
            % Icons
            ButtonInfo = {
                uix.utility.loadIcon( 'arrow_right_24.png' ), @(h,e)onAddButtonPressed(obj,h,e), 'Add items into the selected list.'
                uix.utility.loadIcon( 'delete_24.png' ), @(h,e)onRemoveButtonPressed(obj,h,e), 'Delete highlighted items from the selected list.'
                uix.utility.loadIcon( 'arrow_up_24.png' ), @(h,e)onUpButtonPressed(obj,h,e), 'Shift highlighted items up.'
                uix.utility.loadIcon( 'arrow_down_24.png' ), @(h,e)onDownButtonPressed(obj,h,e), 'Shift highlighted items down.'
                };

            % List
            obj.h.ListboxSrc = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Style', 'listbox', ...
                'FontSize', 10, ...
                'Max', 2, ...
                'Callback', @(h,e)onListSrcSelection(obj,h,e));
            
            obj.h.Listbox = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Style', 'listbox', ...
                'FontSize', 10, ...
                'Max', 2, ...
                'Callback', @(h,e)onListSelection(obj,h,e));
            
            % Buttons
            idx = 1;
            obj.h.Button(idx) = uicontrol( ...
                'Parent', obj.UIContainer, ...
                'Style', 'pushbutton', ...
                'CData', ButtonInfo{idx,1}, ...
                'TooltipString', ButtonInfo{idx,3},...
                'Callback', ButtonInfo{idx,2} );
                
            for idx = size(ButtonInfo,1):-1:2
                obj.h.Button(idx) = uicontrol( ...
                    'Parent', obj.UIContainer, ...
                    'Style', 'pushbutton', ...
                    'CData', ButtonInfo{idx,1}, ...
                    'TooltipString', ButtonInfo{idx,3},...
                    'Callback', ButtonInfo{idx,2} );
            end
            
        end %function create
        
        
        function redraw(obj)
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                [width,height] = obj.getpixelsize;
                
                % Button Size
                butW = 28;
                butH = 28;
                
                % Position Source listbox
                listSrcX = 1+obj.Padding;
                listSrcY = 1+obj.Padding+2*obj.Spacing+butH;
                listSrcW = max((width - (2*obj.Padding+2*obj.Spacing+butW))/2,0);
                listSrcH = max(height - obj.Padding - listSrcY,0);
                set(obj.h.ListboxSrc, 'Position', [listSrcX listSrcY listSrcW listSrcH])
                
                % Position Selected listbox
                listX = obj.Padding+2*obj.Spacing+butW+listSrcW;
                listY = listSrcY;
                listW = listSrcW;
                listH = listSrcH;
                set(obj.h.Listbox, 'Position', [listX listY listW listH])
                
                % Position buttons
                butX = listSrcX + listSrcW + obj.Spacing;
                butY = listSrcY + listSrcH/2 - butH/2;
                set(obj.h.Button(1), 'Position', [butX butY butW butH]);
                
                nbut = numel(obj.h.Button);
                butX = listX;
                butY = 1+obj.Padding;
                for idx = 2:nbut
                    if obj.ButtonVis(idx)
                        set(obj.h.Button(idx), 'Position', [butX butY butW butH]);
                        butX = butX + butW + obj.Spacing;
                    end
                end
                
                % Redraw listbox text
                NewSel = obj.redrawListText();
                
                % Update enables
                if strcmp(obj.Enable,'on')
                    
                    % How many added and how many selected?
                    NumAll = numel(obj.AllItems);
                    NumAdd = numel(obj.AddedIndex);
                    NumSel = numel(NewSel);
                    
                    % Listbox always on if widget enabled
                    set(obj.h.ListboxSrc, 'Enable', 'on')
                    set(obj.h.Listbox, 'Enable', 'on')
                    
                    % Button 1 - Add
                    ThisEnable = obj.AllowDuplicates || NumAdd<NumAll;
                    set(obj.h.Button(1), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                    % Button 2 - Delete
                    ThisEnable = NumSel>0;
                    set(obj.h.Button(2), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                    % Button 3 - Up
                    ThisEnable = obj.AllowOrdering && NumSel>0 && NewSel(end)>NumSel;
                    set(obj.h.Button(3), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                    % Button 4 - Down
                    ThisEnable = obj.AllowOrdering && NumSel>0 && NewSel(1)<=(NumAdd-NumSel);
                    set(obj.h.Button(4), 'Enable', uix.utility.tf2onoff(ThisEnable) );
                    
                else
                    % Whole widget disabled
                    set(obj.h.Listbox, 'Enable', 'off')
                    set(obj.h.ListboxSrc, 'Enable', 'off')
                    set(obj.h.Button, 'Enable', 'off')
                end
                
            end %if obj.IsConstructed
            
        end %function redraw
        
        
        function NewSel = redrawListText(obj)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Update the listboxsrc text and selection
                if obj.AllowDuplicates % Duplicates
                    ListboxStr = obj.AllItems;
                else % No Duplicates
                    tf = true(size(obj.AllItems));
                    tf(obj.AddedIndex) = false;
                    ListboxStr = obj.AllItems(tf);
                end
                NewSel = obj.SelectedSrcIndex;
                if isempty(ListboxStr)
                    NewSel = [];
                elseif ~isempty(NewSel)
                    NewSel = NewSel( NewSel <= numel(ListboxStr) );
                    if isempty(NewSel)
                        NewSel = numel(ListboxStr);
                    end
                end
                set(obj.h.ListboxSrc, 'String', ListboxStr, 'Value', NewSel);
                
                % Update the listbox text and selection
                ListboxStr = obj.AllItems(obj.AddedIndex);
                NewSel = obj.SelectedIndex;
                if isempty(ListboxStr)
                    NewSel = [];
                elseif ~isempty(NewSel)
                    NewSel = NewSel( NewSel <= numel(ListboxStr) );
                    if isempty(NewSel)
                        NewSel = numel(ListboxStr);
                    end
                end
                set(obj.h.Listbox, 'String', ListboxStr, 'Value', NewSel);
                
            else
                NewSel = [];
            end %if obj.IsConstructed
        end %function
        
    end %methods
    
    
    %% Callback methods
    methods ( Access = 'protected' )
        
        function onAddButtonPressed(obj,~,~)
            
            % What is currently highlighted in the listbox?
            SelIdx = obj.h.ListboxSrc.Value;
            
            % Insert the new indices
            if obj.AllowDuplicates % Duplicates
                tf = true(size(obj.AllItems));
                ListboxIdx = find(tf);
            else % No Duplicates
                tf = true(size(obj.AllItems));
                tf(obj.AddedIndex) = false;
                ListboxIdx = find(tf);
            end
            obj.insertIndices(ListboxIdx(SelIdx)); %triggers redraw

            % Call the callback
            Items = obj.AllItems(SelIdx);
            evt = struct('Source',obj,'Interaction','Add','Items',Items);
            obj.callCallback(evt);
            
        end %function onAddButtonPressed
        
        function onCopyButtonPressed(obj,~,~)
            
            %RAJ - to do, make an optional callback
            
            % What is currently highlighted in the listbox?
            SelIdx = obj.h.Listbox.Value;
            
            % What indices are they?
            NewSelection = obj.AddedIndex(SelIdx);
            
            % Insert the new indices
            obj.insertIndices(NewSelection); %triggers redraw
            
            % Call the callback
            Items = obj.AllItems(NewSelection);
            evt = struct('Source',obj,'Interaction','Copy','Items',Items);
            obj.callCallback(evt);
            
        end %function onCopyButtonPressed
         
        function onDownButtonPressed(obj,~,~)
            
            % Shift selection down 1
            idxMovedTo = shiftSelection(obj,1); %triggers redraw
            
            % Call the callback
            Items = obj.AddedItems(idxMovedTo);
            evt = struct('Source',obj,'Interaction','MoveDown','Items',Items);
            obj.callCallback(evt);
            
        end %function onDownButtonPressed
        
        function onListSrcSelection(obj,~,~)
            
            % Redraw the component
            obj.redraw();
            
            % Call the callback
            Items = obj.SelectedItems;
            evt = struct('Source',obj,'Interaction','SelectSrc','Items',Items);
            obj.callCallback(evt);
            
        end %function onListSrcSelection
        
        function onListSelection(obj,~,~)
            
            % Redraw the component
            obj.redraw();
            
            % Call the callback
            Items = obj.SelectedItems;
            evt = struct('Source',obj,'Interaction','Select','Items',Items);
            obj.callCallback(evt);
            
        end %function onListSelection
        
        function onRemoveButtonPressed(obj,~,~)
            
            % What is currently highlighted in the listbox?
            SelIdx = obj.SelectedIndex;
            
            % Remove these items
            Items = obj.AllItems( obj.AddedIndex(SelIdx,:) );
            obj.AddedIndex(SelIdx,:) = []; %triggers redraw
            
            % Call the callback
            evt = struct('Source',obj,'Interaction','MoveDown','Items',Items);
            obj.callCallback(evt);
            
        end %function onRemoveButtonPressed
        
        function onUpButtonPressed(obj,~,~)
            
            % Shift selection up 1
            idxMovedTo = shiftSelection(obj,-1);  %triggers redraw
            
            % Call the callback
            Items = obj.AddedItems(idxMovedTo);
            evt = struct('Source',obj,'Interaction','MoveDown','Items',Items);
            obj.callCallback(evt);
            
        end %function onUpButtonPressed
        
    end %methods - redraw graphics
    
    
    %% Helper methods
    methods (Access = protected)
        
        function updateSelectionForNewItems(obj,NewItems,OldItems)
            % Handle selection when the list of items changes
            
            %RAJ - this could be improved by checking membership/location
            %of the new and old items.
            % Ensure the selection does not exceed bounds
            obj.SelectedIndex( obj.SelectedIndex > numel(obj.AllItems) ) = [];
            obj.AddedIndex( obj.AddedIndex > numel(obj.AllItems) ) = [];
            
        end
        
        function idxMovedTo = shiftSelection(obj,Shift)
            
            % Get the new indices
            [idxNew, idxMovedTo] = uix.utility.shiftIndexInList(...
                obj.SelectedIndex, numel(obj.AddedIndex), Shift);
            
            % Update the order in the listbox
            obj.AddedIndex = obj.AddedIndex(idxNew);
            
            % Update the selected items in the listbox
            obj.SelectedIndex = idxMovedTo;
        end
        
        function insertIndices(obj,idxNew)
            
            % Where to insert?
            if ~obj.AllowOrdering
                %RAJ - improve this to sort the list
                InsertIdx = numel(obj.AddedIndex);
            elseif isempty(obj.SelectedIndex)
                InsertIdx = numel(obj.AddedIndex);
            else
                InsertIdx = obj.SelectedIndex(end);
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
                if ~isempty(value)
                    validateattributes(value,{'cell'},{'column'})
                end
                OldItems = obj.AllItems;
                obj.AllItems = value;
                obj.updateSelectionForNewItems(value,OldItems);
                obj.redraw();
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
                obj.redraw();
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
                
        % AllowOrdering
        function set.AllowOrdering(obj,value)
            if obj.IsConstructed
                error('Property AllowOrdering may not be changed after the ListBuilder is created.');
            end
            validateattributes(value,{'logical'},{'scalar'})
            obj.AllowOrdering = value;
        end
        
        % SelectedIndex
        function value = get.SelectedIndex(obj)
            if obj.IsConstructed
                value = get( obj.h.Listbox, 'Value' );
            else
                value = zeros(0,1);
            end
        end
        function set.SelectedIndex(obj,value)
            if obj.IsConstructed
                set( obj.h.Listbox, 'Value', value );
            end
        end
        
        % SelectedSrcIndex
        function value = get.SelectedSrcIndex(obj)
            if obj.IsConstructed
                value = get( obj.h.ListboxSrc, 'Value' );
            else
                value = zeros(0,1);
            end
        end
        function set.SelectedSrcIndex(obj,value)
            if obj.IsConstructed
                set( obj.h.ListboxSrc, 'Value', value );
            end
        end
        
        % SelectedItems
        function value = get.SelectedItems(obj)
            value = obj.AllItems( obj.AddedIndex(obj.SelectedIndex) );
        end
        
        % SelectedSrcItems
        function value = get.SelectedSrcItems(obj)
            value = obj.AllItems( obj.AddedIndex(obj.SelectedSrcIndex) );
        end
        
    end % Get/Set methods
    
    
end %classdef