function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotVirtualCohortGeneration(obj,hAxes,varargin)
% plotVirtualCohortGeneration - plots the analysis
% -------------------------------------------------------------------------
% Abstract: This plots the analysis based on the settings and data table.
%
% Syntax:
%           plotVirtualCohortGeneration(aObj,hAxes)
%
% Inputs:
%           obj - QSP.VirtualPopulationGeneration or QSP.CohortGeneration object
%
%           hAxes
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 331 $  $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
% ---------------------------------------------------------------------

p = inputParser;
p.KeepUnmatched = false;

% Define defaults and requirements for each parameter
p.addParameter('Mode','Cohort',@(x)any(ismember(x,{'Cohort','VP'})));

p.parse(varargin{:});

Mode = p.Results.Mode;


%% Turn on hold

for index = 1:numel(hAxes)
    %     XLimMode{index} = get(hAxes(index),'XLimMode');
    %     YLimMode{index} = get(hAxes(index),'YLimMode');
    cla(hAxes(index));
    xr = get(hAxes(index),'xruler');
    xr.TickLabelRotation = 0;
    
    legend(hAxes(index),'off')
    %     set(hAxes(index),'XLimMode',XLimMode{index},'YLimMode',YLimMode{index})
    
    set(hAxes(index),...
        'XLimMode',obj.PlotSettings(index).XLimMode,...
        'YLimMode',obj.PlotSettings(index).YLimMode);
    if strcmpi(obj.PlotSettings(index).XLimMode,'manual')
        tmp = obj.PlotSettings(index).CustomXLim;
        if ischar(tmp), tmp = str2num(tmp); end         %#ok<ST2NM>
        set(hAxes(index),...
            'XLim',tmp);
    end
    if strcmpi(obj.PlotSettings(index).YLimMode,'manual')
        tmp = obj.PlotSettings(index).CustomYLim;
        if ischar(tmp), tmp = str2num(tmp); end         %#ok<ST2NM>
        set(hAxes(index),...
            'YLim',tmp);
    end
    
    hold(hAxes(index),'on')
end

NumAxes = numel(hAxes);
hSpeciesGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);
hDatasetGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);

hLegend = cell(1,NumAxes);
hLegendChildren = cell(1,NumAxes);


%% Process

% TODO: These are not passed out
StatusOK = true;
Message = '';

% load acceptance criteria
if strcmpi(Mode,'Cohort')
    % Cohort
    Names = {obj.Settings.VirtualPopulationData.Name};
    MatchIdx = strcmpi(Names,obj.DatasetName);
else
    % VP
    Names = {obj.Settings.VirtualPopulationGenerationData.Name};
    MatchIdx = strcmpi(Names,obj.VpopGenDataName);
end

