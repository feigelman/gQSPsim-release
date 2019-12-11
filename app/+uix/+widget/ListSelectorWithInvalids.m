classdef ListSelectorWithInvalids < uix.widget.ListSelector
    % ListSelectorWithInvalids - Custom ListSelector to show inactive items
    % ---------------------------------------------------------------------
    % This class extends the ListSelector, adding capability to mark
    % certain items as inactive
    %
    % Syntax:
    %           w = uix.widget.ListSelectorWithInvalids('Property','Value',...)
    %
    % This widget extends uix.widget.ListSelector and adds the following:
    %
    % Properties:
    %
    %   InvalidIndex - numeric indices of invalid items from AllItems
    %   [column matrix]
    %
    % Methods:
    %       none
    %
    % Examples:
    %
    %     AllItems = {'Alpha';'Bravo';'Charlie';'Delta';'Echo';'Foxtrot'};
    %     InvalidIndex = 2:numel(AllItems);
    %     fig = figure;
    %     w = uix.widget.ListSelectorWithInvalids('Parent',fig,...
    %         'AllItems',AllItems,'InvalidIndex',InvalidIndex);
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 286 $
    %   $Date: 2016-09-02 13:09:23 -0400 (Fri, 02 Sep 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        InvalidIndex = zeros(0,1);
    end
    
    
    
    %% Constructor / Destructor
    methods
        
        function obj = ListSelectorWithInvalids( varargin )
            
            % Call superclass constructor
            obj = obj@uix.widget.ListSelector(varargin{:});
            
        end %function
        
    end %methods - constructor/destructor
    
    
    
    %% Overridden methods
    methods ( Access = 'protected' )
        
        
        function NewSel = redrawListText(obj)
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass method first
                %obj.redrawListText@uix.widget.ListSelector();
                
                % Update the listboxsrc text and selection
                if obj.AllowDuplicates % Duplicates
                    idxKeep = 1:numel(obj.AllItems);
                else % No Duplicates
                    tf = true(size(obj.AllItems));
                    tf(obj.AddedIndex) = false;
                    idxKeep = find(tf);
                end
                ListboxStr = obj.AllItems(idxKeep);
                % Mark any invalid items
                for idx=1:numel(idxKeep)
                    if any(obj.InvalidIndex == idxKeep(idx))
                        ListboxStr{idx} = makeInvalid(ListboxStr{idx});
                    end
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
                % Mark any invalid items
                for idx=1:numel(ListboxStr)
                    if any(obj.InvalidIndex == obj.AddedIndex(idx))
                        ListboxStr{idx} = makeInvalid(ListboxStr{idx});
                    end
                end                
                set(obj.h.Listbox, 'String', ListboxStr, 'Value', NewSel);
                
            else
                NewSel = [];
            end %if obj.IsConstructed
            
            % Helper function
            function str = makeInvalid(str)
                str = sprintf('<html><font color="red">%s (INVALID)</font>',str);
            end
            
        end %function
        
        
        function updateSelectionForNewItems(obj,NewItems,OldItems)
            
            % Call superclass method first
            obj.updateSelectionForNewItems@uix.widget.ListSelector(NewItems,OldItems);
            
            % Ensure the index does not exceed bounds
            obj.InvalidIndex( obj.InvalidIndex > numel(obj.AllItems) ) = [];
            
        end %function
        
        
        function redraw(obj)
            
            % Call superclass constructor
            redraw@uix.widget.ListSelector(obj);
            
            % Ensure the construction is complete
            if obj.IsConstructed
                % Button 1 - Add
                
                % If the selected value from the source listbox is
                % highlighted as invalid, don't do anything
                if strcmp(obj.Enable,'on')
                    
                    % What is currently highlighted in the listbox?
                    SelIdx = obj.h.ListboxSrc.Value;
                    SelEnable = get(obj.h.Button(1),'Enable');
                    if strcmpi(SelEnable,'on')
                        NewEnable = ~any(ismember(SelIdx(:),obj.InvalidIndex(:)));
                        set(obj.h.Button(1), 'Enable', uix.utility.tf2onoff(NewEnable) );
                    end
                    
                end % Else, don't do anything
            end
            
        end %function
        
        
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        % InvalidIndex
        function set.InvalidIndex(obj,value)
            value = value(:);
            if ~isequal(obj.InvalidIndex, value)
                maxVal = numel(obj.AllItems);
                validateattributes(value,{'numeric'},...
                    {'column', 'integer', 'positive', '<=', maxVal})
                obj.InvalidIndex = value;
                redraw(obj)
            end
        end
        
    end % Get/Set methods
    
    
end %classdef