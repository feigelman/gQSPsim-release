function updateMaxNumSims(vObj)

if ~isempty(vObj.TempData)
    set(vObj.h.MaxNumSimulationsEdit,'Value',num2str(vObj.TempData.MaxNumSimulations));
else
    set(vObj.h.MaxNumSimulationsEdit,'Value','NaN');
end