function [hLegend,hLegendChildren] = updatePlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,varargin)
% updatePlots - Updates the plot
% -------------------------------------------------------------------------
% Abstract: Updates the plot
%
% Syntax:
%           updatePlots(aObj,hAxes)
%
% Inputs:
%           obj - QSP.Simulation object
%
%           hAxes
%
%           hSpeciesGroup
%
%           hDatasetGroup
%
% Outputs:
%           hLegend
%
%           hLegendChildren
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

NumAxes = numel(hAxes);
hLegend = cell(1,NumAxes);
hLegendChildren = cell(1,NumAxes);

p = inputParser;
p.KeepUnmatched = false;

% Define defaults and requirements for each parameter
p.addParameter('AxIndices',1:NumAxes); %#ok<*NVREPL>
p.addParameter('RedrawLegend',true);

p.parse(varargin{:});

AxIndices = p.Results.AxIndices;
RedrawLegend = p.Results.RedrawLegend;


for axIndex = AxIndices(:)'
    
    
    %---------------------------------------------------------------------%
    % Process Species Group
    %---------------------------------------------------------------------%
    
    ItemIndices = cell2mat(obj.PlotItemTable(:,1));
    VisibleItemIndices = find(ItemIndices);
    InvisibleItemIndices = find(~ItemIndices);
    
    % Get all children
    TheseSpeciesGroups = [hSpeciesGroup{:,axIndex}];
    TheseSpeciesGroups = TheseSpeciesGroups(arrayfun(@isvalid, TheseSpeciesGroups)); % remove deleted items

    try
        ch = get(TheseSpeciesGroups,'Children');
        if iscell(ch)
            ch = vertcat(ch{:});
        end
    catch err      
        warning(err.message)
        return
    end
    
    % Set SpeciesGroup - DisplayName
    SelectedUserData = get(TheseSpeciesGroups,'UserData'); % Just sIdx
    if iscell(SelectedUserData)
        SelectedUserData = vertcat(SelectedUserData{:});
    end
    TheseItems = TheseSpeciesGroups;
    for thisIdx = 1:numel(TheseItems)
        sIdx = SelectedUserData(thisIdx);
        FormattedFullDisplayName = regexprep(obj.PlotSpeciesTable{sIdx,4},'_','\\_'); % For export, use patch since line width is not applied
        set(TheseItems(thisIdx),'DisplayName',FormattedFullDisplayName);
    end
    
    
    if ~isempty(ch)
        % Set DummyLine - LineStyle for UI
        IsDummyLine = strcmpi(get(ch,'Tag'),'DummyLine');
        TheseDummyLines = ch(IsDummyLine);
        SelectedUserData = get(TheseDummyLines,'UserData'); % Just sIdx
        if iscell(SelectedUserData)
            SelectedUserData = vertcat(SelectedUserData{:});
        end
        for thisIdx = 1:numel(TheseDummyLines)
            sIdx = SelectedUserData(thisIdx);
            ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
            set(TheseDummyLines(thisIdx),'LineStyle',ThisLineStyle);
        end
        
        
        % Get all Traces and Quantiles
        TheseChildren = ch(~IsDummyLine);
        ChildrenUserData = get(TheseChildren,'UserData');
        if iscell(ChildrenUserData)
            ChildrenUserData = vertcat(ChildrenUserData{:});
        end
        
        IsItemVisible = ismember(ChildrenUserData(:,2),VisibleItemIndices);
        
        IsTrace = strcmpi(get(TheseChildren,'Tag'),'TraceLine');
        chTrace = TheseChildren(IsTrace);
        chTraceVisible = TheseChildren(IsTrace & IsItemVisible);
        
        IsMeanLine = strcmpi(get(TheseChildren,'Tag'),'MeanLine');
        chMeanLine = TheseChildren(IsMeanLine);
        chMeanLineVisible = TheseChildren(IsMeanLine & IsItemVisible);
        
        IsMedianLine = strcmpi(get(TheseChildren,'Tag'),'MedianLine');
        chMedianLine = TheseChildren(IsMedianLine);
        chMedianLineVisible = TheseChildren(IsMedianLine & IsItemVisible);
        
        IsBoundaryLine = strcmpi(get(TheseChildren,'Tag'),'BoundaryLine');
        chIsBoundaryLine = TheseChildren(IsBoundaryLine);
        chIsBoundaryLineVisible = TheseChildren(IsBoundaryLine & IsItemVisible);
        
        IsBoundaryPatch = strcmpi(get(TheseChildren,'Tag'),'BoundaryPatch');
        chBoundaryPatch = TheseChildren(IsBoundaryPatch);
        chBoundaryPatchVisible = TheseChildren(IsBoundaryPatch & IsItemVisible);
        
        IsSD = strcmpi(get(TheseChildren,'Tag'),'WeightedSD');
        chSD = TheseChildren(IsSD);
        chSDVisible = TheseChildren(IsSD & IsItemVisible);
        
        % Toggle Visibility for items based on ShowTraces, ShowQuantiles, and
        % Selected/Unselected items
        if obj.bShowTraces(axIndex)
            set(chTraceVisible,'Visible','on')
        else
            set(chTrace,'Visible','off')
        end
        if obj.bShowQuantiles(axIndex)            
            set(chIsBoundaryLineVisible,'Visible','on')
            set(chBoundaryPatchVisible,'Visible','on')
        else
            set(chIsBoundaryLine,'Visible','off')
            set(chBoundaryPatch,'Visible','off')
        end
        if obj.bShowMean(axIndex)
            set(chMeanLineVisible,'Visible','on')
        else
            set(chMeanLine,'Visible','off')
        end
        if obj.bShowMedian(axIndex)
            set(chMedianLineVisible,'Visible','on')
        else
            set(chMedianLine,'Visible','off')
        end
        if obj.bShowSD(axIndex)
            set(chSDVisible,'Visible','on')
        else
            set(chSD,'Visible','off')
        end
        
        MatchIdx = ismember(ChildrenUserData(:,2),InvisibleItemIndices);
        TheseMatches = TheseChildren(MatchIdx);
        set(TheseMatches,'Visible','off')
        
        
        % Update Display Name and LineStyles for Children of SpeciesGroup
        
        % Turn off displayname for all traces and quantiles
        set(chTrace,'DisplayName','');
        set(chMeanLine,'DisplayName','');
        set(chMedianLine,'DisplayName','');
        set(chSD,'DisplayName','');
        
        % Get one type of child - either trace OR quantile
        TheseItems = [];
        if obj.bShowTraces(axIndex) && ~isempty(chTrace)
            % Process trace to only set ONE display name per unique entry
            TheseItems = chTrace;
            
        elseif obj.bShowMean(axIndex) && ~isempty(chMeanLine)
            % Process meanLine to only set ONE display name per unique entry
            TheseItems = chMeanLine;
            
        elseif obj.bShowMedian(axIndex) && ~isempty(chMedianLine)
            % Process meanLine to only set ONE display name per unique entry
            TheseItems = chMedianLine;
            
        elseif obj.bShowSD(axIndex) && ~isempty(chSD)
            % Process meanLine to only set ONE display name per unique entry
            TheseItems = chSD;
        end
        
        % Process species related content
        if ~isempty(TheseItems)
            
            % Get user data
            SelectedUserData = get(TheseItems,'UserData'); % Just [sIdx,itemIdx]
            if iscell(SelectedUserData)
                SelectedUserData = vertcat(SelectedUserData{:});
            end
            % Find only unique entries (by [sIdx, itemIdx] combinations)
            [~,UniqueIdx] = unique(SelectedUserData,'rows');
            
            for thisIdx = UniqueIdx(:)'
                % Extract sIdx and itemIdx from UserData
                ThisUserData = SelectedUserData(thisIdx,:);
                sIdx = ThisUserData(1);
                itemIdx = ThisUserData(2);
                
                % Now create formatted display name
                ThisDisplayName = obj.PlotSpeciesTable{sIdx,4};
                FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotItemTable{itemIdx,6});
                FormattedFullDisplayName = regexprep(FullDisplayName,'_','\\_'); % For export, use patch since line width is not applied
                
                % Get line style
                ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
                % Set display name for selection only
                type = class(TheseItems(thisIdx));
                set(TheseItems(thisIdx),'DisplayName',FormattedFullDisplayName);                
                if ~strcmp(type, 'matlab.graphics.chart.primitive.Scatter')
                    set(TheseItems(thisIdx),'LineStyle',ThisLineStyle);
                end
            end
        end
    end %if ~isempty(ch)
    
    %---------------------------------------------------------------------%
    % Process Data Group
    %---------------------------------------------------------------------%
    
    % Get all children
    TheseDataGroups = [hDatasetGroup{:,axIndex}];
    ch = get(TheseDataGroups,'Children');
    if iscell(ch)
        ch = vertcat(ch{:});
    end
    
    % Set DataGroup - DisplayName
    SelectedUserData = get(TheseDataGroups,'UserData'); % Just dIdx
    if iscell(SelectedUserData)
        SelectedUserData = vertcat(SelectedUserData{:});
    end
    TheseItems = TheseDataGroups;
    for thisIdx = 1:numel(TheseItems)
        dIdx = SelectedUserData(thisIdx);
        FormattedFullDisplayName = regexprep(obj.PlotDataTable{dIdx,4},'_','\\_'); % For export, use patch since line width is not applied
        set(TheseItems(thisIdx),'DisplayName',FormattedFullDisplayName);
    end
    
    if ~isempty(ch)
        
        % Set DummyLine - MarkerStyle
        IsDummyLine = strcmpi(get(ch,'Tag'),'DummyLine');
        TheseDummyLines = ch(IsDummyLine);
        SelectedUserData = get(TheseItems,'UserData'); % Just sIdx
        if iscell(SelectedUserData)
            SelectedUserData = vertcat(SelectedUserData{:});
        end
        for thisIdx = 1:numel(TheseDummyLines)
            dIdx = SelectedUserData(thisIdx);
            ThisMarkerStyle = obj.PlotDataTable{dIdx,2};
            set(TheseDummyLines(thisIdx),'Marker',ThisMarkerStyle);
        end
        
        TheseChildren = ch(~IsDummyLine);
        
        % Process dataset related content
        if ~isempty(TheseChildren)
            
            % Get user data
            SelectedUserData = get(TheseChildren,'UserData'); % Just [sIdx,itemIdx]
            if iscell(SelectedUserData)
                SelectedUserData = vertcat(SelectedUserData{:});
            end
            % Find only unique entries (by [sIdx, itemIdx] combinations)
            [~,UniqueIdx] = unique(SelectedUserData,'rows');
            
            for thisIdx = UniqueIdx(:)'
                % Extract sIdx and itemIdx from UserData
                ThisUserData = SelectedUserData(thisIdx,:);
                dIdx = ThisUserData(1);
                itemIdx = ThisUserData(2);
                
                % Now create formatted display name
                ThisDisplayName = obj.PlotDataTable{dIdx,4};
                FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotGroupTable{itemIdx,4});
                FormattedFullDisplayName = regexprep(FullDisplayName,'_','\\_'); % For export, use patch since line width is not applied
                
                % Get marker style
                ThisMarkerStyle = obj.PlotDataTable{dIdx,2};
                % Set display name for selection only
                set(TheseChildren(thisIdx),'DisplayName',FormattedFullDisplayName,'Marker',ThisMarkerStyle);
            end
            
            % Toggle visibility
            ItemIndices = cell2mat(obj.PlotGroupTable(:,1));
            VisibleItemIndices = find(ItemIndices);
            InvisibleItemIndices = find(~ItemIndices);
            
            % Set visible on
            MatchIdx = ismember(SelectedUserData(:,2),VisibleItemIndices);
            set(TheseChildren(MatchIdx),'Visible','on');
            % Set visible off
            MatchIdx = ismember(SelectedUserData(:,2),InvisibleItemIndices);
            set(TheseChildren(MatchIdx),'Visible','off');
            
        end
    end %if ~isempty(ch)
    
    
    % Append
    LegendItems = [horzcat(hSpeciesGroup{:,axIndex}) horzcat(hDatasetGroup{:,axIndex})];
    
    if RedrawLegend
        
        % Filter based on what is plotted (non-empty parent) and what is
        % valid
        if ~isempty(LegendItems)
            HasParent = ~cellfun(@isempty,{LegendItems.Parent});
            IsValid = isvalid(LegendItems);
            LegendItems = LegendItems(HasParent & IsValid);
        else
            LegendItems = [];
        end
        
       [hLegend{axIndex},hLegendChildren{axIndex}] = uix.abstract.CardViewPane.redrawLegend(hAxes(axIndex),LegendItems,obj.PlotSettings(axIndex));
       
    end %if RedrawLegend
end %for axIndex
