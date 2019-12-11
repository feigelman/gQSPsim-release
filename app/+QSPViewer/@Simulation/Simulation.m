classdef Simulation < uix.abstract.CardViewPane
    % Simulation - View Pane for the object
    % ---------------------------------------------------------------------
    % Display a viewer/editor for the object
    %

    
    %   Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $
    %   $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
  
    %% Private properties
    properties (Access=private)
        DatasetPopupItems = {'-'}
        DatasetPopupItemsWithInvalid = {'-'}
        
        DatasetHeader = {}
        DatasetHeaderPopupItems = {'-'}        
        DatasetHeaderPopupItemsWithInvalid = {'-'}
        
        TaskPopupTableItems = {}
        VPopPopupTableItems = {}
%         GroupPopupTableItems = {}
        
        PlotSpeciesAsInvalidTable = cell(0,2)
        PlotItemAsInvalidTable = cell(0,4)
        PlotDataAsInvalidTable = cell(0,2)
        PlotGroupAsInvalidTable = cell(0,3)
        
        PlotSpeciesInvalidRowIndices = []
        PlotItemInvalidRowIndices = []
        PlotDataInvalidRowIndices = []
        PlotGroupInvalidRowIndices = []
        
    end
    
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);        
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = Simulation(varargin)
            
            % Call superclass constructor
            RunVis = true;
            obj = obj@uix.abstract.CardViewPane(RunVis,varargin{:});
            
            % Create the graphics objects
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Mark construction complete to tell refresh the graphics exist
            obj.IsConstructed = true;
            
            % Refresh the view
            obj.refresh();
            
        end
        
    end %methods
    
    
    %RAJ - for callbacks:
    %notify(obj, 'DataEdited', <eventdata>);
    
    %% Methods from CardViewPane
    methods
        function onPlotConfigChange(obj,h,e)
            
            % Update data first
            Value = get(h,'Value');
            obj.Data.SelectedPlotLayout = obj.PlotLayoutOptions{Value};
            
            onPlotConfigChange@uix.abstract.CardViewPane(obj,h,e);
        end %function
        
        function resize(obj)
            
            Buffer = 40;
            MinimumWidth = 50;
            
            tableObj = [obj.h.ItemsTable,obj.h.PlotSpeciesTable,obj.h.PlotItemsTable,obj.h.PlotDatasetTable,obj.h.PlotGroupTable];
            
            for index = 1:numel(tableObj)
                Pos = get(tableObj(index),'Position');
                if Pos(3) >= MinimumWidth
                    
                    nColumns = numel(tableObj(index).ColumnName);
                    ColumnWidth = (Pos(3)-Buffer)/nColumns;
                    ColumnWidth = repmat(ColumnWidth,1,nColumns);
                    if isa(tableObj(index).HTable,'matlab.ui.control.Table')
                        tableObj(index).HTable.ColumnWidth = num2cell(ColumnWidth);
                    else
                        tableObj(index).HTable.ColumnWidth = ColumnWidth;
                    end
                    
                end
            end %for
        end %function
        
    end %methods
   
    
    %% Callbacks
    methods
        
        function onResize(obj,h,e)
            
            resize(obj);
            
        end %function
        
        function onFolderSelection(vObj,h,evt) %#ok<*INUSD>
            
            % Update the value
            vObj.TempData.SimResultsFolderName = evt.NewValue;
            
            % Update the view
            updateResultsDir(vObj);
            
        end %function
        
        function onDatasetPopup(vObj,h,e)
            
            vObj.TempData.DatasetName = vObj.DatasetPopupItems{get(h,'Value')};
            
            % Update the view
            refreshDataset(vObj);
            
        end %function
        
        function onGroupNamePopup(vObj,h,e)
            
            vObj.TempData.GroupName = vObj.DatasetHeaderPopupItems{get(h,'Value')};
            
            % Update the view
            updateDataset(vObj);
            
        end %function
        
        function onItemsButtonPressed(vObj,h,e)
            
            switch e.Interaction
                
                case 'Add'
                    
                    if ~isempty(vObj.TaskPopupTableItems)
                        NewTaskVPop = QSP.TaskVirtualPopulation;
                        NewTaskVPop.TaskName = vObj.TaskPopupTableItems{1};
                        NewTaskVPop.VPopName = vObj.VPopPopupTableItems{1};
