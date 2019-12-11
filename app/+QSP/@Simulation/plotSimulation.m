function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotSimulation(obj,hAxes)
% plotSimulation - plots the simulation
% -------------------------------------------------------------------------
% Abstract: This plots the simulation analysis.
%
% Syntax:
%           plotSimulation(aObj,hAxes)
%
% Inputs:
%           obj - QSP.Simulation object
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

%% Turn on hold

for index = 1:numel(hAxes)

    cla(hAxes(index));
    legend(hAxes(index),'off')    

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
hDatasetGroup = cell(size(obj.PlotDataTable,1),NumAxes);


%% Get the selections and MATResultFilePaths

% Get the selected items
OrigIsSelected = obj.PlotItemTable(:,1);
if iscell(OrigIsSelected)
    OrigIsSelected = cell2mat(OrigIsSelected);
end
OrigIsSelected = find(OrigIsSelected);

% Process all
IsSelected = 1:size(obj.PlotItemTable,1);

TaskNames = {obj.Item.TaskName};
VPopNames = {obj.Item.VPopName};
Groups = {obj.Item.Group};

if ~isempty(IsSelected)
    MATFileNames = {};
    ItemIndices = [];
    for index = IsSelected(:)'
        % Find the match of obj.PlotItemTable back in obj.Item
        ThisTaskName = obj.PlotItemTable{index,3};
        ThisVPopName = obj.PlotItemTable{index,4};
        ThisTask = getValidSelectedTasks(obj.Settings,ThisTaskName);
        ThisVPop = getValidSelectedVPops(obj.Settings,ThisVPopName);        
        ThisGroup = obj.PlotItemTable{index,5};
        
        if ~isempty(ThisTask) && (~isempty(ThisVPop) || strcmp(ThisVPopName,QSP.Simulation.NullVPop))
            MatchIdx = strcmp(ThisTaskName,TaskNames) & strcmp(ThisVPopName,VPopNames) & strcmp(ThisGroup, Groups);
            if any(MatchIdx)
                ThisFileName = {obj.Item(MatchIdx).MATFileName};
                MATFileNames = [MATFileNames,ThisFileName]; %#ok<AGROW>
                ItemIndices = [ItemIndices,index]; %#ok<AGROW>
            end
        end
    end
    ResultsDir = fullfile(obj.Session.RootDirectory,obj.SimResultsFolderName);
    MATResultFilePaths = cellfun(@(X) fullfile(ResultsDir,X), MATFileNames, 'UniformOutput', false);
else
    MATResultFilePaths = {};
end


%% Load the MATResultFilePaths

Results = [];
% Load selected MAT files
for index = 1:numel(MATResultFilePaths)
    if ~isdir(MATResultFilePaths{index}) && exist(MATResultFilePaths{index},'file')
        ThisFileData = load(MATResultFilePaths{index},'Results');
        if isfield(ThisFileData,'Results') && ...
                all(isfield(ThisFileData.Results,{'Time','Data','SpeciesNames'}))
            if isempty(Results)
                Results = ThisFileData.Results;
            else
                Results(index) = ThisFileData.Results; %#ok<AGROW>
            end
        else
            warning('plotSimulation: Data cannot be loaded from %s. File must contain Results structure with fields Time, Data, SpeciesNames.',MATResultFilePaths{index});
        end
    elseif ~isdir(MATResultFilePaths{index}) % Invalid file
        fprintf('plotSimulation: Missing results file %s\n',MATResultFilePaths{index});
    end
end

% Get the associated colors

garbage = ~cellfun(@isnumeric,obj.PlotItemTable(IsSelected,2));
colors = obj.PlotItemTable(IsSelected,2);
colors(garbage,:) = {[0 0 0]};
SelectedItemColors = cell2mat(colors);


%% Plot Simulation Items

