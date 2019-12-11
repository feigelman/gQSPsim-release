function removeInvalidVisualization(vObj)

% Remove invalid indices
if ~isempty(vObj.PlotSpeciesInvalidRowIndices)
    vObj.Data.PlotSpeciesTable(vObj.PlotSpeciesInvalidRowIndices,:) = [];
    vObj.PlotSpeciesAsInvalidTable(vObj.PlotSpeciesInvalidRowIndices,:) = [];
    vObj.PlotSpeciesInvalidRowIndices = [];
end

if ~isempty(vObj.PlotItemInvalidRowIndices)
    vObj.Data.PlotItemTable(vObj.PlotItemInvalidRowIndices,:) = [];
    vObj.PlotItemAsInvalidTable(vObj.PlotSpeciesInvalidRowIndices,:) = [];
    vObj.PlotItemInvalidRowIndices = [];
end

% Update
updateVisualizationView(vObj);