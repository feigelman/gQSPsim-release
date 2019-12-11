function refreshDataset(vObj)

%% Update DatasetPopup

if ~isempty(vObj.TempData)
    ThisList = {vObj.TempData.Settings.OptimizationData.Name};
    Selection = vObj.TempData.DatasetName;
    
    MatchIdx = strcmpi(ThisList,Selection);    
    if any(MatchIdx)
        ThisStatusOk = validate(vObj.TempData.Settings.OptimizationData(MatchIdx));
        ForceMarkAsInvalid = ~ThisStatusOk;
    else
        ForceMarkAsInvalid = false;
    end
    
    % Invoke helper
    [FullListWithInvalids,FullList,Value] = QSP.highlightInvalids(ThisList,Selection,ForceMarkAsInvalid);
else
    FullList = {'-'};
    FullListWithInvalids = {QSP.makeInvalid('-')};    
    Value = 1;
end
vObj.DatasetPopupItems = FullList;
vObj.DatasetPopupItemsWithInvalid = FullListWithInvalids;
set(vObj.h.DatasetPopup,'String',vObj.DatasetPopupItemsWithInvalid,'Value',Value);


%% Update GroupNamePopup and IDNamePopup

if ~isempty(vObj.TempData) && ~isempty(vObj.TempData.DatasetName) && ~isempty(vObj.TempData.Settings.OptimizationData)
    Names = {vObj.TempData.Settings.OptimizationData.Name};
    MatchIdx = strcmpi(Names,vObj.TempData.DatasetName);
    
    if any(MatchIdx)
        dObj = vObj.TempData.Settings.OptimizationData(MatchIdx);
        
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
vObj.DatasetHeader = OptimHeader;
vObj.PrunedDatasetHeader = setdiff(OptimHeader,{'Time','Group'}); % Remove Time, Group
vObj.DatasetData = OptimData;


%% Update GroupNamePopup and IDNamePopup

updateDataset(vObj);