if any(MatchIdx)
    if strcmpi(Mode,'Cohort')
        % Cohort
        vpopObj = obj.Settings.VirtualPopulationData(MatchIdx);
    else
        % VP
        vpopObj = obj.Settings.VirtualPopulationGenerationData(MatchIdx);
    end
    
    [ThisStatusOk,ThisMessage,ThisHeader,ThisData] = importData(vpopObj,vpopObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    ThisHeader = {};
    ThisData = {};
end


%% Get the selections and Task-Vpop pairs

% Process all
IsSelected = true(size(obj.PlotItemTable,1),1);

if isempty(obj.SimResults)
    IsCached = false(size(obj.PlotItemTable(:,1)));
    obj.SimResults = cell(size(obj.PlotItemTable(:,1)));
else
    IsCached = ~cellfun(@isempty, obj.SimResults);
end
RunInds = IsSelected & ~IsCached;

if any(RunInds) && ~isempty(obj.VPopName)
    
    SelectedInds = find(RunInds);
    
    % make Task-Vpop pairs for each selected task
    nSelected = nnz(RunInds);
    
    simObj = QSP.Simulation;
    simObj.Settings = obj.Settings;
    simObj.Session = obj.Session;
    for ii = 1:nSelected
        simObj.Item(ii) = QSP.TaskVirtualPopulation;
        % NOTE: Indexing into Item may not be valid from PlotItemTable (Incorrect if there are/were invalids: simObj.Item(ii).TaskName = obj.Item(SelectedInds(ii)).TaskName;)
        simObj.Item(ii).TaskName = obj.PlotItemTable{SelectedInds(ii),3};
        simObj.Item(ii).VPopName = obj.VPopName;
        simObj.Item(ii).Group = obj.PlotItemTable{SelectedInds(ii),4};
    end
else
    simObj = QSP.Simulation.empty(0,1);
end

% get the virtual population object
% allVpopNames = {obj.Settings.VirtualPopulation.Name};
% vObj = obj.Settings.VirtualPopulation(strcmp(obj.VPopName,allVpopNames));

%% Run the simulations for those that are not cached
if ~isempty(simObj)
    
    if strcmpi(Mode,'Cohort')
        % Cohort
        TimeVec = cell2mat(ThisData(:,strcmp('Time',ThisHeader)));
        [ThisStatusOK,Message,ResultFileNames,Cancelled,Results] = simulationRunHelper(simObj, [], {}, TimeVec); %#ok<ASGLU>
    else
        % VP
        [ThisStatusOK,Message,ResultFileNames,Cancelled,Results] = simulationRunHelper(simObj); %#ok<ASGLU>
    end
    
    if ~ThisStatusOK  && ~Cancelled
        errordlg(Message)
        return
    end
    
    if Cancelled
        return
    end
    
    % cache the result to avoid simulating again
    for ii = 1:length(simObj.Item)
        obj.SimResults{SelectedInds(ii)}.Time = Results{ii}.Time;
        obj.SimResults{SelectedInds(ii)}.SpeciesNames = Results{ii}.SpeciesNames;
        obj.SimResults{SelectedInds(ii)}.Data = Results{ii}.Data;
        obj.SimResults{SelectedInds(ii)}.VpopWeights = Results{ii}.VpopWeights;
    end
else
    Results = [];
end


%% add the cached results to get the complete simulation results

% add cached results
indCached = find(IsSelected & IsCached);
newResults = [];

for ii = 1:length(indCached)
    newResults{indCached(ii)} = obj.SimResults{indCached(ii)}; %#ok<AGROW>
end

indNotCached = find(IsSelected & ~IsCached);
if ~isempty(Results)
    for ii = 1:length(indNotCached)
        newResults{indNotCached(ii)} = Results{ii}; %#ok<AGROW>
    end
end

if ~isempty(newResults)
    Results = newResults(~cellfun(@isempty,newResults)); % combined cached & new simulations
end


%% Plot Simulation Items

if strcmp(obj.PlotType,'Normal') && ~isempty(Results)    
    % Shared utility used by both Cohort and VP
    hSpeciesGroup = i_plotSimSharedHelper(obj,hAxes,Mode,Results,ThisHeader,ThisData);
    
elseif strcmpi(Mode,'Cohort') && strcmp(obj.PlotType,'Diagnostic') && ~isempty(Results)    
    i_plotCohortDiagnosticHelper(obj,hAxes,Results,ThisHeader,ThisData);
    
end %if PlotType is normal


%% Plot Dataset

if StatusOK
    if strcmpi(Mode,'Cohort') && strcmp(obj.PlotType,'Normal')
        hDatasetGroup = i_plotCohortDataHelper(obj,hAxes,ThisHeader,ThisData);
        
    elseif strcmpi(Mode,'VP')
        hDatasetGroup = i_plotVPDataHelper(obj,hAxes,Results,ThisHeader,ThisData);
    end %if
end


%% Legend

% Force a drawnow, to avoid legend issues
drawnow;

[hLegend,hLegendChildren] = updatePlots(obj,hAxes,hSpeciesGroup,hDatasetGroup);


%% Turn off hold

for index = 1:numel(hAxes)
    title(hAxes(index),obj.PlotSettings(index).Title,...
        'FontSize',obj.PlotSettings(index).TitleFontSize,...
        'FontWeight',obj.PlotSettings(index).TitleFontWeight); % sprintf('Plot %d',index));
    set(hAxes(index),...
        'XGrid',obj.PlotSettings(index).XGrid,...
        'YGrid',obj.PlotSettings(index).YGrid,...
        'XMinorGrid',obj.PlotSettings(index).XMinorGrid,...
        'YMinorGrid',obj.PlotSettings(index).YMinorGrid);
    set(hAxes(index).XAxis,...
        'FontSize',obj.PlotSettings(index).XTickLabelFontSize,...
        'FontWeight',obj.PlotSettings(index).XTickLabelFontWeight);
    set(hAxes(index).YAxis,...
        'FontSize',obj.PlotSettings(index).YTickLabelFontSize,...
        'FontWeight',obj.PlotSettings(index).YTickLabelFontWeight);
    xlabel(hAxes(index),obj.PlotSettings(index).XLabel,...
        'FontSize',obj.PlotSettings(index).XLabelFontSize,...
        'FontWeight',obj.PlotSettings(index).XLabelFontWeight); % 'Time');
    ylabel(hAxes(index),obj.PlotSettings(index).YLabel,...
        'FontSize',obj.PlotSettings(index).YLabelFontSize,...
        'FontWeight',obj.PlotSettings(index).YLabelFontWeight); % 'States');
    set(hAxes(index),'YScale',obj.PlotSettings(index).YScale);
    
    hold(hAxes(index),'off')
    % Reset zoom state
    hFigure = ancestor(hAxes(index),'Figure');
    if ~isempty(hFigure) && strcmpi(obj.PlotSettings(index).XLimMode,'auto') && strcmpi(obj.PlotSettings(index).YLimMode,'auto')
        set(hFigure,'CurrentAxes',hAxes(index)) % This causes the legend fontsize to reset: axes(hAxes(index));
        try
            zoom(hFigure,'out');
            zoom(hFigure,'reset');
        catch ME
            warning(ME.message);
        end
    end
end



%--------------------------------------------------------------------------
%% Helper functions
%--------------------------------------------------------------------------

function hSpeciesGroup = i_plotSimSharedHelper(obj,hAxes,Mode,Results,ThisHeader,ThisData)

if strcmpi(Mode,'Cohort')
    accCritHeader = ThisHeader;
    accCritData = ThisData;    
else
    vpopGenHeader = ThisHeader;
    vpopGenData = ThisData;    
end

NumAxes = numel(hAxes);
OrigIsSelected = obj.PlotItemTable(:,1);
if iscell(OrigIsSelected)
    OrigIsSelected = cell2mat(OrigIsSelected);
