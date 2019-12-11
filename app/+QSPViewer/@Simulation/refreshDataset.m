function refreshDataset(vObj)

%% Update DatasetPopup

OptimHeader = {};

if ~isempty(vObj.TempData)
    ThisRawList = {vObj.TempData.Settings.OptimizationData.Name};
    % Dataset is optional, so add an 'Unspecified'
    ThisList = vertcat('Unspecified',ThisRawList(:));
    Selection = vObj.TempData.DatasetName;
    if isempty(Selection)
        Selection = 'Unspecified';
    end
    
    % Force as invalid if validate fails
    MatchIdx = find(strcmpi(ThisRawList,Selection));
    if any(MatchIdx)
        [ThisStatusOk,~,OptimHeader] = validate(vObj.TempData.Settings.OptimizationData(MatchIdx));
        ForceMarkAsInvalid = ~ThisStatusOk;
    else
        ForceMarkAsInvalid = false;
    end
    
    % Invoke helper
    [FullListWithInvalids,FullList,~] = QSP.highlightInvalids(ThisList,Selection,ForceMarkAsInvalid);
else
    FullList = {'-'};
    FullListWithInvalids = {QSP.makeInvalid('-')};        
end
vObj.DatasetPopupItems = FullList;
vObj.DatasetPopupItemsWithInvalid = FullListWithInvalids;



if ~isempty(vObj.TempData)
    if isempty(vObj.TempData.DatasetName)
        ThisSelection = 'Unspecified';
    else
        ThisSelection = vObj.TempData.DatasetName;
    end
    [~,Value] = ismember(ThisSelection,vObj.DatasetPopupItems);
    set(vObj.h.DatasetPopup,'String',vObj.DatasetPopupItemsWithInvalid,'Value',Value);
else
    set(vObj.h.DatasetPopup,'String',vObj.DatasetPopupItemsWithInvalid,'Value',1);
end


%% Update GroupNamePopup

vObj.DatasetHeader = OptimHeader;


%% Update GroupNamePopup

updateDataset(vObj);