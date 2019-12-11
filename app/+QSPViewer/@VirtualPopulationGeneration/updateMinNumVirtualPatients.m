function updateMinNumVirtualPatients(vObj)

if ~isempty(vObj.TempData)
    set(vObj.h.MinNumVirtualPatientsEdit,'Value',num2str(vObj.TempData.MinNumVirtualPatients));
else
    set(vObj.h.MinNumVirtualPatientsEdit,'Value','NaN');
end