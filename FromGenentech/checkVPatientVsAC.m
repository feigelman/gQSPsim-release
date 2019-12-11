function [model_outputs, StatusOK, Message, LB_outputs, UB_outputs, spec_outputs, taskName_outputs, time_outputs, nIC, D] = checkVPatientVsAC(obj, args, grpData, Names0, Values0 )

% unpack args
LB = args.LB;
UB = args.UB;
fixedParams = args.fixedParams;
fixedParamNames = args.fixedParamNames;
perturbParamNames = args.perturbParamNames;
logInds = args.logInds;
unqGroups = args.unqGroups;
Groups = args.Groups;
Species = args.Species;
Time = args.Time;
LB_accCrit = args.LB_accCrit;
UB_accCrit = args.UB_accCrit;
ICTable = args.ICTable;
Mappings = args.Mappings;
P0_1 = args.P0_1;
CV = args.CV;
normInds = args.normInds;

% group data
taskObj = grpData.taskObj;
Species_grp = grpData.Species_grp;
Time_grp = grpData.Time_grp;
LB_grp = grpData.LB_grp;
UB_grp = grpData.UB_grp;
OutputTimes =  grpData.OutputTimes;
ICs = grpData.ICs;
nIC = grpData.nIC;
IC_species = grpData.IC_species;
grpInds = grpData.grpInds;

%  checkVPatientVsAC(Values0, Names0, obj, unqGroups, Groups, groupVec, Species, Time, LB_accCrit, UB_accCrit, ICTable, Mappings )
% checkVPatientVsAC(Values0, Names0, obj, unqGroups, Groups, groupVec, Species, Time, LB_accCrit, UB_accCrit, ICTable, Mappings )
StatusOK = true;
Message = '';

% generate a long vector of model outputs to compare to the acceptance
% criteria
spec_outputs = [];
time_outputs = [];
LB_outputs = [];
UB_outputs = [];
taskName_outputs = [];
model_outputs = [];

% loop over unique groups in the acceptance criteria file
for grpIdx = 1:length(unqGroups) %nItems
    
    % loop over initial conditions for this group
    for ixIC = 1:nIC(grpIdx)
        if ~isempty(IC_species)
            Names = [Names0; IC_species'];  
            Values = [Values0; ICs{grpIdx}(ixIC,:)'];
        else
            Names = Names0;
            Values = Values0;
        end


        % simulate
        try
            simData  = taskObj{grpIdx}.simulate(...
                'Names', Names, ...
                'Values', Values, ...
                'OutputTimes', OutputTimes{grpIdx});

            % for each species in this grp acc crit, find the corresponding
            % model output, grab relevant time points, compare
            uniqueSpecies_grp = unique(Species_grp{grpIdx});
            for spec = 1:length(uniqueSpecies_grp)
                % find the data species in the Species-Data mapping
                specInd = strcmp(uniqueSpecies_grp(spec),Mappings(:,2));

                if nnz(specInd) ~= 1
                    StatusOK = false;
                    Message = sprintf('%s\nOnly one species may be assigned to any given data set. Please check mappings for validity.\n', Message);
                    delete(hWbar)
                    return
                end               

                % grab data for the corresponding model species from the simulation results
                [simT,simData_spec,specName] = selectbyname(simData,Mappings(specInd,1));

                try
                    % transform the model outputs to match the data
                    simData_spec = obj.SpeciesData(specInd).evaluate(simData_spec);
                catch ME
                    StatusOK = false;
                    ThisMessage = sprintf(['There is an error in one of the function expressions in the SpeciesData mapping.'...
                        'Validate that all mappings have been specified for each unique species in dataset. %s'], ME.message);
                    Message = sprintf('%s\n%s\n',Message,ThisMessage);
                    path(myPath);
                    return                    
                end % try

                % grab all acceptance criteria time points for this species in this group
                ix_grp_spec = strcmp(uniqueSpecies_grp(spec),Species_grp{grpIdx});
                Time_grp_spec = Time_grp{grpIdx}(ix_grp_spec);
                LB_grp_spec = LB_grp{grpIdx}(ix_grp_spec);
                UB_grp_spec = UB_grp{grpIdx}(ix_grp_spec);

                % select simulation time points for which there are acceptance criteria
                [bSim,okInds] = ismember(simT,Time_grp_spec);
                simData_spec = simData_spec(bSim);
                LB_grp_spec = LB_grp_spec(okInds(bSim));
                UB_grp_spec = UB_grp_spec(okInds(bSim));
                Time_grp_spec = Time_grp_spec(okInds(bSim));

                % save model outputs
                model_outputs = [model_outputs;simData_spec];
                time_outputs = [time_outputs;Time_grp_spec];
                spec_outputs = [spec_outputs;repmat(specName,size(simData_spec))];
                taskName_outputs = [taskName_outputs;repmat({taskObj{grpIdx}.Name},size(simData_spec))];

                LB_outputs = [LB_outputs; LB_grp_spec];
                UB_outputs = [UB_outputs; UB_grp_spec];


            end % for spec
        catch ME2
            % if the simulation fails, replace model outputs with Inf so
            % that the parameter set fails the acceptance criteria
            model_outputs = [model_outputs;Inf*ones(length(grpInds),1)];
            LB_outputs = [LB_outputs;NaN(length(grpInds),1)];            
            UB_outputs = [UB_outputs;NaN(length(grpInds),1)];
            StatusOK = false;
            D = inf;
        end
    end % for ixIC

end % for grp

% at this point, model_outputs should be the same length as the vectors
% LB_accCrit and UB_accCrit

% compute squatred distance from the midpoints of the
% acceptance criteria for use with the relative
% prevalence method

midpoints = (LB_outputs + UB_outputs)/2;

D = (model_outputs - midpoints).^2 - (UB_outputs - midpoints).^2;
D = D ./ midpoints.^2;
D = sum(D(D>=0));
    

    