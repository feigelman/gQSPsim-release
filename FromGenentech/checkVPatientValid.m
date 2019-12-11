function [model_outputs, StatusOK, Message, LB_outputs, UB_outputs, D] = checkVPatientValid(Values0, Names0, obj, unqGroups, Groups, Species, Time, LB_accCrit, UB_accCrit, ICTable, Mappings )
    

    
    % generate a long vector of model outputs to compare to the acceptance
    % criteria
    spec_outputs = [];
    time_outputs = [];
    LB_outputs = [];
    UB_outputs = [];
    taskName_outputs = [];
    model_outputs = [];
    LB_violation = [];
    UB_violation = [];   
    
    % loop over unique groups in the acceptance criteria file
    for grpIdx = 1:length(unqGroups) %nItems
        currGrp = unqGroups(grpIdx);
        
        % get matching taskGroup item based on group ID        
        itemIdx = strcmp({obj.Item.GroupID}, num2str(currGrp));
        if ~any(itemIdx)
            % this group is not part of this vpop generation
            continue
        end
        
        if nnz(itemIdx) > 1
            StatusOK = false;
            Message = sprintf('%s\nOnly one task may be assigned to any group. Check task group mappings.\n', Message);
            delete(hWbar)
            return
        end
        
        % get task object for this item based on name
        tskInd = strcmp(obj.Item(itemIdx).TaskName,{obj.Settings.Task.Name});
        taskObj = obj.Settings.Task(tskInd);
        
        % indices of data points in acc. crit. matching this group
        grpInds = find(Groups == currGrp);
        
        % get group information
        Species_grp = Species(grpInds);
        Time_grp = Time(grpInds);
        LB_grp = LB_accCrit(grpInds);
        UB_grp = UB_accCrit(grpInds);
        
        % change output times for the exported model
        OutputTimes = sort(unique(Time_grp));
        
        % set the initial conditions to the value in the IC file if specified
        if ~isempty(ICTable)
            ICs = ICTable.data(groupVec==currGrp, ixSpecies );
            IC_species = ICTable.colheaders(ixSpecies);
            nIC = size(ICs,1);
            if ~any(groupVec==currGrp)
                StatusOK = false;
                Message = sprintf('%sInitial conditions file specified contains groups for which no task has been assigned.\n', Message);
                delete(hWbar)
                return
            end
            
        else
            nIC = 1;
            ICs = [];
            IC_species = {};
        end
        
        % loop over initial conditions for this group
        for ixIC = 1:nIC
            if ~isempty(IC_species)
                Names = [Names0; IC_species'];  
                Values = [Values0; ICs(ixIC,:)'];
            else
                Names = Names0;
                Values = Values0;
            end


            % simulate
            try
                simData  = taskObj.simulate(...
                    'Names', Names, ...
                    'Values', Values, ...
                    'OutputTimes', OutputTimes);

                % for each species in this grp acc crit, find the corresponding
                % model output, grab relevant time points, compare
                uniqueSpecies_grp = unique(Species_grp);
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
                    ix_grp_spec = strcmp(uniqueSpecies_grp(spec),Species_grp);
                    Time_grp_spec = Time_grp(ix_grp_spec);
                    LB_grp_spec = LB_grp(ix_grp_spec);
                    UB_grp_spec = UB_grp(ix_grp_spec);

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
                    taskName_outputs = [taskName_outputs;repmat({taskObj.Name},size(simData_spec))];

                    LB_outputs = [LB_outputs; LB_grp_spec];
                    UB_outputs = [UB_outputs; UB_grp_spec];
                    

                end % for spec
            catch ME2
                % if the simulation fails, replace model outputs with Inf so
                % that the parameter set fails the acceptance criteria
                model_outputs = [model_outputs;Inf*ones(length(grpInds),1)];
                LB_outputs = [LB_outputs;NaN(length(grpInds),1)];            
                UB_outputs = [UB_outputs;NaN(length(grpInds),1)];
            end
        end % for ixIC
        
    end % for grp

    % at this point, model_outputs should be the same length as the vectors
    % LB_accCrit and UB_accCrit
    
    % compute squatred distance from the midpoints of the
    % acceptance criteria for use with the relative
    % prevalence method

    D = sum( (model_outputs - (LB_outputs + UB_outputs)/2).^2);

    