end
OrigIsSelected = find(OrigIsSelected);

% Get the associated colors
ItemColors = cell2mat(obj.PlotItemTable(:,2));

% Process all
IsSelected = true(size(obj.PlotItemTable,1),1);
ResultsIdx = find(IsSelected);

hSpeciesGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);

for sIdx = 1:size(obj.PlotSpeciesTable,1)
    origAxIdx = str2double(obj.PlotSpeciesTable{sIdx,1});
    axIdx = origAxIdx;
    if isempty(axIdx) || isnan(axIdx)
        axIdx = 1;
    end
    
    ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
    ThisName = obj.PlotSpeciesTable{sIdx,3};
    ThisDataName = obj.PlotSpeciesTable{sIdx,4};
    ThisDisplayName = obj.PlotSpeciesTable{sIdx,5};
    
    acc_lines = [];
    rej_lines = [];
    ublb_lines = [];
    
    
    for itemIdx = 1:numel(Results)
        itemNumber = ResultsIdx(itemIdx);
        % Plot the species from the simulation item in the appropriate
        % color
        
        % Check if it is a selected item
        if ismember(itemNumber,OrigIsSelected)
            IsVisible = true;
        else
            IsVisible = false;
        end
        
        % Get the match in Sim 1 (Virtual Patient 1) in this VPop
        ColumnIdx = find(strcmp(Results{itemIdx}.SpeciesNames,ThisName));
        
        % since not all tasks will contain all species...
        if ~isempty(ColumnIdx)
            % Update ColumnIdx to get species for ALL virtual patients
            NumSpecies = numel(Results{itemIdx}.SpeciesNames);
            ColumnIdx = ColumnIdx:NumSpecies:size(Results{itemIdx}.Data,2);
            ColumnIdx_invalid = find(strcmp(Results{itemIdx}.SpeciesNames,ThisName)) + (find(Results{itemIdx}.VpopWeights==0)-1) * NumSpecies;
            
            
            if isempty(hSpeciesGroup{sIdx,axIdx})
                % Un-parent if not-selected
                if isempty(origAxIdx) || isnan(origAxIdx)
                    ThisParent = matlab.graphics.GraphicsPlaceholder.empty();
                else
                    ThisParent = hAxes(axIdx);
                end
                hSpeciesGroup{sIdx,axIdx} = hggroup(ThisParent,...
                    'Tag','Species',...
                    'DisplayName',regexprep(sprintf('%s [Sim]',ThisDisplayName),'_','\\_'),...
                    'UserData',sIdx);
                set(get(get(hSpeciesGroup{sIdx,axIdx},'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
                % Add dummy line for legend
                line(nan,nan,'Parent',hSpeciesGroup{sIdx,axIdx},...
                    'LineStyle',ThisLineStyle,...
                    'Color',[0 0 0],...
                    'Tag','DummyLine',...
                    'UserData',sIdx);
            end
            
            % Normal plot type
            % plot over for just the invalid / rejected vpatients
            
            % transform data
            thisData = obj.SpeciesData(sIdx).evaluate(Results{itemIdx}.Data);
            
            % invalid lines
            if ~isempty(ColumnIdx_invalid)
                % Plot
                hThis = plot(hSpeciesGroup{sIdx,axIdx},Results{itemIdx}.Time,thisData(:,ColumnIdx_invalid),...
                    'Color',[0.5,0.5,0.5],...
                    'Tag','InvalidVP',...
                    'LineStyle',ThisLineStyle,...
                    'LineWidth',obj.PlotSettings(axIdx).LineWidth,...
                    'UserData',[sIdx,itemIdx]);
                if obj.ShowInvalidVirtualPatients
                    set(hThis,'Visible','on');
                else
                    set(hThis,'Visible','off');
                end
                setIconDisplayStyleOff(hThis);
                rej_lines = [rej_lines; hThis]; %#ok<AGROW>
                
            end
            
            % valid lines
            if ~isempty(Results{itemIdx}.Data(:,setdiff(ColumnIdx, ColumnIdx_invalid)))
                
                if iscell(Results{itemIdx}.VpopWeights)
                    vpopWeights = cell2mat(Results{itemIdx}.VpopWeights);
                else
                    vpopWeights = Results{itemIdx}.VpopWeights;
                end
                
                if strcmpi(Mode,'Cohort')
                    % Cohort
                    x = thisData(:,setdiff(ColumnIdx, ColumnIdx_invalid));
                    w = ones(size(x,2),1) * 1/size(x,2);
                else
                    % VP
                    x = thisData(:,ColumnIdx);
                    w = vpopWeights/sum(vpopWeights);
                end
                
                % Plot TraceLine
                if length(Results{itemIdx}.Time) == 1
                    ThisMarkerStyle = 'o';
                else
                    ThisMarkerStyle = 'none';
                end                
                
                hThisTrace = plot(hSpeciesGroup{sIdx,axIdx},Results{itemIdx}.Time,thisData(:,setdiff(ColumnIdx, ColumnIdx_invalid)),...
                    'Color',ItemColors(itemIdx,:),...
                    'Tag','TraceLine',...
                    'LineStyle',ThisLineStyle,...
                    'LineWidth',obj.PlotSettings(axIdx).LineWidth,...
                    'UserData',[sIdx,itemIdx],...
                    'Marker', ThisMarkerStyle);
                
                setIconDisplayStyleOff(hThisTrace);
                acc_lines = [acc_lines; hThisTrace]; %#ok<AGROW>
                if obj.bShowTraces(axIdx)
                    set(hThisTrace,'Visible','on');
                else
                    set(hThisTrace,'Visible','off');
                end
                % Set visibility
                set(hThisTrace,...
                    'Visible',uix.utility.tf2onoff(IsVisible && obj.bShowTraces(axIdx)));
                
                % Plot WeightedQuantile
                
                % NOTE: If hSpeciesGroup is not parented to an
                % axes, then this will pop up a new figure. Set to an
                % axes and then re-parent after
                hThisParent = ancestor(hSpeciesGroup{sIdx,axIdx},'axes');
                % Temporarily parent to the first axes
                if isempty(hThisParent)
                    hThisParent = hAxes(1);
                end
                
                % use median for cohort, mean for vpop
%                 if strcmpi(Mode,'Cohort')
%                     style = 'quantile';
%                 else 
%                     style = 'mean_std';
%                 end

                % use mean for all
                style = 'mean_std';
                
                SE = weightedQuantilePlot(Results{itemIdx}.Time, x, w, ItemColors(itemIdx,:),...
                    'linestyle',ThisLineStyle,...
                    'meanlinewidth',obj.PlotSettings(axIdx).MeanLineWidth,...
                    'medianlinewidth',obj.PlotSettings(axIdx).MedianLineWidth,...
                    'boundarylinewidth',obj.PlotSettings(axIdx).BoundaryLineWidth,...
                    'quantile',[obj.PlotSettings(axIdx).BandplotLowerQuantile, obj.PlotSettings(axIdx).BandplotUpperQuantile],...
                    'parent',hThisParent, ...
                    'style', style); % hSpeciesGroup{sIdx,axIdx});
                
                
                if isa(SE, 'matlab.graphics.chart.primitive.ErrorBar')
                    % error bar (one time point)
                    set(SE, 'Parent',hSpeciesGroup{sIdx,axIdx});
                else
                    % shaded error bar
                    set([SE.meanLine,SE.medianLine,SE.edge,SE.patch],'Parent',hSpeciesGroup{sIdx,axIdx});
                end

                if isempty(SE)
                    continue
                end
                                
                if ~isa(SE, 'matlab.graphics.chart.primitive.ErrorBar')
                    setIconDisplayStyleOff([SE.meanLine,SE.medianLine,SE.edge,SE.patch]);            
                end

                
                if obj.bShowMean(axIdx)
                    set(SE.meanLine,'Visible','on');
                else
                    set(SE.meanLine,'Visible','off');
                end
                if obj.bShowMedian(axIdx)
                    set(SE.medianLine,'Visible','on');
                else
                    set(SE.medianLine,'Visible','off');
                end
                if obj.bShowQuantiles(axIdx)
                    if isa(SE, 'matlab.graphics.chart.primitive.ErrorBar')
                        set(SE, 'Visible', 'on');
                    else
                        set([SE.edge,SE.patch],'Visible','on');
                    end
                else
                    if isa(SE, 'matlab.graphics.chart.primitive.ErrorBar')
                        set(SE, 'Visible', 'off')
                    else
                        set([SE.edge,SE.patch],'Visible','off');    
                    end
                end
                % Set visibility
                if ~isempty(SE) && isstruct(SE) && isfield(SE,'meanLine')
                    set([SE.meanLine,SE.medianLine,SE.edge,SE.patch],...
                        'UserData',[sIdx,itemIdx],...
                        'Visible',uix.utility.tf2onoff(IsVisible && obj.bShowQuantiles(axIdx)));
                elseif ~isempty(SE) && isa(SE, 'matlab.graphics.chart.primitive.ErrorBar')
                    set(SE,  'UserData',[sIdx,itemIdx],... % SE.meanLine
                        'Visible',uix.utility.tf2onoff(IsVisible));               
                end
                
                
%                 % Plot Mean line
%                 if strcmpi(Mode,'Cohort')
%                     % Cohort
%                     
%                     % Mean line
%                     hThis = plot(hSpeciesGroup{sIdx,axIdx}, Results{itemIdx}.Time, thisData(:,ColumnIdx) * ...
%                         vpopWeights/sum(vpopWeights),...
%                         'LineStyle',ThisLineStyle,...
%                         'Color',ItemColors(itemIdx,:),...
%                         'UserData',[sIdx,itemIdx],... % SE.meanLine
%                         'Tag','WeightedMeanLine',... % TODO: Validate
%                         'LineWidth',obj.PlotSettings(axIdx).MeanLineWidth);      
%                     
%                     setIconDisplayStyleOff(hThis);
%                     set(hThis,'Visible',uix.utility.tf2onoff(IsVisible && ~obj.bShowQuantiles(axIdx)));
%                 else
%                     % VP
%                     spData = vpopGenData( cell2mat(vpopGenData(:,strcmp(vpopGenHeader,'Group'))) == str2num(obj.PlotItemTable{itemNumber,4}) & ...
%                         strcmp(vpopGenData(:,strcmp(vpopGenHeader,'Species')), ThisDataName), :); %#ok<ST2NM>
%                     val1 = cell2mat(spData(:, strcmp(vpopGenHeader, 'Value1')));
%                     
%                     type = spData(:, strcmp(vpopGenHeader, 'Type'));
%                     times = cell2mat(spData(:, strcmp(vpopGenHeader, 'Time')));
%                     ixMean = strcmp(type,'MEAN');
%                     
%                     % Mean line
%                     hThis = plot(hSpeciesGroup{sIdx,axIdx}, times(ixMean), val1(ixMean), ...
%                         'LineStyle',ThisLineStyle,...
%                         'Color',ItemColors(itemIdx,:),...
%                         'UserData',[sIdx,itemIdx],... % SE.meanLine
%                         'Tag','WeightedMeanLine',... % TODO: Validate
%                         'LineWidth',obj.PlotSettings(axIdx).MeanLineWidth);
%                     
                    % Show simulation standard deviations
%                 end
                
                % Only allow one display name - don't attach to
                % traces and quantiles and instead attach to mean
                % line
                %                     set(hThis(1),'DisplayName',regexprep(sprintf('%s [Sim]',FullDisplayName),'_','\\_')); % For export, use patch since line width is not applied
%                 setIconDisplayStyleOff(hThis);
%                 set(hThis,'Visible',uix.utility.tf2onoff(IsVisible && ~obj.bShowQuantiles(axIdx)));
                
            end %if
            
            
            % Plot bounds - Cohort only
            if strcmpi(Mode,'Cohort')
                % Cohort
                
                % add upper and lower bounds if applicable
                DataCol = find(strcmp(accCritHeader,'Data'));
                accName = obj.PlotSpeciesTable(strcmp(ThisDataName,obj.PlotSpeciesTable(:,4)),4);
                
                accDataRows = strcmp(accCritData(:,DataCol), accName) & ...
                    cell2mat(accCritData(:,strcmp(accCritHeader,'Group'))) == str2num(obj.PlotItemTable{itemNumber,4}) ; %#ok<FNDSB,ST2NM>
                LB = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'LB')));
                UB = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'UB')));
                accTime = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'Time')));
                
                if any(accDataRows)
                    % Plot Lower Bound
                    hThis = plot(hSpeciesGroup{sIdx,axIdx},accTime,LB,...
                        'MarkerFaceColor', ItemColors(itemIdx,:),...
                        'MarkerEdgeColor','k',...
                        'LineWidth',obj.PlotSettings(axIdx).BoundaryLineWidth,... 'LineWidth',2,...
                        'LineStyle','none',...
                        'Tag','LowerBound',...
                        'UserData',[sIdx,itemIdx]);
                    setIconDisplayStyleOff(hThis);
                    ublb_lines = [ublb_lines; hThis]; %#ok<AGROW>
                    
                    % Plot Upper Bound
                    hThis = plot(hSpeciesGroup{sIdx,axIdx},accTime,UB,...
                        'MarkerFaceColor',ItemColors(itemIdx,:),...
                        'MarkerEdgeColor','k',...
                        'LineWidth',obj.PlotSettings(axIdx).BoundaryLineWidth,... 'LineWidth',2,... % TODO: Ask Iraj
                        'LineStyle','none',...
                        'Tag','UpperBound',...
                        'UserData',[sIdx,itemIdx]);
                    setIconDisplayStyleOff(hThis);
                    ublb_lines = [ublb_lines; hThis]; %#ok<AGROW>
                    
                end %if
            end % if Cohort
            
            % plot the standard deviations (VP only)
            mu = thisData(:,ColumnIdx) * vpopWeights/sum(vpopWeights) ;
            wSD = sqrt((thisData(:,ColumnIdx) - mu).^2* ...
                vpopWeights/sum(vpopWeights));

            hu = plot(hSpeciesGroup{sIdx,axIdx}, Results{itemIdx}.Time, mu + wSD,...%                         'LineStyle','none',...
                'LineStyle',ThisLineStyle,...%                         'Marker', '^', ...%                         'MarkerSize',5,...
                'LineWidth',obj.PlotSettings(axIdx).StandardDevLineWidth,...
                'Color',ItemColors(itemIdx,:),...
                'UserData',[sIdx,itemIdx],...
                'Tag','WeightedSD'... % TODO: Validate
                );

            hl = plot(hSpeciesGroup{sIdx,axIdx}, Results{itemIdx}.Time, mu - wSD,...
                'LineStyle', ThisLineStyle, ...
                'LineWidth',obj.PlotSettings(axIdx).StandardDevLineWidth,...
                'Color',ItemColors(itemIdx,:),...
                'UserData',[sIdx,itemIdx],...
                'Tag','WeightedSD'... % TODO: Validate
                );

            setIconDisplayStyleOff([hl,hu]);
            set([hu,hl],'Visible',uix.utility.tf2onoff(IsVisible && obj.bShowSD(axIdx)));
        end %if
    end %for
    
    overlays = [ublb_lines; acc_lines; rej_lines];
    if ~isempty(overlays)
        uistack(overlays,'top');
    end
    
