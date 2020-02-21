function registerUnits
    % Register units with SimBiology
    newUnits = [
        "fold",       "dimensionless";
        "normalized", "dimensionless";
        "fraction",   "dimensionless"
        "nM",         "nanomole / litre"];
    
    for i = 1:size(newUnits,1)
        if isempty(sbioselect(sbioroot, 'Name', newUnits(i, 1)))
            
            % Create unit
            unitObj = sbiounit(newUnits(i, 1), newUnits(i, 2));
            
            % Add to library
            sbioaddtolibrary(unitObj);
        end
    end
end
