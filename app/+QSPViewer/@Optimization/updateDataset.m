function updateDataset(vObj)


%% Update GroupNamePopup and IDNamePopup
if ~isempty(vObj.TempData)
    % Invoke helper
    GroupSelection = vObj.TempData.GroupName;
    [FullGroupListWithInvalids,FullGroupList,GroupValue] = QSP.highlightInvalids(vObj.DatasetHeader,GroupSelection);
    
    % Invoke helper
    IDSelection = vObj.TempData.IDName;
    [FullIDListWithInvalids,FullIDList,IDValue] = QSP.highlightInvalids(vObj.DatasetHeader,IDSelection);
else
    FullGroupList = {'-'};
    FullIDList = {'-'};
    FullGroupListWithInvalids = {QSP.makeInvalid('-')};
    FullIDListWithInvalids = {QSP.makeInvalid('-')};
    
    GroupValue = 1;
    IDValue = 1;
end
vObj.DatasetGroupPopupItems = FullGroupList;
vObj.DatasetGroupPopupItemsWithInvalid = FullGroupListWithInvalids;
vObj.DatasetIDPopupItems = FullIDList;
vObj.DatasetIDPopupItemsWithInvalid = FullIDListWithInvalids;

set(vObj.h.GroupNamePopup,'String',vObj.DatasetGroupPopupItemsWithInvalid,'Value',GroupValue);
set(vObj.h.IDNamePopup,'String',vObj.DatasetIDPopupItemsWithInvalid,'Value',IDValue);


%% Refresh GroupIDPopupTableItems

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