end %for
    

function i_plotCohortDiagnosticHelper(obj,hAxes,Results,ThisHeader,ThisData)

% Cohort
accCritHeader = ThisHeader;
accCritData = ThisData;
grpVec = cell2mat(accCritData(:,strcmp('Group', accCritHeader)));
LBVec = cell2mat(accCritData(:,strcmp('LB', accCritHeader)));
UBVec = cell2mat(accCritData(:,strcmp('UB', accCritHeader)));
DataVec = accCritData(:,strcmp('Data', accCritHeader));
TimeVec = cell2mat(accCritData(:,strcmp('Time', accCritHeader)));

% Get the associated colors
ItemColors = cell2mat(obj.PlotItemTable(:,2));

% all axes with species assigned to them
allAxes = str2double(obj.PlotSpeciesTable(:,1));

% Process all
IsSelected = true(size(obj.PlotItemTable,1),1);
ResultsIdx = find(IsSelected);

OrigIsSelected = obj.PlotItemTable(:,1);
if iscell(OrigIsSelected)
    OrigIsSelected = cell2mat(OrigIsSelected);
end
OrigIsSelected = find(OrigIsSelected);

% all species names
%     spNames = obj.PlotSpeciesTable(:,3);
dataNames = obj.PlotSpeciesTable(:,4);

