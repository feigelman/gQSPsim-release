function setIconDisplayStyleOff(hThis)

hThisAnn = get(hThis,'Annotation');
if iscell(hThisAnn)
    hThisAnn = [hThisAnn{:}];
end
hThisAnnLegend = get(hThisAnn,'LegendInformation');
if iscell(hThisAnnLegend)
    hThisAnnLegend = [hThisAnnLegend{:}];
end
set(hThisAnnLegend,'IconDisplayStyle','off');