%                         if isempty(vObj.GroupPopupTableItems)
%                             NewTaskVPop.Group = 1;
%                         else
%                             NewTaskVPop.Group = num2str( str2num(vObj.GroupPopupTableItems{end})+1); % default to last
%                         end
                        NewTaskVPop.Group = '';
                        vObj.TempData.Item(end+1) = NewTaskVPop;
                    else
                        hDlg = errordlg('At least one task must be defined in order to add a simulation item.','Cannot Add','modal');
                        uiwait(hDlg);
                    end
                    
                case 'Remove'
                    
                    DeleteIdx = e.Indices;
                    if DeleteIdx <= numel(vObj.TempData.Item)
                        vObj.TempData.Item(DeleteIdx) = [];
                    end
            end

            % Update the view
            refreshItemsTable(vObj, false);

            
        end %function
        
        function onItemsTableEdit(vObj,h,e)
            
            NewData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            % Update entry
            HasChanged = false;
            if ColIdx == 1
                if ~isequal(vObj.TempData.Item(RowIdx).TaskName,NewData{RowIdx,ColIdx})
                    HasChanged = true;                    
                end
                vObj.TempData.Item(RowIdx).TaskName = NewData{RowIdx,ColIdx};
            elseif ColIdx == 3 % Group
                if ~isequal(vObj.TempData.Item(RowIdx).VPopName,NewData{RowIdx,ColIdx})
                    HasChanged = true;                    
                end
                vObj.TempData.Item(RowIdx).Group = NewData{RowIdx,ColIdx};                
            elseif ColIdx == 2 % Vpop
                if ~isequal(vObj.TempData.Item(RowIdx).VPopName,NewData{RowIdx,ColIdx})
                    HasChanged = true;                    
                end
                vObj.TempData.Item(RowIdx).VPopName = NewData{RowIdx,ColIdx};                
            end
            % Clear the MAT file name
            if HasChanged
                vObj.TempData.Item(RowIdx).MATFileName = '';
            end
            
            refreshItemsTable(vObj, false);
           
        end %function
        
        function onItemsTableSelect(vObj,h,e)
            
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            
            h.SelectedRows = RowIdx;
            
            % Update the view
            updateItemsTable(vObj);
            
        end %function
        
        function onSpeciesTablePlot(vObj,h,e)
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            NewAxIdx = str2double(ThisData{RowIdx,1});
            if isnan(NewAxIdx)
                NewAxIdx = [];
            end
                
            
            if ~isequal(vObj.Data.PlotSpeciesTable,[ThisData(:,1) ThisData(:,2) ThisData(:,3)]) || ...
                    ColIdx == 1 || ColIdx == 2 || ColIdx == 4
                
                if ~isempty(RowIdx) && ColIdx == 2
                    NewLineStyle = ThisData{RowIdx,2};
                    setSpeciesLineStyles(vObj.Data,RowIdx,NewLineStyle);
                end
                
                vObj.Data.PlotSpeciesTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);

                if ColIdx == 2