% loop over axes
unqAxis = unique(allAxes);
for axIdx = 1:numel(unqAxis)
    currentAxis = unqAxis(axIdx);
    %         cla(hAxes(unqAxis(axIdx)))
    
    % get all species for this axis
    axData = dataNames(allAxes==currentAxis);
    
    axDataArray = {};
    xlabArray = {};
    colorArray = {};
    UBArray = [];
    LBArray = [];
    
    % loop over the species on this axis
    for dataIdx = 1:length(axData)
        currentData = axData(dataIdx);
        currentDataIdx = strcmp(currentData, obj.PlotSpeciesTable(:,4));
        % loop over all tasks and get the data for this species
        for itemIdx = 1:numel(Results)
            
            itemNumber = ResultsIdx(itemIdx);
            
            if ~ismember(itemNumber,OrigIsSelected)
                continue;
            end
            
            % species in this task
            NumSpecies = numel(Results{itemIdx}.SpeciesNames);
            currentSpecies = obj.PlotSpeciesTable( strcmp(obj.PlotSpeciesTable(:,4), currentData), 3);
            % time points for this species in this group in the acc. crit.
            thisTime = TimeVec(grpVec == str2num(obj.PlotItemTable{itemNumber,4}) & strcmp(DataVec, currentData)); %#ok<ST2NM>
            if isempty(thisTime)
                continue
            end
            
            % ub/lb
            thisUB = UBVec(grpVec == str2num(obj.PlotItemTable{itemNumber,4}) & strcmp(DataVec, currentData)); %#ok<ST2NM>
            thisLB = LBVec(grpVec == str2num(obj.PlotItemTable{itemNumber,4}) & strcmp(DataVec, currentData)); %#ok<ST2NM>
            
            % get times that are in the acceptance criteria for this task / species
            [b_time,timeIdx] = ismember(thisTime, Results{itemIdx}.Time);
            timeIdx = timeIdx(b_time); % rows to subset for data distributions
            
            % index of all columns for this species in this group
            NumVpop = size(Results{itemIdx}.Data,2) / NumSpecies;
            
            if ~obj.ShowInvalidVirtualPatients && ~isempty(Results{itemIdx}.VpopWeights)
                if isempty(Results{itemIdx}.VpopWeights)
                    ColumnIdx = find( strcmp(Results{itemIdx}.SpeciesNames, currentSpecies)) + (0:NumVpop-1)*NumSpecies;
                    warning('plotVirtualPopulationGeneration: missing prevalence weights in vpop. Showing all trajectories.')
                else
                    ColumnIdx = find( strcmp(Results{itemIdx}.SpeciesNames, currentSpecies)) + (find(Results{itemIdx}.VpopWeights)-1)*NumSpecies ;
                    if isempty(ColumnIdx)
                        return
                    end
                end
            else
                ColumnIdx = find( strcmp(Results{itemIdx}.SpeciesNames, currentSpecies)) + (0:NumVpop-1)*NumSpecies;
            end
            
            thisData = obj.SpeciesData(currentDataIdx).evaluate(Results{itemIdx}.Data(:, ColumnIdx));
            thisData = thisData(timeIdx, :);
            
            for tix = 1:length(timeIdx)
                axDataArray = [axDataArray, thisData(tix,:)]; %#ok<AGROW>
            end
            
            xlabArray = [xlabArray; num2cell(thisTime)]; %#ok<AGROW> % add labels to array
            colorArray = [colorArray; repmat({ItemColors(itemIdx,:)}, length(thisTime), 1)]; %#ok<AGROW>
            UBArray = [UBArray; thisUB]; %#ok<AGROW>
            LBArray = [LBArray; thisLB]; %#ok<AGROW>
        end
    end
    
    % plot distribution plots for this axis
    if isempty(axDataArray)
        continue
    end
    warning('off','DISTRIBUTIONPLOT:ERASINGLABELS')
    distributionPlot(hAxes(currentAxis), axDataArray, 'color', colorArray, 'xNames', xlabArray, 'showMM', 0, 'histOpt', 0)
    
    % add error bars
    for k=1:length(UBArray)
        errorbar(hAxes(currentAxis), k, (UBArray(k)+LBArray(k))/2, (UBArray(k)-LBArray(k))/2, 'Marker', 's', 'LineStyle', 'none',  ..., ...
            'Color', 'k',...
            'LineWidth',obj.PlotSettings(currentAxis).LineWidth);
        %                             'LineWidth', 2) % colorArray{k} TODO: Ask Iraj
    end
    
