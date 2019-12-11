classdef VirtualPopulationGeneration < uix.abstract.CardViewPane
    % VirtualPopulationGeneration - View Pane for the object
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
    properties (SetAccess=private)
        DatasetPopupItems = {'-'}
        DatasetPopupItemsWithInvalid = {'-'}
        
        DatasetGroupPopupItems = {'-'}        
        DatasetGroupPopupItemsWithInvalid = {'-'}
        
        VpopPopupItems = {'-'}   
        VpopPopupItemsWithInvalid = {'-'}

        MethodItems = {'Maximum likelihood'; 'Bayesian'}   
        MethodItemsWithInvalid = {'-'}
        
        TaskPopupTableItems = {}
        GroupIDPopupTableItems = {}
        SpeciesPopupTableItems = {} % From Tasks
        
        DatasetHeader = {}
        DatasetDataColumn = {}
        DatasetData = {};
        
        ParametersHeader = {} % From RefParamName
        ParametersData = {} % From RefParamName
               
        PlotSpeciesAsInvalidTable = cell(0,3)
        PlotItemAsInvalidTable = cell(0,4)
        
        PlotSpeciesInvalidRowIndices = []
        PlotItemInvalidRowIndices = []       
        
        ShowTraces = true;
        ShowSEBar = false;
    end
    
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = VirtualPopulationGeneration(varargin)
            
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
       end
        
       function resize(obj)
            
            Buffer = 40;
            MinimumWidth = 50;
            
            tableObj = [obj.h.ItemsTable,obj.h.SpeciesDataTable,obj.h.PlotSpeciesTable,obj.h.PlotItemsTable];
            
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
        
    end % methods
    
    
    %% Callbacks
    methods
        
        function onResize(obj,h,e)
            
            resize(obj);
            
        end %function
        
        function onFolderSelection(vObj,~,evt) %#ok<*INUSD>
            
            % Update the value
            vObj.TempData.VPopResultsFolderName = evt.NewValue;
            
            % Update the view
            updateResultsDir(vObj);
            
        end %function
        
        function onICFileSelection(vObj,~,e)
            % Update IC value
            vObj.TempData.ICFileName = e.NewValue;
  
        end
        
        function onCohortPopup(vObj,h,e)
            
            vObj.TempData.DatasetName = vObj.DatasetPopupItems{get(h,'Value')};
            
            % Update the view
            refreshDataset(vObj);
            refreshItemsTable(vObj);
            refreshSpeciesDataTable(vObj);
            
        end %function

        function onVpopGenDataPopup(vObj,h,e)
            
            vObj.TempData.VpopGenDataName = vObj.VpopPopupItems{get(h,'Value')};
            
            % Update the view
            refreshDataset(vObj);
            refreshItemsTable(vObj);
            refreshSpeciesDataTable(vObj);
            
        end %function
        
        function onMethodPopup(vObj,h,e)
            vObj.TempData.MethodName = vObj.MethodItems{get(h,'Value')};
            
            % Update the view
            refreshDataset(vObj);
            refreshItemsTable(vObj);
            refreshSpeciesDataTable(vObj);
            
        end %function
        
        function onRedistributeWeightsCheck(vObj,h,e)
            vObj.TempData.RedistributeWeights = get(h,'Value');

            % Update the view
            refreshDataset(vObj);
            refreshItemsTable(vObj);
            refreshSpeciesDataTable(vObj);
            
        end
        
        function onParametersPopup(vObj,h,e)
            
            vObj.TempData.RefParamName = vObj.ParameterPopupItems{get(h,'Value')};
            
            % Try importing to load data for Parameters view
            MatchIdx = strcmp({vObj.TempData.Settings.Parameters.Name},vObj.TempData.RefParamName);
            if any(MatchIdx)
                pObj = vObj.TempData.Settings.Parameters(MatchIdx);
                [StatusOk,Message,vObj.ParametersHeader,vObj.ParametersData] = importData(pObj,pObj.FilePath);
                if ~StatusOk
                    hDlg = errordlg(Message,'Parameter Import Failed','modal');
                    uiwait(hDlg);
                end
            end
            
            % Update the view
            refreshParameters(vObj);
            
        end %function
        
        function onGroupNamePopup(vObj,h,e)
            
            vObj.TempData.GroupName = vObj.DatasetGroupPopupItems{get(h,'Value')};
            
            % Update the view
            updateDataset(vObj);
            refreshItemsTable(vObj);
            
        end %function
        
        function onTableButtonPressed(vObj,~,e,TableTag)
            
            FlagRefreshTables = true;
            
            switch e.Interaction
                
                case 'Add'
                    
                    if strcmpi(TableTag,'OptimItems')
                        if ~isempty(vObj.TaskPopupTableItems) && ~isempty(vObj.GroupIDPopupTableItems)
                            NewTaskGroup = QSP.TaskGroup;
                            NewTaskGroup.TaskName = vObj.TaskPopupTableItems{1};
                            NewTaskGroup.GroupID = vObj.GroupIDPopupTableItems{1};
                            vObj.TempData.Item(end+1) = NewTaskGroup;
                        else
                            hDlg = errordlg('At least one task and the group column must be defined in order to add an optimization item.','Cannot Add','modal');
                            uiwait(hDlg);
                            FlagRefreshTables = false;
                        end
                            
                    elseif strcmpi(TableTag,'SpeciesData')
                        if ~isempty(vObj.SpeciesPopupTableItems) && ~isempty(vObj.DatasetDataColumn)
                            NewSpeciesData = QSP.SpeciesData;
                            NewSpeciesData.SpeciesName = vObj.SpeciesPopupTableItems{1};
                            NewSpeciesData.DataName = vObj.DatasetDataColumn{1};
                            DefaultExpression = 'x';
                            NewSpeciesData.FunctionExpression = DefaultExpression;
                            vObj.TempData.SpeciesData(end+1) = NewSpeciesData;
                        else
                            hDlg = errordlg('At least one task with active species and a non-empty ''Species'' column in the dataset must be defined in order to add an optimization item.','Cannot Add','modal');
                            uiwait(hDlg);
                            FlagRefreshTables = false;
                        end
                    end
                    
                case 'Remove'
                    
                    DeleteIdx = e.Indices;
                    
                    if DeleteIdx <= numel(vObj.TempData.Item) && strcmpi(TableTag,'OptimItems')
                        vObj.TempData.Item(DeleteIdx) = [];
                    elseif DeleteIdx <= numel(vObj.TempData.SpeciesData) && strcmpi(TableTag,'SpeciesData')
                        vObj.TempData.SpeciesData(DeleteIdx) = [];
                    else
                        FlagRefreshTables = false;
                    end
            end
                
            % Update the view
            if FlagRefreshTables
                if strcmpi(TableTag,'OptimItems')
                    Title = 'Refreshing view';
                    hWbar = uix.utility.CustomWaitbar(0,Title,'',false);
                    
                    % Tasks => Species
                    uix.utility.CustomWaitbar(0.5,hWbar,'Refresh Tables...');
                    refreshItemsTable(vObj);
                    refreshSpeciesDataTable(vObj);
                    
                    uix.utility.CustomWaitbar(1,hWbar,'Done');
                    if ~isempty(hWbar) && ishandle(hWbar)
                        delete(hWbar);
                    end
                    
                elseif strcmpi(TableTag,'SpeciesData')
                    refreshSpeciesDataTable(vObj);
                end
            end
            
        end %function
        
        function onTableEdit(vObj,h,e,TableTag)
            
            NewData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            % Update entry
            if strcmpi(TableTag,'OptimItems')            
                if ColIdx == 1
                    vObj.TempData.Item(RowIdx).TaskName = NewData{RowIdx,1};            
                elseif ColIdx == 2
                    vObj.TempData.Item(RowIdx).GroupID = NewData{RowIdx,2};
                end
                
            elseif strcmpi(TableTag,'SpeciesData')
                if ColIdx == 2
                    vObj.TempData.SpeciesData(RowIdx).SpeciesName = NewData{RowIdx,2};
                elseif ColIdx == 4
                    vObj.TempData.SpeciesData(RowIdx).FunctionExpression = NewData{RowIdx,4};
                elseif ColIdx == 1
                    vObj.TempData.SpeciesData(RowIdx).DataName = NewData{RowIdx,1};
                elseif ColIdx == 5
                    vObj.TempData.SpeciesData(RowIdx).ObjectiveName = NewData{RowIdx,5};
                end
                
            end
            
            % Update the view
            if strcmpi(TableTag,'OptimItems')
                Title = 'Refreshing view';
                hWbar = uix.utility.CustomWaitbar(0,Title,'',false);
                
                % Tasks => Species
                uix.utility.CustomWaitbar(0.5,hWbar,'Refresh Tables...');
                refreshItemsTable(vObj);
                refreshSpeciesDataTable(vObj);
                
                uix.utility.CustomWaitbar(1,hWbar,'Done');
                if ~isempty(hWbar) && ishandle(hWbar)
                    delete(hWbar);
                end
                
            elseif strcmpi(TableTag,'SpeciesData')
                refreshSpeciesDataTable(vObj);
            end
            
        end %function
        
        function onTableSelect(vObj,h,e,TableTag)
            
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            RowIdx = Indices(1,1);
            
            h.SelectedRows = RowIdx;
            
            % Update the view
            if strcmpi(TableTag,'OptimItems')
                updateItemsTable(vObj);                
            elseif strcmpi(TableTag,'SpeciesData')
                updateSpeciesDataTable(vObj);
            end
            
        end %function
        
        function onMinNumVirtualPatientsEdit(vObj,h,e)
            
            try
                vObj.TempData.MinNumVirtualPatients = str2double(get(h,'Value'));
            catch ME
                hDlg = errordlg(ME.message,'Invalid Value','modal');
                uiwait(hDlg);
            end
            
            % Update the view
            updateMinNumVirtualPatients(vObj);
            
        end %function
        
        function onPlotParameterDistributionDiagnostics(vObj,h,e)
            
            if ~isempty(vObj.Data.VPopName)
                h = figure('Name', 'Parameter Distribution Diagnostic'); %, 'Units', 'pixels', 'Position', [0 0 1000 1000]);
                p = uix.ScrollingPanel('Parent', h, 'Units', 'Normalized', 'Position', [0 0 1 1]); %,  'Units', 'pixels', 'Position', [0 0 1000 600]);

                vpopFile = fullfile(vObj.Data.FilePath, vObj.Data.VPopResultsFolderName, vObj.Data.ExcelResultFileName);                
                try
                    Raw = readtable(vpopFile);
                    ParamNames = Raw.Properties.VariableNames;
                    Raw = [ParamNames;table2cell(Raw)];                    
                catch err
                    warning('Could not open vpop xlsx file.')
                    disp(err)
                    return
                end
                
                % Get the parameter values (everything but the header)
                if size(Raw,1) > 1
                    ParamValues = cell2mat(Raw(2:end,:));
                else
                    ParamValues = [];
                end
                    
                nCol = size(Raw,2);
               
                g = uix.Grid('Parent', p); %,  'Units', 'pixels', 'Position', [0 0 200*dims(1) 200*dims(2)], 'Spacing', 1);
                MatchIdx = find(strcmp(vObj.Data.RefParamName,{vObj.Data.Settings.Parameters.Name}));
                
                LB = [];
                UB = [];                
                if ~isempty(MatchIdx)
                    try
                        Raw = readtable(vObj.Data.Settings.Parameters(MatchIdx).FilePath);
                        LB = Raw.LB;
                        UB = Raw.UB;
                    catch err
                        warning('Could not open parameters xlsx file or LB and/or UB column headers are missing. Setting lower and upper bounds to empty.')
                        disp(err)                       
                    end
                end
                
                for k=1:nCol
                    ax=axes('Parent', g);
                    hist(ax, ParamValues(:,k))
                    if k <= length(LB)
                        h2(1)=line(LB(k)*ones(1,2), get(ax,'YLim'));
                        h2(2)=line(UB(k)*ones(1,2), get(ax,'YLim'));
                        set(h2,'LineStyle','--','Color','r')
                    end
                    title(ax, ParamNames{k}, 'Interpreter', 'none')
                    set(ax, 'TitleFontWeight', 'bold' )
                end          
                
                % add empty placeholders
                for k=(nCol+1):3*ceil(nCol/3)
                    uix.Empty('Parent', g)
                end

                set(g, 'Widths', 300*ones(1,3), 'Heights', 300*ones(1,ceil(nCol/3)));
                set(p, 'Widths', 900, 'Heights', 300*ceil(nCol/3))
                
            end
