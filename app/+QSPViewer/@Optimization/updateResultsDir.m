function updateResultsDir(vObj)

if ~isempty(vObj.TempData)
    set(vObj.h.ResultsDirSelector,...
        'RootDirectory',vObj.TempData.Session.RootDirectory,...
        'Value',vObj.TempData.OptimResultsFolderName)
else
    ResultsDir = '';
    vObj.h.ResultsDirSelector.Value = ResultsDir;
end