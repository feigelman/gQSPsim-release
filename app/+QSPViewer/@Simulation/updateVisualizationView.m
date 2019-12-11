function updateVisualizationView(vObj)
% updateVisualizationView - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateVisualizationView(vObj)
%
% Inputs:
%           vObj - QSPViewer.Simulation vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 331 $  $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
% ---------------------------------------------------------------------

if vObj.Selection ~= 3
    return;
end

%% Update view

if ~isempty(vObj.Data)
    % Check what items are stale or invalid
    [StaleFlag,ValidFlag] = getStaleItemIndices(vObj.Data);
    InvalidItemIndices = ~ValidFlag;    
        
    if all(ValidFlag) && vObj.Selection ~= 2
        set(vObj.h.VisualizeButton,'Enable','on');
    else
        % Navigate to Summary view if not already on it
        if vObj.Selection == 3
            onNavigation(vObj,'Summary');
        end
        set(vObj.h.VisualizeButton,'Enable','off');        
    end
end

%% update plot style
if ~isempty(vObj.Data)
    vObj.Data.bShowTraces = vObj.bShowTraces;
    vObj.Data.bShowQuantiles = vObj.bShowQuantiles;
    vObj.Data.bShowMean = vObj.bShowMean;
    vObj.Data.bShowMedian = vObj.bShowMedian;
    vObj.Data.bShowSD = vObj.bShowSD;
end

%% Update table contextmenus

hFigure = ancestor(vObj.UIContainer,'figure');
% Create context menu
vObj.h.PlotItemsTableContextMenu = uicontextmenu('Parent',hFigure);
uimenu(vObj.h.PlotItemsTableContextMenu,...
    'Label','Set Color...',...
    'Tag','ItemsColor',...
    'Callback',@(h,e)onPlotItemsTableContextMenu(vObj,h,e));
set(vObj.h.PlotItemsTable,'TableContextMenu',vObj.h.PlotItemsTableContextMenu);

% Create context menu
vObj.h.PlotGroupTableContextMenu = uicontextmenu('Parent',hFigure);
uimenu(vObj.h.PlotGroupTableContextMenu,...
    'Label','Set Color...',...
    'Tag','ItemsColor',...
    'Callback',@(h,e)onPlotGroupTableContextMenu(vObj,h,e));
set(vObj.h.PlotGroupTable,'TableContextMenu',vObj.h.PlotGroupTableContextMenu);


%% Get Axes Options for Plot column

AxesOptions = getAxesOptions(vObj);


%% Refresh Species


% List only SpeciesNames from Valid Sim Items, not all Tasks
if ~isempty(vObj.Data)
    
    ItemTaskNames = {vObj.Data.Item.TaskName};
    SpeciesNames = getSpeciesFromValidSelectedTasks(vObj.Data.Settings,ItemTaskNames);
    InvalidIndices = ~ismember(SpeciesNames,vObj.Data.PlotSpeciesTable(:,3));
    
    if isempty(vObj.Data.PlotSpeciesTable)
        % If empty, populate, but first update line styles
        vObj.Data.PlotSpeciesTable = cell(numel(SpeciesNames),4);
        updateSpeciesLineStyles(vObj.Data);
        
        vObj.Data.PlotSpeciesTable(:,1) = {' '};
        vObj.Data.PlotSpeciesTable(:,2) = vObj.Data.SpeciesLineStyles(:);
        vObj.Data.PlotSpeciesTable(:,3) = SpeciesNames;
        vObj.Data.PlotSpeciesTable(:,4) = SpeciesNames;
        
        vObj.PlotSpeciesAsInvalidTable = vObj.Data.PlotSpeciesTable;
        vObj.PlotSpeciesInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(SpeciesNames),4);
        NewPlotTable(:,1) = {' '};
        NewPlotTable(:,2) = {'-'}; % vObj.Data.SpeciesLineStyles(:); % TODO: !!
        NewPlotTable(:,3) = SpeciesNames;
        NewPlotTable(:,4) = SpeciesNames;
        
        % Adjust size if from an old saved session
        if size(vObj.Data.PlotSpeciesTable,2) == 2
            vObj.Data.PlotSpeciesTable(:,3) = vObj.Data.PlotSpeciesTable(:,2);
            vObj.Data.PlotSpeciesTable(:,2) = {'-'};  % TODO: !!
        end
        if size(vObj.Data.PlotSpeciesTable,2) == 3
            vObj.Data.PlotSpeciesTable(:,4) = vObj.Data.PlotSpeciesTable(:,3);
            vObj.Data.PlotSpeciesTable(:,2) = {'-'};  % TODO: !!
        end
        % Update Table
        KeyColumn = 3;
        [vObj.Data.PlotSpeciesTable,vObj.PlotSpeciesAsInvalidTable,vObj.PlotSpeciesInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotSpeciesTable,NewPlotTable,InvalidIndices,KeyColumn);
        % Update line styles
        updateSpeciesLineStyles(vObj.Data);
    end
    
    % Species table
    set(vObj.h.PlotSpeciesTable,...
        'Data',vObj.PlotSpeciesAsInvalidTable,...
        'ColumnName',{'Plot','Style','Name','Display'},...
        'ColumnFormat',{AxesOptions,vObj.Data.Settings.LineStyleMap,'char','char'},...
        'ColumnEditable',[true,true,false,true]...
        );
