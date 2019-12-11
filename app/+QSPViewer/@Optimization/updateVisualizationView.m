function updateVisualizationView(vObj)
% updateVisualizationView - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateVisualizationView(vObj)
%
% Inputs:
%           vObj - QSPViewer.Optimization vObject
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

%% Update table contextmenu

hFigure = ancestor(vObj.UIContainer,'figure');
% Create context menu
vObj.h.PlotItemsTableContextMenu = uicontextmenu('Parent',hFigure);    
uimenu(vObj.h.PlotItemsTableContextMenu,...
    'Label','Set Color...',...
    'Tag','ItemsColor',...
    'Callback',@(h,e)onPlotItemsTableContextMenu(vObj,h,e));    
set(vObj.h.PlotItemsTable,'TableContextMenu',vObj.h.PlotItemsTableContextMenu);


%% Get Axes Options for Plot column

AxesOptions = getAxesOptions(vObj);


%% Re-import OptimizationData

if ~isempty(vObj.Data) && ~isempty(vObj.Data.DatasetName) && ~isempty(vObj.Data.Settings.OptimizationData)
    Names = {vObj.Data.Settings.OptimizationData.Name};
    MatchIdx = strcmpi(Names,vObj.Data.DatasetName);
    
    if any(MatchIdx)
        dObj = vObj.Data.Settings.OptimizationData(MatchIdx);
        
        DestDatasetType = 'wide';
        [~,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
    else
        OptimHeader = {};
        OptimData = {};
    end
else
    OptimHeader = {};
    OptimData = {};
end


% Get the group column
% GroupID
if ~isempty(OptimHeader) && ~isempty(OptimData)
    MatchIdx = strcmp(OptimHeader,vObj.Data.GroupName);
    GroupIDs = OptimData(:,MatchIdx);
    if iscell(GroupIDs)
        GroupIDs = cell2mat(GroupIDs);
    end
    GroupIDs = unique(GroupIDs);
    GroupIDs = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
else
    GroupIDs = [];
end


%% Refresh Items

if ~isempty(vObj.Data)
    
    % Get the raw TaskNames, GroupIDNames
    TaskNames = {vObj.Data.Item.TaskName};
    GroupIDNames = {vObj.Data.Item.GroupID};
    
    InvalidIndices = false(size(TaskNames));
    for idx = 1:numel(TaskNames)
        % Check if the task is valid
        ThisTask = getValidSelectedTasks(vObj.Data.Settings,TaskNames{idx});
        MissingGroup = ~ismember(GroupIDNames{idx},GroupIDs(:)');
        if isempty(ThisTask) || MissingGroup
            InvalidIndices(idx) = true;
        end
    end
    
    % If empty, populate
    if isempty(vObj.Data.PlotItemTable)
        
        if any(InvalidIndices)
            % Then, prune
            TaskNames(InvalidIndices) = [];
            GroupIDNames(InvalidIndices) = [];
        end
        
        vObj.Data.PlotItemTable = cell(numel(TaskNames),5);
        vObj.Data.PlotItemTable(:,1) = {false};
        vObj.Data.PlotItemTable(:,3) = TaskNames;
        vObj.Data.PlotItemTable(:,4) = GroupIDNames;
        vObj.Data.PlotItemTable(:,5) = TaskNames;
        
        % Update the item colors
        ItemColors = getItemColors(vObj.Data.Session,numel(TaskNames));
        vObj.Data.PlotItemTable(:,2) = num2cell(ItemColors,2);        
        
        vObj.PlotItemAsInvalidTable = vObj.Data.PlotItemTable;
        vObj.PlotItemInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(TaskNames),5);
        NewPlotTable(:,1) = {false};
        NewPlotTable(:,3) = TaskNames;
        NewPlotTable(:,4) = GroupIDNames;
        NewPlotTable(:,5) = TaskNames;
        
        NewColors = getItemColors(vObj.Data.Session,numel(TaskNames));
        NewPlotTable(:,2) = num2cell(NewColors,2);   
        
        if size(vObj.Data.PlotItemTable,2) == 4
            vObj.Data.PlotItemTable(:,5) = vObj.Data.PlotItemTable(:,3);
        end
        
        % Update Table
        KeyColumn = [3 4];
        [vObj.Data.PlotItemTable,vObj.PlotItemAsInvalidTable,vObj.PlotItemInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotItemTable,NewPlotTable,InvalidIndices,KeyColumn);        
    end

    % Update Colors column 
    TableData = vObj.PlotItemAsInvalidTable;
    TableData(:,2) = uix.utility.getHTMLColor(vObj.Data.PlotItemTable(:,2));
    % Items table

    hSelect = vObj.h.PlotItemsTable.CellSelectionCallback;
    hEdit = vObj.h.PlotItemsTable.CellEditCallback;
    vObj.h.PlotItemsTable.CellSelectionCallback = [];
    vObj.h.PlotItemsTable.CellEditCallback = [];
    set(vObj.h.PlotItemsTable,...
        'Data',TableData,...
        'ColumnName',{'Include','Color','Task','Group','Display'},...
        'ColumnFormat',{'boolean','char','char','char','char'},...
        'ColumnEditable',[true,false,false,false,true]...
        );
    vObj.h.PlotItemsTable.CellSelectionCallback = hSelect;
    vObj.h.PlotItemsTable.CellEditCallback = hEdit;
    
    % Set cell color
    for index = 1:size(TableData,1)
        ThisColor = vObj.Data.PlotItemTable{index,2};
        if ~isempty(ThisColor)
            if isnumeric(ThisColor)
                vObj.h.PlotItemsTable.setCellColor(index,2,ThisColor);
            else
                warning('Error: invalid color')
            end
        end
    end
else
    % Items table
    set(vObj.h.PlotItemsTable,...
        'Data',cell(0,5),...
        'ColumnName',{'Include','Color','Task','Group','Display'},...
        'ColumnFormat',{'boolean','char','char','char','char'},...
        'ColumnEditable',[true,false,false,false,true]...
        );
end


%% Refresh Species-Data

if ~isempty(vObj.Data)
    % Get the raw SpeciesNames, DataNames
    TaskNames = {vObj.Data.Item.TaskName};
    SpeciesNames = {vObj.Data.SpeciesData.SpeciesName};
    DataNames = {vObj.Data.SpeciesData.DataName};
    
    % Get the list of all active species from all valid selected tasks
    ValidSpeciesList = getSpeciesFromValidSelectedTasks(vObj.Data.Settings,TaskNames);
    
    InvalidIndices = false(size(SpeciesNames));
    for idx = 1:numel(SpeciesNames)
        % Check if the species is missing
        MissingSpecies = ~ismember(SpeciesNames{idx},ValidSpeciesList);        
        MissingData = ~ismember(DataNames{idx},OptimHeader);
        if MissingSpecies || MissingData
            InvalidIndices(idx) = true;
        end
    end
    
    % If empty, populate
    if isempty(vObj.Data.PlotSpeciesTable)
        
        if any(InvalidIndices)
            % Then, prune
            SpeciesNames(InvalidIndices) = [];
            DataNames(InvalidIndices) = [];
        end
        
        % If empty, populate, but first update line styles
        vObj.Data.PlotSpeciesTable = cell(numel(SpeciesNames),5);
        
        vObj.Data.PlotSpeciesTable(:,1) = {' '};
        if ~isempty(vObj.Data.SpeciesLineStyles(:))
            vObj.Data.PlotSpeciesTable(:,2) = vObj.Data.SpeciesLineStyles(:);
        else
            vObj.Data.PlotSpeciesTable(:,2) = {'-'};
        end
            
        vObj.Data.PlotSpeciesTable(:,3) = SpeciesNames;
        vObj.Data.PlotSpeciesTable(:,4) = DataNames;
        vObj.Data.PlotSpeciesTable(:,5) = SpeciesNames;
        
        vObj.PlotSpeciesAsInvalidTable = vObj.Data.PlotSpeciesTable;
        vObj.PlotSpeciesInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(SpeciesNames),5);
        NewPlotTable(:,1) = {' '};
        NewPlotTable(:,2) = {'-'}; % vObj.Data.SpeciesLineStyles(:); % TODO: !!
        NewPlotTable(:,3) = SpeciesNames;
        NewPlotTable(:,4) = DataNames;
        NewPlotTable(:,5) = SpeciesNames;
        
        % Adjust size if from an old saved session
        if size(vObj.Data.PlotSpeciesTable,2) == 3
            vObj.Data.PlotSpeciesTable(:,5) = vObj.Data.PlotSpeciesTable(:,3);
            vObj.Data.PlotSpeciesTable(:,4) = vObj.Data.PlotSpeciesTable(:,3);
            vObj.Data.PlotSpeciesTable(:,3) = vObj.Data.PlotSpeciesTable(:,2);
            vObj.Data.PlotSpeciesTable(:,2) = {'-'};  % TODO: !!
        elseif size(vObj.Data.PlotSpeciesTable,2) == 4
            vObj.Data.PlotSpeciesTable(:,5) = vObj.Data.PlotSpeciesTable(:,3);
        end
        
        % Update Table
        KeyColumn = [3 4];
        [vObj.Data.PlotSpeciesTable,vObj.PlotSpeciesAsInvalidTable,vObj.PlotSpeciesInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotSpeciesTable,NewPlotTable,InvalidIndices,KeyColumn);                     
        % Update line styles
        updateSpeciesLineStyles(vObj.Data);
    end

     % Species table
    set(vObj.h.PlotSpeciesTable,...
        'Data',vObj.PlotSpeciesAsInvalidTable,...
        'ColumnName',{'Plot','Style','Species','Data','Display'},...
        'ColumnFormat',{AxesOptions,vObj.Data.Settings.LineStyleMap,'char','char','char'},...
        'ColumnEditable',[true,true,false,false,true]...
        );    