end

    
%% ------------------------------------------------------------------------
function hDatasetGroup = i_plotCohortDataHelper(obj,hAxes,ThisHeader,ThisData)

AccCritHeader = ThisHeader;
AccCritData = ThisData;

NumAxes = numel(hAxes);
hDatasetGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);

OrigIsSelected = obj.PlotItemTable(:,1);
if iscell(OrigIsSelected)
    OrigIsSelected = cell2mat(OrigIsSelected);
end
OrigIsSelected = find(OrigIsSelected);

% Process all
SelectedGroupColors = vertcat(obj.PlotItemTable{:,2});
SelectedGroupIDs = categorical(obj.PlotItemTable(:,4));
SelectedItemNames = obj.PlotItemTable(:,5);

% Get the Group Column from the imported dataset
GroupColumn = AccCritData(:,strcmp(AccCritHeader,obj.GroupName));
if iscell(GroupColumn)
    % If numeric column, convert to matrix to use categorical
    IsNumeric = cellfun(@(x)isnumeric(x),GroupColumn);
    if all(IsNumeric)
        GroupColumn = cell2mat(GroupColumn);
    else
        GroupColumn(IsNumeric) = cellfun(@(x)num2str(x),GroupColumn(IsNumeric),'UniformOutput',false);
    end
