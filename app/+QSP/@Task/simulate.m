function [simData, statusOK, Message] = simulate(obj, varargin)
    
    statusOK = true;
    Message = '';
    simData = [];
    
    p = inputParser;
    p.addOptional('Names', {});
    p.addOptional('Values', {});
    p.addParameter('OutputTimes', obj.OutputTimes);
    p.addParameter('StopTime', obj.TimeToSteadyState);
    p.addParameter('Waitbar', []);
    p.addParameter('CheckCurrent', true);

    parse(p, varargin{:});
    Names = p.Results.Names; 
    Values = p.Results.Values;
    Waitbar = p.Results.Waitbar;
    CheckCurrent = p.Results.CheckCurrent;
    
    % filter out missing values
    ixOK = find(~isnan(p.Results.Values));
    Names = Names(ixOK);
    Values = Values(ixOK);
    
    % rebuild model if necessary
    if CheckCurrent        
        [statusOK, Message] = obj.update();
        if ~statusOK
            return
        end
    end
            
    modelSpecies = sbioselect(obj.VarModelObj,'Type','Species'); 
    speciesNames = get(modelSpecies, 'Name');

%     fprintf('Species names %s', strjoin(speciesNames,'\n'));
    
    [hSpecies,idxSpecies] = ismember(Names, speciesNames);    
    ICSpecies = Names(hSpecies);      
    ICValues = Values(hSpecies);

    % indices of each specified parameter in the complete list of
    % parameters
    modelParams = sbioselect(obj.VarModelObj,'Type','Parameter'); 
    modelParamNames = get(modelParams, 'Name');
    % need to add the reaction scoping to parameters if they are
    % reaction-scoped
    
    idxReactionScoped = strcmp('SimBiology.KineticLaw', cellfun(@class, get(modelParams,'Parent'), 'UniformOutput', false));
     
    modelParamNames(idxReactionScoped) = arrayfun(@(k) sprintf('%s.%s', get(get(get(modelParams(k),'Parent'),'Parent'), 'Name'), ...
        modelParamNames{k}),  find(idxReactionScoped), ...
        'UniformOutput', false);
    
    [hParam, ixParam] = ismember(Names,modelParamNames);
    
    pNames = Names(hParam); % parameter names
    pValues = Values(hParam); % parameter values
    ixParam = ixParam(hParam); % keep only indices that are parameters
    
    idxMisc = ~(hSpecies | hParam) & ~strcmpi(Names,'GROUP');
    if any(idxMisc)
        % found some columns which are neither parameter nor species
        statusOK = false;
        Message = sprintf(['Invalid parameters specified for simulation. Please check virtual population and/or parameters file for consistency with model.\n' ... 
            'Note that reaction-scoped parameters must be named [reaction name].[parameter name]\n%s\nSpecies:\n%s\nParameters:\n%s'], ...
            strjoin(cellfun(@(s) sprintf('* %s',s), Names(idxMisc), 'UniformOutput', false), '\n'), ...
            strjoin(cellfun(@(s) sprintf('* %s',s), obj.SpeciesNames, 'UniformOutput', false), '\n'), ...
            strjoin(cellfun(@(s) sprintf('* %s',s), pNames, 'UniformOutput', false), '\n') );
        
        return
    end
            
    % get default parameter values for the current variants
    paramValues = cell2mat(get(modelParams,'Value'));
    
    % replace values with the specified values
    paramValues(ixParam) = pValues;   
    
    times = p.Results.OutputTimes;
    StopTime = p.Results.StopTime;
    
    model = obj.ExportedModel;
    
    activeDoses = obj.ActiveDoseNames(:);
    if isempty(activeDoses)
        doses = [];
    else
        allDoses = getdose(model);        
        [~,doseIdx] = ismember({obj.ActiveDoseNames{:}}, {allDoses.Name});
        doses = allDoses(doseIdx);
        
    end
    
    % get initial conditions
    if isempty(ICValues)        
        % if not specified, use default values /w variants applied
        ICValues = cell2mat(get(obj.VarModelObj.Species, 'InitialAmount'));
    else 
        % set initial conditions from argument
        [~,spIdx] = ismember(ICSpecies, speciesNames);
        ICs_all = cell2mat(get(obj.VarModelObj.Species, 'InitialAmount'));
        idxValid = ~isnan(ICValues);
        if ~any(idxValid)
            statusOK = false;
            Message = sprintf('All species initial values were invalid');
            return
        end
        ICs_all(spIdx(idxValid)) = ICValues(idxValid);
        ICValues = ICs_all;       
    end
            
%     test = load('test');
%     paramValues = test.paramValues;
    
    if obj.RunToSteadyState
        % Simulate to steady state
        try
            model.SimulationOptions.StopTime = StopTime;
            model.SimulationOptions.OutputTimes = [];            
            [~,RTSSdata,outNames] = simulate(model,[ICValues; paramValues],[]);
            
            comps = get(obj.ModelObj.mObj, 'Compartments');
            nComp = length(comps);
            if nComp==1
                outNames = cellfun(@(s) sprintf('%s.%s', comps(1).Name, s), outNames, 'UniformOutput', false);
            end
            
            RTSSdata = max(0,RTSSdata); % replace any negative values with zero
            
            

            
            % comparments
            comps = cellfun(@(x) x.Name, get(obj.VarModelObj.Species,'Parent'), 'UniformOutput', false);
            specs = get(obj.VarModelObj.Species,'Name');
            fullSpecName = arrayfun(@(k) sprintf('%s.%s', comps{k}, specs{k}), 1:numel(specs), 'UniformOutput', false);
            
            [hIdx,idxSpecies] = ismember(outNames, fullSpecName);

%             [hIdx,idxSpecies] = ismember(outNames, get(obj.VarModelObj.Species,'Name'));
            if any(isnan(RTSSdata(:)))
                ME = MException('Task:simulate', 'Encountered NaN during simulation');
                throw(ME)
            end
            ICValues = RTSSdata(end, idxSpecies(hIdx));
            %             if any(isinf(ICValues))
%                 disp('Ignoring inf values computed for steady state')
%             end
        catch err
            warning(err.identifier, 'Task:simulate: %s', err.message)
            statusOK = false;
            Message = err.message;
            simData= [];
            return
        end % try
    end    

    model.SimulationOptions.StopTime = StopTime;
    model.SimulationOptions.OutputTimes = times;
    
    try
        simData = simulate(model,[reshape(ICValues,[],1); paramValues],doses);
    catch simErr
        statusOK = false;
        Message = simErr.message;
        simData= [];
        return
    end
        
end




