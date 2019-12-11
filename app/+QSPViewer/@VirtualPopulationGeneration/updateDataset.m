function updateDataset(vObj)


%% Update GroupNamePopup and IDNamePopup
if ~isempty(vObj.TempData)
    % Invoke helper
    GroupSelection = vObj.TempData.GroupName;
    [FullGroupListWithInvalids,FullGroupList,GroupValue] = QSP.highlightInvalids(vObj.DatasetHeader,GroupSelection);
else
    FullGroupList = {'-'};
    FullGroupListWithInvalids = {QSP.makeInvalid('-')};
    
    GroupValue = 1;
end
vObj.DatasetGroupPopupItems = FullGroupList;
vObj.DatasetGroupPopupItemsWithInvalid = FullGroupListWithInvalids;

set(vObj.h.GroupNamePopup,'String',vObj.DatasetGroupPopupItemsWithInvalid,'Value',GroupValue);


%% Refresh GroupIDPopupTableItems

% GroupID
if ~isempty(vObj.TempData) && ~isempty(vObj.DatasetHeader) && ~isempty(vObj.DatasetData)
    MatchIdx = strcmp(vObj.DatasetHeader,vObj.TempData.GroupName);
    GroupIDs = vObj.DatasetData(:,MatchIdx);
    if iscell(GroupIDs)
        try
            GroupIDs = cell2mat(GroupIDs);
        catch
            errordlg('Invalid group ID column selected. Only numeric values are allowed')
            return
        end
            
    end
    GroupIDs = unique(GroupIDs);
    vObj.GroupIDPopupTableItems = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
else
    vObj.GroupIDPopupTableItems = {};
end