function updateMaxNumVirtualPatients(vObj)

if ~isempty(vObj.TempData)
    set(vObj.h.MaxNumVirtualPatientsEdit,'Value',num2str(vObj.TempData.MaxNumVirtualPatients));
else
    set(vObj.h.MaxNumVirtualPatientsEdit,'Value','NaN');
end