%             uiwait(h)
            
            
        end %function
        
        function onSpeciesDataTablePlot(vObj,h,e)
            
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
            
            
            if ~isequal(vObj.Data.PlotSpeciesTable,[ThisData(:,1) ThisData(:,2) ThisData(:,3) ThisData(:,4)]) || ...
                    ColIdx == 1 || ColIdx == 2 || ColIdx == 5
                
                vObj.Data.PlotSpeciesTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
                
                if ~isempty(RowIdx) && ColIdx == 2
                    NewLineStyle = ThisData{RowIdx,2};
                    setSpeciesLineStyles(vObj.Data,RowIdx,NewLineStyle);
                end
                
%                 if ColIdx == 5
%                     % Display name
%                     for sIdx = 1:size(vObj.Data.PlotSpeciesTable,1)
%                         axIdx = str2double(vObj.Data.PlotSpeciesTable{sIdx,1});
%                         if ~isnan(axIdx)
%                             set(vObj.h.SpeciesGroup{sIdx,axIdx},'DisplayName',regexprep(vObj.Data.PlotSpeciesTable{sIdx,5},'_','\\_')); 
%                         end
%                     end           
%                     % No need to call redraw legend
                    
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
%                     
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
                    
                elseif ColIdx == 5
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
                        vObj.h.DatasetGroup{sIdx,NewAxIdx} = vObj.h.DatasetGroup{sIdx,1};
                        % Parent
                        vObj.h.SpeciesGroup{sIdx,NewAxIdx}.Parent = vObj.h.MainAxes(NewAxIdx);
                        vObj.h.DatasetGroup{sIdx,NewAxIdx}.Parent = vObj.h.MainAxes(NewAxIdx);
                    elseif ~isempty(OldAxIdx) && isempty(NewAxIdx)
                        vObj.h.SpeciesGroup{sIdx,1} = vObj.h.SpeciesGroup{sIdx,OldAxIdx};
                        vObj.h.DatasetGroup{sIdx,1} = vObj.h.DatasetGroup{sIdx,OldAxIdx};
                        % Un-parent
                        vObj.h.SpeciesGroup{sIdx,1}.Parent = matlab.graphics.GraphicsPlaceholder.empty();
                        vObj.h.DatasetGroup{sIdx,1}.Parent = matlab.graphics.GraphicsPlaceholder.empty();
                        if OldAxIdx ~= 1
                            vObj.h.SpeciesGroup{sIdx,OldAxIdx} = [];
                            vObj.h.DatasetGroup{sIdx,OldAxIdx} = [];
                        end
                    elseif ~isempty(OldAxIdx) && ~isempty(NewAxIdx)
                        vObj.h.SpeciesGroup{sIdx,NewAxIdx} = vObj.h.SpeciesGroup{sIdx,OldAxIdx};
                        vObj.h.DatasetGroup{sIdx,NewAxIdx} = vObj.h.DatasetGroup{sIdx,OldAxIdx};
                        % Re-parent
                        vObj.h.SpeciesGroup{sIdx,NewAxIdx}.Parent = vObj.h.MainAxes(NewAxIdx);
                        vObj.h.DatasetGroup{sIdx,NewAxIdx}.Parent = vObj.h.MainAxes(NewAxIdx);
                        if OldAxIdx ~= NewAxIdx
                            vObj.h.SpeciesGroup{sIdx,OldAxIdx} = [];
                            vObj.h.DatasetGroup{sIdx,OldAxIdx} = [];
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
            end %if ~isequal
            
        end %function
        
        function onItemsTableSelectionPlot(vObj,h,e) %#ok<INUSL>
            
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
            
            if ColIdx == 5
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
            
        end %function
        
        function onPlotItemsTableContextMenu(vObj,h,e)
            
            SelectedRow = get(vObj.h.PlotItemsTable,'SelectedRows');
            if ~isempty(SelectedRow)
                ThisColor = vObj.Data.PlotItemTable{SelectedRow,2};
                
                NewColor = uisetcolor(ThisColor);
                
                if ~isequal(NewColor,0)
                    vObj.Data.PlotItemTable{SelectedRow,2} = NewColor;
                    
                    itemIdx = SelectedRow;
                    
                    TheseSpeciesGroups = [vObj.h.SpeciesGroup{:}];
                    for index = 1:numel(TheseSpeciesGroups)
                        ThisGroup = TheseSpeciesGroups(index);
                        if ~isvalid(ThisGroup)
                            warning('Encountered deleted handle')
                            return
                        end
                        TheseChildren = get(ThisGroup,'Children');
                        KeepIdx = ...
                            ~strcmpi(get(TheseChildren,'Tag'),'DummyLine') & ...
                            ~strcmpi(get(TheseChildren,'Tag'),'InvalidVP');
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
                    
                    TheseDataGroups = [vObj.h.DatasetGroup{:}];
                    for index = 1:numel(TheseDataGroups)
                        ThisGroup = TheseDataGroups(index);
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
        
        function onNavigation(vObj,View)
            
            onNavigation@uix.abstract.CardViewPane(vObj,View);
            
        end %function
        
    end
    
    
end %classdef
