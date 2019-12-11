function objVals = defaultObj(species,data,simTime,dataTime,allData,ID,Grp,currID,currGrp)

allData = allData(~isnan(allData));

if length(allData) > 1
    objVals = abs(species(:)-data(:))/(max(allData)-min(allData));
else
    objVals = abs( species(:)-data(:))/abs(data(:));
end
    
end