%                     % Style - Note this will change the line styles even
%                     for the patch boundaries
%                     for sIdx = 1:size(vObj.Data.PlotSpeciesTable,1)
%                         axIdx = str2double(vObj.Data.PlotSpeciesTable{sIdx,1});
%                         if ~isnan(axIdx)
%                             Ch = get(vObj.h.SpeciesGroup{sIdx,axIdx},'Children');
%                             HasLineStyle = isprop(Ch,'LineStyle');
%                             set(Ch(HasLineStyle),'LineStyle',vObj.Data.PlotSpeciesTable{sIdx,2});
%                         end
%                     end   
                    
                    AxIndices = NewAxIdx;
                    if isempty(AxIndices)
                        AxIndices = 1:numel(vObj.h.MainAxes);
                    end
                    % Redraw legend
                    [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                        vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup,...
                        'AxIndices',AxIndices);
                    vObj.h.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                    vObj.h.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                    
                elseif ColIdx == 4
                    % Display Name
                    AxIndices = NewAxIdx;
                    if isempty(AxIndices)
                        AxIndices = 1:numel(vObj.h.MainAxes);
                    end
                    % Redraw legend
                    [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                        vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup,...
                        'AxIndices',AxIndices);
                    vObj.h.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                    vObj.h.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                    
                elseif ColIdx == 1
                    % Plot axes
                    sIdx = RowIdx;
                    OldAxIdx = find(~cellfun(@isempty,vObj.h.SpeciesGroup(sIdx,:)),1,'first');
                    
                    % If originally not plotted
                    if isempty(OldAxIdx) && ~isempty(NewAxIdx)
                        vObj.h.SpeciesGroup{sIdx,NewAxIdx} = vObj.h.SpeciesGroup{sIdx,1};
                        % Parent
                        vObj.h.SpeciesGroup{sIdx,NewAxIdx}.Parent = vObj.h.MainAxes(NewAxIdx);
                    elseif ~isempty(OldAxIdx) && isempty(NewAxIdx)
                        vObj.h.SpeciesGroup{sIdx,1} = vObj.h.SpeciesGroup{sIdx,OldAxIdx};
                        % Un-parent
                        vObj.h.SpeciesGroup{sIdx,1}.Parent = matlab.graphics.GraphicsPlaceholder.empty();
                        if OldAxIdx ~= 1
                            vObj.h.SpeciesGroup{sIdx,OldAxIdx} = [];
                        end
                    elseif ~isempty(OldAxIdx) && ~isempty(NewAxIdx)
                        vObj.h.SpeciesGroup{sIdx,NewAxIdx} = vObj.h.SpeciesGroup{sIdx,OldAxIdx};
                        % Re-parent
                        vObj.h.SpeciesGroup{sIdx,NewAxIdx}.Parent = vObj.h.MainAxes(NewAxIdx);                        
                        if OldAxIdx ~= NewAxIdx
                            vObj.h.SpeciesGroup{sIdx,OldAxIdx} = [];
                        end
                    end
                    
                    % Update lines (line widths, marker sizes)
                    updateLines(vObj);
                    
                    AxIndices = [OldAxIdx,NewAxIdx];
                    AxIndices(isnan(AxIndices)) = [];
                    
                    % Redraw legend
                    [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                        vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup,...
                        'AxIndices',AxIndices);
                    vObj.h.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                    vObj.h.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);

                end %if ColIdx
                
                notify(vObj, 'MarkDirty')
            end %if ~isequal
            
        end %function
        
        function onItemsTableSelectionPlot(vObj,h,e)
            
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            
            h.SelectedRows = RowIdx;
             
            % This line is causing issues with edit and selection callbacks
            % with uitables
