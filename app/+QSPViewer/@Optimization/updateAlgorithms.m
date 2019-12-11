function updateAlgorithms(vObj)

if ~isempty(vObj.TempData)
    ThisList = vObj.TempData.OptimAlgorithms;
    Selection = vObj.TempData.AlgorithmName;
    % Invoke helper
    [FullListWithInvalids,FullList,Value] = QSP.highlightInvalids(ThisList,Selection);
else
    FullList = {'-'};
    FullListWithInvalids = {QSP.makeInvalid('-')};
    Value = 1;
end
vObj.AlgorithmPopupItems = FullList;
vObj.AlgorithmPopupItemsWithInvalid = FullListWithInvalids;
set(vObj.h.AlgorithmPopup,'String',vObj.AlgorithmPopupItemsWithInvalid,'Value',Value);