else
    set(vObj.h.PlotSpeciesTable,...
        'Data',cell(0,5),...
        'ColumnName',{'Plot','Style','Species','Data','Display'},...
        'ColumnFormat',{AxesOptions,'char','char','char','char'},...
        'ColumnEditable',[true,true,false,false,true]...
        );
end


%% Refresh Parameters

% Source popup
if ~isempty(vObj.Data)
    % Update PlotParametersSourceOptions
    Names = {vObj.Data.Settings.Parameters.Name};
    MatchIdx = strcmpi(Names,vObj.Data.RefParamName);
    
    % TODO: Confirm - is this an issue if the Vpop name is renamed so it no
    % longer matches the ExcelResultFileName?
%     VPopNames = {};
%     for idx = 1:numel(vObj.Data.ExcelResultFileName)
%         if ~isempty(vObj.Data.ExcelResultFileName{idx})
%             [~,VPopNames{idx}] = fileparts(vObj.Data.ExcelResultFileName{idx}); %#ok<AGROW>
%         else
%             VPopNames{idx} = [];
%         end
%     end

    % construct the VPopname from the name of the optimization
    VPopNames = {sprintf('Results - Optimization = %s -', vObj.Data.Name)};
    
    % Filter VPopNames list (only if name does not exist, not if invalid)
    AllVPopNames = {vObj.Data.Session.Settings.VirtualPopulation.Name};
    MatchVPopIdx = false(1,numel(AllVPopNames));
    for idx = 1:numel(VPopNames)
        if isempty(VPopNames{idx})
            continue
        end
        MatchVPopIdx = MatchVPopIdx | ~cellfun(@isempty,regexp(AllVPopNames,VPopNames{idx}));
    end
    VPopNames = AllVPopNames(MatchVPopIdx);
    
    if any(MatchIdx)
        pObj = vObj.Data.Settings.Parameters(MatchIdx);    
        pObj_derivs = AllVPopNames(~cellfun(@isempty, strfind(AllVPopNames, vObj.Data.RefParamName )));
        PlotParametersSourceOptions = vertcat('N/A',{pObj.Name},reshape(pObj_derivs,[],1), VPopNames(:));
    else
        PlotParametersSourceOptions = vertcat('N/A',VPopNames(:));
    end