%             % Update the view
%             updateVisualizationView(vObj);
        end %function  
        
        function onItemsTablePlot(vObj,h,e)
            
            % Temporarily disable column 1 to prevent quick clicking of
            % 'Include'
            OrigColumnEditable = get(h,'ColumnEditable');
            ColumnEditable = OrigColumnEditable;
            ColumnEditable(1) = false;
            set(h,'ColumnEditable',ColumnEditable);
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            vObj.Data.PlotItemTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
            if ColIdx == 6
                % Display name                
                [vObj.h.AxesLegend,vObj.h.AxesLegendChildren] = updatePlots(vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup);
                
            elseif ColIdx == 1
                % Include
                
                % Don't overwrite the output
                updatePlots(vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup,...
                    'RedrawLegend',false);
            end
            
            % Enable column 1
            set(h,'ColumnEditable',OrigColumnEditable);
            notify(vObj, 'MarkDirty')

        end %function
        
        function onDataTablePlot(vObj,h,e)
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            NewAxIdx = str2double(ThisData{RowIdx,1});
            if isnan(NewAxIdx)
                NewAxIdx = [];
            end
            
            h.SelectedRows = RowIdx;
            
            vObj.Data.PlotDataTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
            if ColIdx == 4
                % Display name
                AxIndices = NewAxIdx;
                if isempty(AxIndices)
                    AxIndices = 1:numel(vObj.h.MainAxes);
                end
                % Redraw legend
                [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                    vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup,...
                    'AxIndices',AxIndices);
                vObj.h.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                vObj.h.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);

            elseif ColIdx == 2
                % Style
                for dIdx = 1:size(vObj.Data.PlotDataTable,1)
                    axIdx = str2double(vObj.Data.PlotDataTable{dIdx,1});
                    if ~isnan(axIdx)
                        Ch = get(vObj.h.DatasetGroup{dIdx,axIdx},'Children');
                        HasMarker = isprop(Ch,'Marker');
                        set(Ch(HasMarker),'Marker',vObj.Data.PlotDataTable{dIdx,2});
                    end
                end
                
                AxIndices = NewAxIdx;
                if isempty(AxIndices)
                    AxIndices = 1:numel(vObj.h.MainAxes);
                end
                % Redraw legend
                [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                    vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup,...
                    'AxIndices',AxIndices);
                vObj.h.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                vObj.h.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                    
            elseif ColIdx == 1
                
                dIdx = RowIdx;
                OldAxIdx = find(~cellfun(@isempty,vObj.h.DatasetGroup(dIdx,:)),1,'first');
                
                % If originally not plotted
                if isempty(OldAxIdx) && ~isempty(NewAxIdx)
                    vObj.h.DatasetGroup{dIdx,NewAxIdx} = vObj.h.DatasetGroup{dIdx,1};
                    % Parent
                    vObj.h.DatasetGroup{dIdx,NewAxIdx}.Parent = vObj.h.MainAxes(NewAxIdx);
                elseif ~isempty(OldAxIdx) && isempty(NewAxIdx)
                    vObj.h.DatasetGroup{dIdx,1} = vObj.h.DatasetGroup{dIdx,OldAxIdx};
                    % Un-parent
                    vObj.h.DatasetGroup{dIdx,1}.Parent = matlab.graphics.GraphicsPlaceholder.empty();
                    if OldAxIdx ~= 1
                        vObj.h.DatasetGroup{dIdx,OldAxIdx} = [];
                    end
                elseif ~isempty(OldAxIdx) && ~isempty(NewAxIdx)
                    vObj.h.DatasetGroup{dIdx,NewAxIdx} = vObj.h.DatasetGroup{dIdx,OldAxIdx};
                    % Re-parent
                    vObj.h.DatasetGroup{dIdx,NewAxIdx}.Parent = vObj.h.MainAxes(NewAxIdx);
                    if OldAxIdx ~= NewAxIdx
                        vObj.h.DatasetGroup{dIdx,OldAxIdx} = [];
                    end
                end
                
                AxIndices = [OldAxIdx,NewAxIdx];
                AxIndices(isnan(AxIndices)) = [];
                
                % Redraw legend
                [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                    vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup,...
                    'AxIndices',AxIndices);
                vObj.h.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                vObj.h.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);

            end
            notify(vObj, 'MarkDirty')

        end %function
        
        function onGroupTableSelectionPlot(vObj,h,e)
            
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            
            h.SelectedRows = RowIdx;
            
            % This line is causing issues with edit and selection callbacks
            % with uitables
