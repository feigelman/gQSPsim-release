function updateItemsTable(vObj)

% GroupID
if ~isempty(vObj.TempData) && ~isempty(vObj.DatasetHeader) && ~isempty(vObj.DatasetData)
    MatchIdx = strcmp(vObj.DatasetHeader,vObj.TempData.GroupName);
    GroupIDs = vObj.DatasetData(:,MatchIdx);
    if iscell(GroupIDs)
        GroupIDs = cell2mat(GroupIDs);        
    end    
    GroupIDs = unique(GroupIDs);
    vObj.GroupIDPopupTableItems = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
else
    vObj.GroupIDPopupTableItems = {};
end

set(vObj.h.ItemsTable,...
    'ColumnName',{'Task','Group','Run To Steady State'},...
    'ColumnEditable',[true true false],...
    'ColumnFormat',{vObj.TaskPopupTableItems(:),vObj.GroupIDPopupTableItems(:),'char'});