else
    set(vObj.h.PlotSpeciesTable,...
        'Data',cell(0,4),...
        'ColumnName',{'Plot','Style','Name','Display'},...
        'ColumnFormat',{AxesOptions,'char','char','char'},...
        'ColumnEditable',[true,true,false,true]...
        );
end


%% Refresh Items

if ~isempty(vObj.Data)
    
    TaskNames = {vObj.Data.Item.TaskName};
    VPopNames = {vObj.Data.Item.VPopName};
    Groups    = {vObj.Data.Item.Group};

%       InvalidItemIndices = false(size(TaskNames));
%     for idx = 1:numel(TaskNames)
%         % Check if the task is valid
%         ThisTask = getValidSelectedTasks(vObj.Data.Settings,TaskNames{idx});
%         ThisVPop = getValidSelectedVPops(vObj.Data.Settings,VPopNames{idx});
%         if isempty(ThisTask) || isempty(ThisVPop)
%             InvalidItemIndices(idx) = true;
%         end
%     end
    
    % If empty, populate
    if isempty(vObj.Data.PlotItemTable)
        
        if any(InvalidItemIndices)
            % Then, prune
            TaskNames(InvalidItemIndices) = [];
            VPopNames(InvalidItemIndices) = [];
        end
        
        vObj.Data.PlotItemTable = cell(numel(TaskNames),6);
        vObj.Data.PlotItemTable(:,1) = {false};
        vObj.Data.PlotItemTable(:,3) = TaskNames;
        vObj.Data.PlotItemTable(:,4) = VPopNames;
        vObj.Data.PlotItemTable(:,5) = Groups;
        vObj.Data.PlotItemTable(:,6) = cellfun(@(x,y)sprintf('%s - %s',x,y),TaskNames,VPopNames,'UniformOutput',false);
        
        % Update the item colors
        ItemColors = getItemColors(vObj.Data.Session,numel(TaskNames));
        vObj.Data.PlotItemTable(:,2) = num2cell(ItemColors,2);
        
        vObj.PlotItemAsInvalidTable = vObj.Data.PlotItemTable;
        vObj.PlotItemInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(TaskNames),4);
        NewPlotTable(:,1) = {false};
        NewPlotTable(:,3) = TaskNames;
        NewPlotTable(:,4) = VPopNames;
        NewPlotTable(:,5) = Groups;
        NewPlotTable(:,6) = cellfun(@(x,y)sprintf('%s - %s',x,y),TaskNames,VPopNames,'UniformOutput',false);
        
        NewColors = getItemColors(vObj.Data.Session,numel(TaskNames));
        NewPlotTable(:,2) = num2cell(NewColors,2);   
        
        if size(vObj.Data.PlotItemTable,2) == 5
            vObj.Data.PlotItemTable(:,6) = cellfun(@(x,y)sprintf('%s - %s',x,y),vObj.Data.PlotItemTable(:,3),vObj.Data.PlotItemTable(:,4),'UniformOutput',false);
        end
        
        % Update Table
        KeyColumn = [3 4 5];
        [vObj.Data.PlotItemTable,vObj.PlotItemAsInvalidTable,vObj.PlotItemInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotItemTable,NewPlotTable,InvalidItemIndices,KeyColumn);
    end
    
    % Check which results files are invalid
    ResultsDir = fullfile(vObj.Data.Session.RootDirectory,vObj.Data.SimResultsFolderName);
    
    % Only make the "valids" missing. Leave the invalids as is
    TableData = vObj.PlotItemAsInvalidTable;

    if ~isempty(TableData)
        TaskNames = {vObj.Data.Item.TaskName};
        VPopNames = {vObj.Data.Item.VPopName};
        Groups = {vObj.Data.Item.Group};
        
        for index = 1:size(vObj.Data.PlotItemTable,1)
            % Check to see if this row is invalid. If it is not invalid,
            % check to see if we need to mark the corresponding file as missing
            if ~ismember(vObj.PlotItemInvalidRowIndices,index)
                ThisTaskName = vObj.Data.PlotItemTable{index,3};
                ThisVPopName = vObj.Data.PlotItemTable{index,4};
                ThisGroup = vObj.Data.PlotItemTable{index,5};
                MatchIdx = strcmp(ThisTaskName,TaskNames) & strcmp(ThisVPopName,VPopNames) & strcmp(ThisGroup, Groups);
                if any(MatchIdx)
                    ThisFileName = vObj.Data.Item(MatchIdx).MATFileName;
                    % Mark results file as missing
                    if ~isequal(exist(fullfile(ResultsDir,ThisFileName),'file'),2)
                        TableData{index,3} = QSP.makeItalicized(TableData{index,3});
                        TableData{index,4} = QSP.makeItalicized(TableData{index,4});
                    end
                end %if
            end %if
        end %for
    end %if
    
    % Update Colors column
    TableData(:,2) = uix.utility.getHTMLColor(vObj.Data.PlotItemTable(:,2));
    % Items table
    if any(StaleFlag)
        ThisLabel = 'Simulation Items (Items are not up-to-date)';
    else
        ThisLabel = 'Simulation Items';
    end
    set(vObj.h.PlotItemsTable,...
        'LabelString',ThisLabel,...
        'Data',TableData,...
        'ColumnName',{'Include','Color','Task','Virtual Subject(s)','Group','Display'},...
        'ColumnFormat',{'boolean','char','char','char','numeric','char'},...
        'ColumnEditable',[true,false,false,false,false,true]...
        );
    % Set cell color
    for index = 1:size(TableData,1)
        ThisColor = vObj.Data.PlotItemTable{index,2};
        if ~isempty(ThisColor)
            vObj.h.PlotItemsTable.setCellColor(index,2,ThisColor);
        end
    end