%             % Update the view
%             updateVisualizationView(vObj);
        end %function        
        
        function onGroupTablePlot(vObj,h,e)
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            vObj.Data.PlotGroupTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
            if ColIdx == 4
                % Display name                
                [vObj.h.AxesLegend,vObj.h.AxesLegendChildren] = updatePlots(vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup);
                
            elseif ColIdx == 1
                % Include
                
                % Don't overwrite the output
                updatePlots(vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup,...
                    'RedrawLegend',false);
                
            end
            notify(vObj, 'MarkDirty')
            
            
        end %function
        
        function onPlotItemsTableContextMenu(vObj,h,e)
            
            SelectedRow = get(vObj.h.PlotItemsTable,'SelectedRows');
            if ~isempty(SelectedRow)
                ThisColor = vObj.Data.PlotItemTable{SelectedRow,2};
                
                NewColor = uisetcolor(ThisColor);
                
                if ~isequal(NewColor,0)
                    vObj.Data.PlotItemTable{SelectedRow,2} = NewColor;
                    
                    itemIdx = SelectedRow;
                    
                    TheseGroups = [vObj.h.SpeciesGroup{:}];
                    for index = 1:numel(TheseGroups)
                        ThisGroup = TheseGroups(index);
                        if ~isvalid(ThisGroup)
                            warning('Encountered deleted handle')
                            return
                        end
                        TheseChildren = get(ThisGroup,'Children');
                        KeepIdx = ~strcmpi(get(TheseChildren,'Tag'),'DummyLine');
                        TheseChildren = TheseChildren(KeepIdx);
                        
                        TheseUserData = get(TheseChildren,'UserData');
                        if iscell(TheseUserData)
                            TheseUserData = vertcat(TheseUserData{:});
                        end
                        % Set the color
                        MatchIdx = ismember(TheseUserData(:,2),itemIdx);
                        
                        TheseItems = TheseChildren(MatchIdx);
                        set(TheseItems(isprop(TheseItems,'Color')),'Color',NewColor);
                        set(TheseItems(isprop(TheseItems,'FaceColor')),'FaceColor',NewColor);
                        notify(vObj, 'MarkDirty')
                        
                    end
                    
                    [vObj.h.AxesLegend,vObj.h.AxesLegendChildren] = updatePlots(vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup);
                    
                    % Update the view
                    updateVisualizationView(vObj);
                    
                end
            else
                hDlg = errordlg('Please select a row first to set new color.','No row selected','modal');
                uiwait(hDlg);
            end
            
        end %function
        
        function onPlotGroupTableContextMenu(vObj,h,e)
            
            SelectedRow = get(vObj.h.PlotGroupTable,'SelectedRows');
            if ~isempty(SelectedRow)
                ThisColor = vObj.Data.PlotGroupTable{SelectedRow,2};
                
                NewColor = uisetcolor(ThisColor);
                
                if ~isequal(NewColor,0)
                    vObj.Data.PlotGroupTable{SelectedRow,2} = NewColor;
                    
                    itemIdx = SelectedRow;
                    
                    TheseGroups = [vObj.h.DatasetGroup{:}];
                    for index = 1:numel(TheseGroups)
                        ThisGroup = TheseGroups(index);
                        TheseChildren = get(ThisGroup,'Children');
                        KeepIdx = ~strcmpi(get(TheseChildren,'Tag'),'DummyLine');
                        TheseChildren = TheseChildren(KeepIdx);
                        
                        TheseUserData = get(TheseChildren,'UserData');
                        if iscell(TheseUserData)
                            TheseUserData = vertcat(TheseUserData{:});
                        end
                        % Set the color
                        MatchIdx = ismember(TheseUserData(:,2),itemIdx);
                        
                        TheseItems = TheseChildren(MatchIdx);
                        set(TheseItems(isprop(TheseItems,'Color')),'Color',NewColor);
                        set(TheseItems(isprop(TheseItems,'FaceColor')),'FaceColor',NewColor);
                    end
                    
                    [vObj.h.AxesLegend,vObj.h.AxesLegendChildren] = updatePlots(vObj.Data,vObj.h.MainAxes,vObj.h.SpeciesGroup,vObj.h.DatasetGroup);
                    
                    % Update the view
                    updateVisualizationView(vObj);
                    notify(vObj, 'MarkDirty')

                end
            else
                hDlg = errordlg('Please select a row first to set new color.','No row selected','modal');
                uiwait(hDlg);
            end
            
        end %function
        
        function onNavigation(vObj,View)
            
            % if changing to simulation configuration view then refresh the
            % tables since vpops and tasks may have changed
            if strcmp(View,'Edit')
                Title = 'Refreshing view';
                hWbar = uix.utility.CustomWaitbar(0,Title,'',false);

                uix.utility.CustomWaitbar(0.5,hWbar,'Refresh Table...');
                % Update the view
                refreshItemsTable(vObj, true);
                uix.utility.CustomWaitbar(1,hWbar,'Done');
                if ~isempty(hWbar) && ishandle(hWbar)
                    delete(hWbar);
                end
            end
            onNavigation@uix.abstract.CardViewPane(vObj,View);
            
        end %function
        
    end
        
    
end %classdef