else
    PlotParametersSourceOptions = {'N/A'};
end

% History table
ThisProfileData = {}; % Initialize
if ~isempty(vObj.Data)
    Summary = horzcat(...
        num2cell(1:numel(vObj.Data.PlotProfile))',...        
        {vObj.Data.PlotProfile.Show}',...
        {vObj.Data.PlotProfile.Source}',...
        {vObj.Data.PlotProfile.Description}');
    
    % Loop over and italicize non-matches
    [IsSourceMatch,IsRowEmpty,ThisProfileData] = importParametersSourceHelper(vObj);    
    for rowIdx = 1:size(Summary,1)
        % Mark invalid if source parameters cannot be loaded
        if IsRowEmpty(rowIdx) && vObj.h.PlotHistoryTable.UseJTable
            Summary{rowIdx,3} = QSP.makeInvalid(Summary{rowIdx,3});
        elseif ~IsSourceMatch(rowIdx)
            % If parameters don't match the source, italicize
            if vObj.h.PlotHistoryTable.UseJTable
                tmp = [1, 3, 4];
            else
                tmp = [1, 4];
            end
                
            for colIdx = tmp
                Summary{rowIdx,colIdx} = QSP.makeItalicized(Summary{rowIdx,colIdx});
            end
        end
    end

    ThisSelectionCallback = get(vObj.h.PlotHistoryTable,'CellSelectionCallback');
    ThisEditCallback = get(vObj.h.PlotHistoryTable,'CellEditCallback');
    set(vObj.h.PlotHistoryTable,'CellSelectionCallback',''); % Disable    
    set(vObj.h.PlotHistoryTable,'CellEditCallback',''); % Disable    
    set(vObj.h.PlotHistoryTable,...
        'Data',Summary,...
        'ColumnName',{'Run','Show','Source','Description'},...
        'ColumnFormat',{'numeric','logical',PlotParametersSourceOptions(:),'char'},...
        'ColumnEditable',[false,true,true,true]...
        );
    if ~isempty(Summary)
        set(vObj.h.PlotHistoryTable,'SelectedRows',vObj.Data.SelectedProfileRow);
    end
    set(vObj.h.PlotHistoryTable,...
        'CellSelectionCallback',ThisSelectionCallback,...
        'CellEditCallback',ThisEditCallback); % Restore

else
    set(vObj.h.PlotHistoryTable,...
        'Data',cell(0,5),...
        'ColumnName',{'Run','Show','Source','Description'},...
        'ColumnFormat',{'numeric','logical','char','char'},...
        'ColumnEditable',[false,true,false,true]...
        );
end
    
% Selection
if ~isempty(vObj.Data)
    if ~isempty(vObj.Data.SelectedProfileRow)
        ThisProfile = vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow);
    else
        ThisProfile = QSP.Profile.empty(0,1);
    end
else
    ThisProfile = QSP.Profile.empty(0,1);
end

% Enable
if ~isempty(ThisProfile)
%     set(vObj.h.PlotParametersSourcePopup,'Enable','on');
    set(vObj.h.SaveAsVPopButton,'Enable','on');
    set(vObj.h.SaveAsParametersButton,'Enable','on');
    
    set(vObj.h.PlotParametersTable,'Enable','on');
else
%     set(vObj.h.PlotParametersSourcePopup,'Enable','off');
    set(vObj.h.SaveAsVPopButton,'Enable','off');
    set(vObj.h.SaveAsParametersButton,'Enable','off');
    
    set(vObj.h.PlotParametersTable,'Enable','off');
end



% Parameters Table
updateVisualizationParametersTable(vObj,ThisProfileData);


%% Update selected profile

updateVisualizationSelectedProfile(vObj);


%--------------------------------------------------------------------------