for sIdx = 1:size(obj.PlotSpeciesTable,1)
    origAxIdx = str2double(obj.PlotSpeciesTable{sIdx,1});
    axIdx = origAxIdx;
    if isempty(axIdx) || isnan(axIdx)
        axIdx = 1;
    end
    ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
    ThisName = obj.PlotSpeciesTable{sIdx,3};
    ThisDisplayName = obj.PlotSpeciesTable{sIdx,4};
    
    for resultIdx = 1:numel(Results)
        % Plot the species from the simulation item in the appropriate
        % color
        ThisResult = Results(resultIdx);
        if isempty(ThisResult.Data) || all(all(isnan(ThisResult.Data)))
            continue
        end
        itemIdx = ItemIndices(resultIdx);
        
        % Check if it is a selected item
        if ismember(itemIdx,OrigIsSelected)
            IsVisible = true;
        else
            IsVisible = false;
        end
        ThisColor = SelectedItemColors(resultIdx,:);
        
        
        FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotItemTable{itemIdx,6});
        % Get the match in Sim 1 (Virtual Patient 1) in this VPop
        ColumnIdx = find(strcmp(ThisResult.SpeciesNames,ThisName), 1); % keep only first in case of duplicate
        if isempty(ColumnIdx), continue, end
        
        % Update ColumnIdx to get species for ALL virtual patients
        NumSpecies = numel(ThisResult.SpeciesNames);
        if ~isempty(ThisResult.VpopWeights)
            ColumnIdx = ColumnIdx + (find(ThisResult.VpopWeights)-1)*NumSpecies ;
        else
            ColumnIdx = ColumnIdx:NumSpecies:size(ThisResult.Data,2);
        end
        
        if isempty(hSpeciesGroup{sIdx,axIdx})
            % Un-parent if not-selected
            if isempty(origAxIdx) || isnan(origAxIdx)
                ThisParent = matlab.graphics.GraphicsPlaceholder.empty();
            else
                ThisParent = hAxes(axIdx);
            end
            hSpeciesGroup{sIdx,axIdx} = hggroup(ThisParent,...
                'Tag','Species',...
                'DisplayName',regexprep(ThisDisplayName,'_','\\_'),...
                'UserData',sIdx);
            set(get(get(hSpeciesGroup{sIdx,axIdx},'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
            % Add dummy line for legend
            line(nan,nan,'Parent',hSpeciesGroup{sIdx,axIdx},...
                'LineStyle',ThisLineStyle,...
                'Color',[0 0 0],...
                'Tag','DummyLine',...
                'UserData',sIdx);
        end
        
        % Plot
        if ~isnumeric(ThisColor)
            error('Invalid color selected!')
        end
        
        %         if length(ThisResult.Time) > 1
        if length(ThisResult.Time) == 1
            ThisMarkerStyle = 'o';
        else
            ThisMarkerStyle = 'none';
        end
        
        hThisTrace = plot(hSpeciesGroup{sIdx,axIdx},ThisResult.Time,ThisResult.Data(:,ColumnIdx),...
            'Color',ThisColor,...
            'Tag','TraceLine',...
            'LineStyle',ThisLineStyle,...
            'LineWidth',obj.PlotSettings(axIdx).LineWidth, ...
            'Marker', ThisMarkerStyle);
        if obj.bShowTraces(axIdx)
            set(hThisTrace,'Visible','on');
        else
            set(hThisTrace,'Visible','off');
        end
        setIconDisplayStyleOff(hThisTrace);
        
        
        %                 q50 = quantile(Results(resultIdx).Data(:,ColumnIdx),0.5,2);
        %                 q75 = quantile(Results(resultIdx).Data(:,ColumnIdx),0.75,2);
        %                 q25 = quantile(Results(resultIdx).Data(:,ColumnIdx),0.25,2);
        
        w0 = ThisResult.VpopWeights;
        w0 = w0(w0>0); % filter out the zero weight simulations
        if isempty(w0)
            w0 = ones(1, size(ThisResult.Data,2)/length(ThisResult.SpeciesNames));
        end
        w0 = reshape(w0./sum(w0),[],1); % renormalization
        
        %                 NT = size(Results(resultIdx).Data,1);
        %                 q50 = zeros(1,NT);
        %                 q025 = zeros(1,NT);
        %                 q975 = zeros(1,NT);
        %                 for tIdx = 1:NT
        %                     y = Results(resultIdx).Data(tIdx,ColumnIdx);
        %                     [y,ix] = sort(y, 'Ascend');
        %                     w = w0(ix);
        %                     q50(tIdx) = y(find(cumsum(w)>=0.5, 1, 'first'));
        %                     q025(tIdx) = y(find(cumsum(w)>=0.025, 1, 'first'));
        %                     idx975 = find(cumsum(w)>=0.975, 1, 'first');
        %                     if isempty(idx975)
        %                         idx975 = length(y);
        %                     end
        %                     q975(tIdx) = y(idx975);
        %
        %                 end
        
        
        
        %                 Results(resultIdx).Data
        
        %         if length(ThisResult.Time') > 1
        %                     SE=shadedErrorBar(Results(resultIdx).Time', q50, [q975-q50;q50-q025]);
        %                     set(SE.meanLine,'Color',SelectedItemColors(itemIdx,:),...
        %                         'LineStyle',ThisLineStyle);
        %                     set(SE.patch,'FaceColor',SelectedItemColors(itemIdx,:));
        %                     set(SE.edge,'Color',SelectedItemColors(itemIdx,:),'LineWidth',2);
        x = ThisResult.Data(:,ColumnIdx);
        
        
        % NOTE: If hSpeciesGroup is not parented to an
        % axes, then this will pop up a new figure. Set to an
        % axes and then re-parent after
        hThisParent = ancestor(hSpeciesGroup{sIdx,axIdx},'axes');
        % Temporarily parent to the first axes
        if isempty(hThisParent)
            hThisParent = hAxes(1);
        end
        
        quantileStyle = 'mean_std'; % 'quantile'
        
        SE = weightedQuantilePlot(ThisResult.Time, x, w0, ThisColor, ...
            'linestyle',ThisLineStyle,...
            'meanlinewidth',obj.PlotSettings(axIdx).MeanLineWidth,...
            'medianlinewidth',obj.PlotSettings(axIdx).MedianLineWidth,...
            'boundarylinewidth',obj.PlotSettings(axIdx).BoundaryLineWidth,...
            'quantile',[obj.PlotSettings(axIdx).BandplotLowerQuantile,obj.PlotSettings(axIdx).BandplotUpperQuantile],...
            'parent',hThisParent, ...
            'style',quantileStyle ...
            ); % hSpeciesGroup{sIdx,axIdx});
        
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
            if isa(SE,'matlab.graphics.chart.primitive.ErrorBar')
                set(SE,'Visible','on');
            else
                set([SE.edge,SE.patch],'Visible','on');
            end
        else
            if isa(SE, 'matlab.graphics.chart.primitive.ErrorBar')
                set(SE,'Visible','off')
            else
                set([SE.edge,SE.patch],'Visible','off');
            end
        end
        if ~isa(SE, 'matlab.graphics.chart.primitive.ErrorBar')
            setIconDisplayStyleOff([SE.meanLine,SE.medianLine,SE.edge,SE.patch]);
        end
        
        % Only allow one display name between traces, meanLine, and
        % medianLine
        FormattedFullDisplayName = regexprep(FullDisplayName,'_','\\_'); % For export, use patch since line width is not applied
        if obj.bShowTraces(axIdx)
            % Use the first line only!
            set(hThisTrace(1),'DisplayName',FormattedFullDisplayName);
        elseif obj.bShowMean(axIdx) && ~isempty(SE) && isstruct(SE) && isfield(SE,'meanLine')
            set(SE.meanLine,'DisplayName',FormattedFullDisplayName);
        elseif obj.bShowMedian(axIdx) && ~isempty(SE) && isstruct(SE) && isfield(SE,'medianLine')
            set(SE.medianLine,'DisplayName',FormattedFullDisplayName);
        end
        
        % Set UserData and visibility
        if ~isempty(hThisTrace)
            set(hThisTrace,...
                'UserData',[sIdx,itemIdx],...
                'Visible',uix.utility.tf2onoff(IsVisible));
        end
        if ~isempty(SE) && isstruct(SE) && isfield(SE,'meanLine')
            set([SE.meanLine,SE.medianLine,SE.edge,SE.patch],...
                'UserData',[sIdx,itemIdx],... % SE.meanLine
                'Visible',uix.utility.tf2onoff(IsVisible));
        elseif ~isempty(SE) && isa(SE, 'matlab.graphics.chart.primitive.ErrorBar')
            set(SE,'UserData',[sIdx,itemIdx],... % SE.meanLine
                'Visible',uix.utility.tf2onoff(IsVisible));
        end
        
        % plot the weighted standard deviations 
        mu = x * w0 ;
        wSD = sqrt((x - mu).^2 * w0);            

        hu = plot(hSpeciesGroup{sIdx,axIdx}, ThisResult.Time, mu + wSD,...%                         'LineStyle','none',...
            'LineStyle',ThisLineStyle,...%                         'Marker', '^', ...%                         'MarkerSize',5,...
            'LineWidth',obj.PlotSettings(axIdx).StandardDevLineWidth,...
            'Color',ThisColor,...
            'UserData',[sIdx,itemIdx],...
            'Tag','WeightedSD'... % TODO: Validate
            );

        hl = plot(hSpeciesGroup{sIdx,axIdx}, ThisResult.Time, mu - wSD,...
            'LineStyle', ThisLineStyle, ...
            'LineWidth',obj.PlotSettings(axIdx).StandardDevLineWidth,...
            'Color',ThisColor,...
            'UserData',[sIdx,itemIdx],...
            'Tag','WeightedSD'... % TODO: Validate
            );

        setIconDisplayStyleOff([hl,hu]);
        set([hu,hl],'Visible',uix.utility.tf2onoff(IsVisible && obj.bShowSD(axIdx)));        
        
        
    end %for itemIdx = 1:numel(Results)
    
end %for sIdx = 1:size(obj.PlotSpeciesTable,1)


%% Plot Dataset

Names = {obj.Settings.OptimizationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

% Continue if dataset exists
if any(MatchIdx)
    % Get dataset
    dObj = obj.Settings.OptimizationData(MatchIdx);
    
    % Import
    DestDatasetType = 'wide';
    [StatusOk,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
    % Continue if OK
    if StatusOk
        OrigIsSelected = obj.PlotGroupTable(:,1);
        if iscell(OrigIsSelected)
            OrigIsSelected = cell2mat(OrigIsSelected);
        end
        
        SelectedGroupColors = cell2mat(obj.PlotGroupTable(:,2)); % IsSelected
        SelectedGroupIDs = categorical(obj.PlotGroupTable(:,3)); % IsSelected
        SelectedGroupNames = obj.PlotGroupTable(:,4); % IsSelected

        % Get the Group Column from the imported dataset
        GroupColumn = OptimData(:,strcmp(OptimHeader,obj.GroupName));
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
        Time = OptimData(:,strcmp(OptimHeader,'Time'));

        for dIdx = 1:size(obj.PlotDataTable,1)
            origAxIdx = str2double(obj.PlotDataTable{dIdx,1});
            axIdx = origAxIdx;
            if isempty(axIdx) || isnan(axIdx)
                axIdx = 1;
            end
            ThisMarker = obj.PlotDataTable{dIdx,2};
            ThisName = obj.PlotDataTable{dIdx,3};
            ThisDisplayName = obj.PlotDataTable{dIdx,4};            
            
            ColumnIdx = find(strcmp(OptimHeader,ThisName));

            if ~isempty(ColumnIdx) % && ~isempty(axIdx) && ~isnan(axIdx)
                for gIdx = 1:numel(SelectedGroupIDs)

                    if ismember(gIdx,OrigIsSelected)
                        IsVisible = true;
                    else
                        IsVisible = false;
                    end

                    % Find the GroupID match within the GroupColumn
                    MatchIdx = (GroupColumn == SelectedGroupIDs(gIdx));

                    % Create a group
                    if isempty(hDatasetGroup{dIdx,axIdx})
                        % Un-parent if not-selected
                        if isempty(origAxIdx) || isnan(origAxIdx)
                            ThisParent = matlab.graphics.GraphicsPlaceholder.empty();
                        else
                            ThisParent = hAxes(axIdx);
                        end
                        
                        hDatasetGroup{dIdx,axIdx} = hggroup(ThisParent,...
                            'Tag','Data',...
                            'DisplayName',regexprep(ThisDisplayName,'_','\\_'),...
                            'UserData',dIdx);
                        
                        set(get(get(hDatasetGroup{dIdx,axIdx},'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
                        % Add dummy line for legend
                        line(nan,nan,'Parent',hDatasetGroup{dIdx,axIdx},...
                            'LineStyle','none',...
                            'Marker',ThisMarker,...
                            'Tag','DummyLine',...
                            'Color',[0 0 0],...
                            'UserData',dIdx);
                    end

                    % Plot but remove from the legend
                    try
                        hThis = plot(hDatasetGroup{dIdx,axIdx},cell2mat(Time(MatchIdx)),cell2mat(OptimData(MatchIdx,ColumnIdx)),...
                            'Color',SelectedGroupColors(gIdx,:),...
                            'LineStyle','none',...
                            'Marker',ThisMarker,...
                            'MarkerSize',obj.PlotSettings(axIdx).DataSymbolSize,...
                            'UserData',[dIdx,gIdx],...
                            'DisplayName',regexprep(sprintf('%s %s',ThisDisplayName,SelectedGroupNames{gIdx}),'_','\\_')); % For export
                    catch err
                        errordlg(sprintf('Error encountered plotting data. Please check the optimization data item for valid entries.\n\n%s\n', err.message))                        
                    end
                    
                    setIconDisplayStyleOff(hThis);
                    
                    set(hThis,'Visible',uix.utility.tf2onoff(IsVisible));
                end %for gIdx
            end %if
        end %for dIdx
        
    end %if StatusOk
end %if any(MatchIdx)


%% Legend

% Force a drawnow, to avoid legend issues
drawnow

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