else
    % Items table
    set(vObj.h.PlotItemsTable,...
        'Data',cell(0,6),...
        'ColumnName',{'Include','Color','Task','Virtual Subject(s)','Group','Display'},...
        'ColumnFormat',{'boolean','char','char','char','numeric','char'},...
        'ColumnEditable',[true,false,false,false,false,true]...
        );
end


%% Refresh DataCol

OptimHeader = {};
OptimData = {};

% DatasetHeaderPopupItems corresponds to header in DatasetName
if ~isempty(vObj.Data) && ~isempty(vObj.Data.DatasetName)
    Names = {vObj.Data.Settings.OptimizationData.Name};
    MatchIdx = strcmpi(Names,vObj.Data.DatasetName);
    
    if any(MatchIdx)
        dObj = vObj.Data.Settings.OptimizationData(MatchIdx);
        
        DestDatasetType = 'wide';
        [StatusOk,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
        if StatusOk
            % Prune to remove Time, Group, etc.
            DatasetHeaderPopupItems = setdiff(OptimHeader,{'Time','Group'});
        else
            DatasetHeaderPopupItems = {};
        end
    else
        DatasetHeaderPopupItems = {};
    end
    
    % Adjust size if from an old saved session
    if size(vObj.Data.PlotDataTable,2) == 2
        vObj.Data.PlotDataTable(:,3) = vObj.Data.PlotDataTable(:,2);
        vObj.Data.PlotDataTable(:,2) = {'*'};  % TODO: !!
    end
    if size(vObj.Data.PlotDataTable,2) == 3
        vObj.Data.PlotDataTable(:,4) = vObj.Data.PlotDataTable(:,3);
    end
    
    InvalidIndices = ~ismember(DatasetHeaderPopupItems,vObj.Data.PlotDataTable(:,3));
    
    % If empty, populate
    if isempty(vObj.Data.PlotDataTable)
        vObj.Data.PlotDataTable = cell(numel(DatasetHeaderPopupItems),4);
        vObj.Data.PlotDataTable(:,1) = {' '};
        vObj.Data.PlotDataTable(:,2) = {'*'}; % TODO: !!
        vObj.Data.PlotDataTable(:,3) = DatasetHeaderPopupItems;
        vObj.Data.PlotDataTable(:,4) = DatasetHeaderPopupItems;
        
        vObj.PlotDataAsInvalidTable = vObj.Data.PlotDataTable;
        vObj.PlotDataInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(DatasetHeaderPopupItems),4);
        NewPlotTable(:,1) = {' '};
        NewPlotTable(:,2) = {'*'}; % TODO: !!
        NewPlotTable(:,3) = DatasetHeaderPopupItems;
        NewPlotTable(:,4) = DatasetHeaderPopupItems;
        
        % Update Table
        KeyColumn = 3;
        [vObj.Data.PlotDataTable,vObj.PlotDataAsInvalidTable,vObj.PlotDataInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotDataTable,NewPlotTable,InvalidIndices,KeyColumn);
    end
    
    % Dataset table
    set(vObj.h.PlotDatasetTable,...
        'Data',vObj.PlotDataAsInvalidTable,...
        'ColumnName',{'Plot','Marker','Name','Display'},...
        'ColumnFormat',{AxesOptions,vObj.Data.Settings.LineMarkerMap,'char','char'},...
        'ColumnEditable',[true,true,false,true]...
        );