end
GroupColumn = categorical(GroupColumn);

% Get the Time Column from the imported dataset
TimeColumn = AccCritData(:,strcmp(AccCritHeader,'Time'));

% Get the Species Column from the imported dataset
SpeciesDataColumn = AccCritData(:,strcmp(AccCritHeader,'Data'));

for dIdx = 1:size(obj.PlotSpeciesTable,1)
    origAxIdx = str2double(obj.PlotSpeciesTable{dIdx,1});
    axIdx = origAxIdx;
    if isempty(axIdx) || isnan(axIdx)
        axIdx = 1;
    end
    ThisName = obj.PlotSpeciesTable{dIdx,4};
    ThisMarker = '*';
    ThisDisplayName = obj.PlotSpeciesTable{dIdx,5};
    
    if ~isempty(axIdx) && ~isnan(axIdx)
        for gIdx = 1:numel(SelectedGroupIDs)
            
            if ismember(gIdx,OrigIsSelected)
                IsVisible = true;
            else
                IsVisible = false;
            end
            
            % Find the GroupID match within the GroupColumn and
            % species name match within the SpeciesColumn
            MatchIdx = (GroupColumn == SelectedGroupIDs(gIdx) & strcmp(SpeciesDataColumn,ThisName));
            
            % Plot the lower and upper bounds associated with
            % the selected Group and Species, for each time
            % point
            % Create a group
            if isempty(hDatasetGroup{dIdx,axIdx})
                % Un-parent if not-selected
                if isempty(origAxIdx) || isnan(origAxIdx)
                    ThisParent = matlab.graphics.GraphicsPlaceholder.empty();
                else
                    ThisParent = hAxes(axIdx);
                end
                
                hDatasetGroup{dIdx,axIdx} = hggroup(ThisParent,...shaded
                    'Tag','Data',...
                    'DisplayName',regexprep(sprintf('%s [Data]',ThisDisplayName),'_','\\_'),...
                    'UserData',dIdx);
                
                set(get(get(hDatasetGroup{dIdx,axIdx},'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
                % Add dummy line for legend
                line(nan,nan,'Parent',hDatasetGroup{dIdx,axIdx},...
                    'LineStyle','none',...
                    'Marker',ThisMarker,...
                    'Color',[0 0 0],...
                    'Tag','DummyLine',...
                    'UserData',dIdx);
            end
            
            % Plot but remove from the legend
            if any(MatchIdx)
                FullDisplayName = sprintf('%s %s',ThisDisplayName,SelectedItemNames{gIdx});
                
                hThis = plot(hDatasetGroup{dIdx,axIdx},[TimeColumn{MatchIdx}],[AccCritData{MatchIdx,strcmp(AccCritHeader,'LB')}], ...
                    [TimeColumn{MatchIdx}],[AccCritData{MatchIdx,strcmp(AccCritHeader,'UB')}],...
                    'LineStyle','none',...
                    'Marker',ThisMarker,...
                    'MarkerSize',obj.PlotSettings(axIdx).DataSymbolSize,...
                    'Color',SelectedGroupColors(gIdx,:),...
                    'UserData',[dIdx,gIdx]);
                set(hThis(1),'DisplayName',regexprep(sprintf('%s [Data]',FullDisplayName),'_','\\_')); % For export 'DisplayName',regexprep(sprintf('%s',ThisName),'_','\\_'));
                setIconDisplayStyleOff(hThis);
                
                set(hThis,'Visible',uix.utility.tf2onoff(IsVisible));
                
            end %if
        end %for
    end %if
end %for


%% ------------------------------------------------------------------------
function hDatasetGroup = i_plotVPDataHelper(obj,hAxes,Results,ThisHeader,ThisData)

vpopGenHeader = ThisHeader;
vpopGenData = ThisData;

OrigIsSelected = obj.PlotItemTable(:,1);
if iscell(OrigIsSelected)
    OrigIsSelected = cell2mat(OrigIsSelected);
end
OrigIsSelected = find(OrigIsSelected);

% Process all
IsSelected = true(size(obj.PlotItemTable,1),1);
ResultsIdx = find(IsSelected);

% Get the associated colors
ItemColors = cell2mat(obj.PlotItemTable(:,2));

NumAxes = numel(hAxes);
ThisMarker = 'o';
hDatasetGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);

for sIdx = 1:size(obj.PlotSpeciesTable,1)
    origAxIdx = str2double(obj.PlotSpeciesTable{sIdx,1});
    axIdx = origAxIdx;
    if isempty(axIdx) || isnan(axIdx)
        axIdx = 1;
    end
    
    ThisDisplayName = obj.PlotSpeciesTable{sIdx,5};
    
    % Plot the lower and upper bounds associated with
    % the selected Group and Species, for each time
    % point
    % Create a group
    if isempty(hDatasetGroup{sIdx,axIdx})
        % Un-parent if not-selected
        if isempty(origAxIdx) || isnan(origAxIdx)
            ThisParent = matlab.graphics.GraphicsPlaceholder.empty();
        else
            ThisParent = hAxes(axIdx);
        end
        
        hDatasetGroup{sIdx,axIdx} = hggroup(ThisParent,...shaded
            'Tag','Data',...
            'DisplayName',regexprep(sprintf('%s [Data]',ThisDisplayName),'_','\\_'),...
            'UserData',sIdx);
        
        set(get(get(hDatasetGroup{sIdx,axIdx},'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
        % Add dummy line for legend
        line(nan,nan,'Parent',hDatasetGroup{sIdx,axIdx},...
            'LineStyle','none',...
            'Marker',ThisMarker,...
            'Color',[0 0 0],...
            'Tag','DummyLine',...
            'UserData',sIdx);
    end
    
    % ThisName = obj.PlotSpeciesTable{sIdx,3};
    ThisDataName = obj.PlotSpeciesTable{sIdx,4};
    ThisDisplayName = obj.PlotSpeciesTable{sIdx,5};
    
    for itemIdx = 1:numel(Results)
        
        FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotItemTable{itemIdx,5});
        
        itemNumber = ResultsIdx(itemIdx);
        % Plot the species from the simulation item in the appropriate
        % color
        
        % Check if it is a selected item
        if ismember(itemNumber,OrigIsSelected)
            IsVisible = true;
        else
            IsVisible = false;
        end
        % VP
        spData = vpopGenData( cell2mat(vpopGenData(:,strcmp(vpopGenHeader,'Group'))) == str2num(obj.PlotItemTable{itemNumber,4}) & ...
            strcmp(vpopGenData(:,strcmp(vpopGenHeader,'Species')), ThisDataName), :); %#ok<ST2NM>
        val1 = cell2mat(spData(:, strcmp(vpopGenHeader, 'Value1')));
        val2 = cell2mat(spData(:, strcmp(vpopGenHeader, 'Value2')));
        
        type = spData(:, strcmp(vpopGenHeader, 'Type'));
        times = cell2mat(spData(:, strcmp(vpopGenHeader, 'Time')));
        ixMean = strcmp(type,'MEAN');
        ixMeanStd = strcmp(type,'MEAN_STD');
        
        hThis = plot(hDatasetGroup{sIdx,axIdx}, times(ixMean), val1(ixMean), ...
            'LineStyle','none',...
            'Marker',ThisMarker,...
            'Color',ItemColors(itemIdx,:),...
            'UserData',[sIdx,itemIdx],... % SE.meanLine
            'Tag','WeightedMeanMarker',... % TODO: Validate
            'MarkerSize',obj.PlotSettings(axIdx).DataSymbolSize);
        
        % Only allow one display name - don't attach to`
        % traces and quantiles and instead attach to mean
        % line
        %                     set(hThis(1),'DisplayName',regexprep(sprintf('%s [Sim]',FullDisplayName),'_','\\_')); % For export, use patch since line width is not applied
        setIconDisplayStyleOff(hThis);
        set(hThis,'Visible',uix.utility.tf2onoff(IsVisible));
        
        if any(ixMeanStd)
            % NOTE: If hSpeciesGroup is not parented to an
            % axes, then this line will error. Set to an
            % axes and then re-parent after
            hThisParent = ancestor(hDatasetGroup{sIdx,axIdx},'axes');
            % Temporarily parent to the first axes
            if isempty(hThisParent)
                hThisParent = hAxes(1);
            end
            hThis = errorbar('Parent',hThisParent,...
                times(ixMeanStd), val1(ixMeanStd), val2(ixMeanStd), ThisMarker, 'Color', ItemColors(itemIdx,:),...
                'LineWidth',obj.PlotSettings(axIdx).LineWidth,...
                'MarkerSize',obj.PlotSettings(axIdx).DataSymbolSize,...
                'UserData',[sIdx,itemIdx],...
                'Tag','Errorbar');
            set(hThis,'Parent',hDatasetGroup{sIdx,axIdx});
        end
        setIconDisplayStyleOff(hThis);
        
        set(hThis(1),'DisplayName',regexprep(sprintf('%s [Data]',FullDisplayName),'_','\\_')); % For export 'DisplayName',regexprep(sprintf('%s',ThisName),'_','\\_'));
    end
end