function updateDataset(vObj)


%% Update GroupNamePopup
if ~isempty(vObj.TempData)
     % Invoke helper
    if isempty(vObj.TempData.DatasetName) || strcmpi(vObj.TempData.DatasetName,'Unspecified')
        ThisList = vertcat('Unspecified',vObj.DatasetHeader(:));
    else
        ThisList = vObj.DatasetHeader; 
    end
    
    GroupSelection = vObj.TempData.GroupName;
    [FullGroupListWithInvalids,FullGroupList,GroupValue] = QSP.highlightInvalids(ThisList,GroupSelection);   
else
    FullGroupList = {'-'};
    FullGroupListWithInvalids = {QSP.makeInvalid('-')};
    
    GroupValue = 1;    
end
vObj.DatasetHeaderPopupItems = FullGroupList;
vObj.DatasetHeaderPopupItemsWithInvalid = FullGroupListWithInvalids;

set(vObj.h.GroupNamePopup,'String',vObj.DatasetHeaderPopupItemsWithInvalid,'Value',GroupValue);


