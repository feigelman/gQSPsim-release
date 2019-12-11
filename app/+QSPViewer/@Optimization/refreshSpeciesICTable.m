function refreshSpeciesICTable(vObj)

if ~isempty(vObj.TempData)
    SpeciesNames = {vObj.TempData.SpeciesIC.SpeciesName};
    DataNames = {vObj.TempData.SpeciesIC.DataName};
    FunctionExpressions = {vObj.TempData.SpeciesIC.FunctionExpression};
    Data = [SpeciesNames(:) DataNames(:) FunctionExpressions(:)];
    
    % Mark any invalid entries
    if ~isempty(Data)
        % Species
        MatchIdx = find(~ismember(SpeciesNames(:),vObj.SpeciesPopupTableItems(:)));
        for index = 1:numel(MatchIdx)
            Data{MatchIdx(index),1} = QSP.makeInvalid(Data{MatchIdx(index),1});
        end
        % Data
        MatchIdx = find(~ismember(DataNames(:),vObj.PrunedDatasetHeader(:)));
        for index = 1:numel(MatchIdx)
            Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),2});
        end
    end
else
    Data = {};
end
set(vObj.h.SpeciesICTable,'Data',Data)


%% Call Update

updateSpeciesICTable(vObj);