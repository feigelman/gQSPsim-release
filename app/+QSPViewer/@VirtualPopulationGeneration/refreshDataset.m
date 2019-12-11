function refreshDataset(vObj)

%% Update DatasetPopup = list of cohorts available
if ~isempty(vObj.TempData)
    ThisList = {vObj.TempData.Settings.VirtualPopulation.Name};
    Selection = vObj.TempData.DatasetName;
    
    MatchIdx = strcmpi(ThisList,Selection);    
    if any(MatchIdx)
        ThisStatusOk = validate(vObj.TempData.Settings.VirtualPopulation(MatchIdx));
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
set(vObj.h.CohortPopup,'String',vObj.DatasetPopupItemsWithInvalid,'Value',Value);

%% Update VpopGen Data 
if ~isempty(vObj.TempData)
    ThisList = {vObj.TempData.Settings.VirtualPopulationGenerationData.Name};
    Selection = vObj.TempData.VpopGenDataName;
    
    MatchIdx = strcmpi(ThisList,Selection);    
    if any(MatchIdx)
        ThisStatusOk = validate(vObj.TempData.Settings.VirtualPopulationGenerationData(MatchIdx));
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
vObj.VpopPopupItems = FullList;
vObj.VpopPopupItemsWithInvalid = FullListWithInvalids;
set(vObj.h.VpopPopup,'String',vObj.VpopPopupItemsWithInvalid,'Value',Value);


%% Update GroupNamePopup

if ~isempty(vObj.TempData) && ~isempty(vObj.TempData.DatasetName) && ~isempty(vObj.TempData.Settings.VirtualPopulationGenerationData)
    Names = {vObj.TempData.Settings.VirtualPopulationGenerationData.Name};
    MatchIdx = strcmpi(Names,vObj.TempData.VpopGenDataName);
    
    if any(MatchIdx)
        dObj = vObj.TempData.Settings.VirtualPopulationGenerationData(MatchIdx);
        
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


%% Populate any contextmenu defaults for plotting, based on the Type specified by VPopData

TypeCol = find(strcmp(VPopHeader,'Type'));

vObj.bShowTraces(1:vObj.MaxNumPlots) = false; % default off
vObj.bShowQuantiles(1:vObj.MaxNumPlots) = true; % default on
vObj.bShowMean(1:vObj.MaxNumPlots) = true; % default on
vObj.bShowMedian(1:vObj.MaxNumPlots) = false; % default off
vObj.bShowSD(1:vObj.MaxNumPlots) = false; % default off, unless Type = MEAN_STD

if ~isempty(TypeCol)
    ThisType = VPopData(:,TypeCol);
    if any(strcmp(ThisType,'MEAN_STD')) % If MEAN_STD, then show SD
        vObj.bShowSD(1:vObj.MaxNumPlots) = true;
    end
end

% Update context menu - since defaults are the same, okay to use first
% value and assign to rest
set(vObj.h.ContextMenuTraces,'Checked',uix.utility.tf2onoff(vObj.bShowTraces(1)));
set(vObj.h.ContextMenuQuantiles,'Checked',uix.utility.tf2onoff(vObj.bShowQuantiles(1)));
set(vObj.h.ContextMenuMean,'Checked',uix.utility.tf2onoff(vObj.bShowMean(1)));
set(vObj.h.ContextMenuMedian,'Checked',uix.utility.tf2onoff(vObj.bShowMedian(1)));
set(vObj.h.ContextMenuSD,'Checked',uix.utility.tf2onoff(vObj.bShowSD(1)));
 

%% Get 'Species' column from Dataset

if ~isempty(VPopHeader) && ~isempty(VPopData)
    MatchIdx = find(strcmpi(VPopHeader,'Species'));
    if numel(MatchIdx) == 1
        vObj.DatasetDataColumn = unique(VPopData(:,MatchIdx));
    elseif numel(MatchIdx) == 0
        vObj.DatasetDataColumn = {};
        warning('VpopGen Data %s has 0 ''Species'' column names',vpopObj.FilePath);
    else
        vObj.DatasetDataColumn = {};
        warning('VpopGen Data %s has multiple ''Species'' column names',vpopObj.FilePath);
    end
else
    vObj.DatasetDataColumn = {};
end


%% Update GroupNamePopup

updateDataset(vObj);