else
    % Dataset table
    set(vObj.h.PlotDatasetTable,...
        'Data',cell(0,4),...
        'ColumnName',{'Plot','Marker','Name','Display'},...
        'ColumnFormat',{AxesOptions,'char','char','char'},...
        'ColumnEditable',[true,true,false,true]...
        );
end


%% Refresh GroupID

if ~isempty(vObj.Data) && ~isempty(OptimData)
    MatchIdx = strcmp(OptimHeader,vObj.Data.GroupName);
    GroupIDs = OptimData(:,MatchIdx);
    if iscell(GroupIDs)
        GroupIDs = cell2mat(GroupIDs);
    end
    GroupIDs = unique(GroupIDs);
    GroupIDNames = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
    
    InvalidIndices = ~ismember(GroupIDNames,vObj.Data.PlotGroupTable(:,3));
    
    % If empty, populate
    if isempty(vObj.Data.PlotGroupTable)
        vObj.Data.PlotGroupTable = cell(numel(GroupIDNames),4);
        vObj.Data.PlotGroupTable(:,1) = {false};
        vObj.Data.PlotGroupTable(:,3) = GroupIDNames;
        vObj.Data.PlotGroupTable(:,4) = GroupIDNames;
        
        % Update the group colors
        GroupColors = getGroupColors(vObj.Data.Session,numel(GroupIDNames));
        vObj.Data.PlotGroupTable(:,2) = num2cell(GroupColors,2);
        
        vObj.PlotGroupAsInvalidTable = vObj.Data.PlotGroupTable;
        vObj.PlotGroupInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(GroupIDNames),4);
        NewPlotTable(:,1) = {false};
        NewPlotTable(:,3) = GroupIDNames;
        NewPlotTable(:,4) = GroupIDNames;
        
        NewColors = getGroupColors(vObj.Data.Session,numel(GroupIDNames));
        NewPlotTable(:,2) = num2cell(NewColors,2);   
        
        % Update Table
        KeyColumn = 3;
        [vObj.Data.PlotGroupTable,vObj.PlotGroupAsInvalidTable,vObj.PlotGroupInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotGroupTable,NewPlotTable,InvalidIndices,KeyColumn);
        
    end
    
    % Update Colors column
    TableData = vObj.PlotGroupAsInvalidTable;
    TableData(:,2) = uix.utility.getHTMLColor(vObj.PlotGroupAsInvalidTable(:,2));
    % Group table
    set(vObj.h.PlotGroupTable,...
        'Data',TableData,...
        'ColumnName',{'Include','Color','Name','Display'},...
        'ColumnFormat',{'boolean','char','char','char'},...
        'ColumnEditable',[true,false,false,true]...
        );
    % Set cell color
    for index = 1:size(TableData,1)
        ThisColor = vObj.Data.PlotGroupTable{index,2};
        if ~isempty(ThisColor)
            if ischar(ThisColor) %html string
                rgb = regexp(ThisColor, 'bgcolor="#(\w{2})(\w{2})(\w{2})', 'tokens');
                rgb = rgb{1};
                ThisColor = [hex2dec(rgb{1}), hex2dec(rgb{2}), hex2dec(rgb{3})]/255;
            end
            vObj.h.PlotGroupTable.setCellColor(index,2,ThisColor);
        end
    end
    
else
    % Group table
    set(vObj.h.PlotGroupTable,...
        'Data',cell(0,4),...
        'ColumnName',{'Include','Color','Name','Display'},...
        'ColumnFormat',{'boolean','char','char','char'},...
        'ColumnEditable',[true,false,false,true]...
        );
end




