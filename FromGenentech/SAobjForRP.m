
function D = SAobjForRP(P, logInds, obj, args, grpData)

P(logInds) = 10.^P(logInds);    
Values0 = [P; fixedParams];
Names0 = [perturbParamNames; fixedParamNames];
    
[~, StatusOK, ~, ~, ~, ~,~, ~, ~, D] = checkVPatientVsAC(obj, args, grpData, Names0, Values0);

if ~StatusOK
    D = inf;
end

end