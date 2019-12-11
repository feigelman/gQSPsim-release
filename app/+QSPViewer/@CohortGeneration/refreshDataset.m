function refreshDataset(vObj)

%% Update DatasetPopup

if ~isempty(vObj.TempData)
    ThisList = {vObj.TempData.Settings.VirtualPopulationData.Name};
    Selection = vObj.TempData.DatasetName;
    
    MatchIdx = strcmpi(ThisList,Selection);    
    if any(MatchIdx)
        ThisStatusOk = validate(vObj.TempData.Settings.VirtualPopulationData(MatchIdx));
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


%% Update GroupNamePopup

if ~isempty(vObj.TempData) && ~isempty(vObj.TempData.DatasetName) && ~isempty(vObj.TempData.Settings.VirtualPopulationData)
    Names = {vObj.TempData.Settings.VirtualPopulationData.Name};
    MatchIdx = strcmpi(Names,vObj.TempData.DatasetName);
    
    if any(MatchIdx)
        dObj = vObj.TempData.Settings.VirtualPopulationData(MatchIdx);
        
        [~,~,VPopHeader,VPopData] = importData(dObj,dObj.FilePath);
    else
        VPopHeader = {};
        VPopData = {};
    end
else
    VPopHeader = {};
    VPopData = {};
end
vObj.DatasetHeader = VPopHeader;
vObj.DatasetData = VPopData;


%% Get 'Data' column from Dataset

if ~isempty(VPopHeader) && ~isempty(VPopData)
    MatchIdx = find(strcmpi(VPopHeader,'Data'));
    if numel(MatchIdx) == 1
        vObj.DatasetDataColumn = unique(VPopData(:,MatchIdx));
    elseif numel(MatchIdx) == 0
        vObj.DatasetDataColumn = {};
        warning('Acceptance Criteria %s has 0 ''Data'' column names',vpopObj.FilePath);
    else
        vObj.DatasetDataColumn = {};
        warning('Acceptance Criteria %s has multiple ''Data'' column names',vpopObj.FilePath);
    end
else
    vObj.DatasetDataColumn = {};
end


%% Update GroupNamePopup

updateDataset(vObj);