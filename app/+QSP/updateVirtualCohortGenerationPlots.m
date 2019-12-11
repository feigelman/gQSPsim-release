function [hLegend,hLegendChildren] = updateVirtualCohortGenerationPlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,varargin)
% updateVirtualCohortGenerationPlots - Redraws the plots
% -------------------------------------------------------------------------
% Abstract: Redraws the plots
%
% Syntax:
%           updateVirtualCohortGenerationPlots(aObj,hAxes)
%
% Inputs:
%           obj - QSP.VirtualPopulationGeneration or QSP.CohortGeneration object
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
p.addParameter('Mode','Cohort',@(x)any(ismember(x,{'Cohort','VP'})));
p.addParameter('AxIndices',1:NumAxes); %#ok<*NVREPL>
p.addParameter('RedrawLegend',true);

p.parse(varargin{:});

Mode = p.Results.Mode;
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
    TheseSimItems = TheseSpeciesGroups;
    for thisIdx = 1:numel(TheseSimItems)
        sIdx = SelectedUserData(thisIdx);
        ThisDisplayName = obj.PlotSpeciesTable{sIdx,5};
        
        FormattedFullDisplayName = regexprep(sprintf('%s [Sim]',ThisDisplayName),'_','\\_'); % For export, use patch since line width is not applied
        set(TheseSimItems(thisIdx),'DisplayName',FormattedFullDisplayName);                
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
        
        if strcmpi(Mode,'Cohort')
            IsInvalidVP = strcmpi(get(TheseChildren,'Tag'),'InvalidVP');
            chInvalidVP = TheseChildren(IsInvalidVP);
            chInvalidVPVisible = TheseChildren(IsInvalidVP & IsItemVisible);
        end
        
        IsTrace = strcmpi(get(TheseChildren,'Tag'),'TraceLine');
        chTrace = TheseChildren(IsTrace);
        chTraceVisible = TheseChildren(IsTrace & IsItemVisible);
        
%         IsWeightedMeanLine = strcmpi(get(TheseChildren,'Tag'),'WeightedMeanLine');
%         chWeightedMeanLine = TheseChildren(IsWeightedMeanLine);
%         chWeightedMeanLineVisible = TheseChildren(IsWeightedMeanLine & IsItemVisible);
        
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
        
        IsErrorbar = strcmpi(get(TheseChildren,'Tag'),'Errorbar');
        chErrorbar = TheseChildren(IsErrorbar);
        chErrorbarVisible = TheseChildren(IsErrorbar & IsItemVisible);
        
        IsSD = strcmpi(get(TheseChildren,'Tag'),'WeightedSD');
        chSD = TheseChildren(IsSD);
        chSDVisible = TheseChildren(IsSD & IsItemVisible);
        
        % Toggle Visibility for items based on ShowInvalidVirtualPatients, ShowTraces, ShowQuantiles, and
        % Selected/Unselected items
        if strcmpi(Mode,'Cohort')
            if obj.ShowInvalidVirtualPatients
                set(chInvalidVPVisible,'Visible','on')
            else
                set(chInvalidVP,'Visible','off')
            end
        end
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
%             set(chWeightedMeanLineVisible,'Visible','on')            
        else
            set(chMeanLine,'Visible','off')
%             set(chWeightedMeanLine,'Visible','off')
        end
        if obj.bShowMedian(axIndex)
            set(chMedianLineVisible,'Visible','on')
        else
            set(chMedianLine,'Visible','off')
        end
        if obj.bShowSD(axIndex) % Previously, if isa(obj, 'QSP.VirtualPopulationGeneration') 
            set(chSDVisible,'Visible','on')
        else
            set(chSD,'Visible','off')
        end
        set(chErrorbarVisible,'Visible','on')
        
        MatchIdx = ismember(ChildrenUserData(:,2),InvisibleItemIndices);
        TheseMatches = TheseChildren(MatchIdx);
        set(TheseMatches,'Visible','off')
        
        
        % Update Display Name and LineStyles for Children of SpeciesGroup
        
        % Turn off displayname for all children (including traces and
        % quantiles)
        set(TheseChildren,'DisplayName','');
        
        % Get one type of child - either trace OR quantile
        TheseSimItems = [];
        
        if obj.bShowTraces(axIndex) && ~isempty(chTrace)
            TheseSimItems = [TheseSimItems; chTrace(:)]; %#ok<AGROW>
        end
        if obj.bShowMean(axIndex) && ~isempty(chMeanLine)
            TheseSimItems = [TheseSimItems; chMeanLine(:)]; %#ok<AGROW>
        end
        if obj.bShowMedian(axIndex) && ~isempty(chMedianLine)
            TheseSimItems = [TheseSimItems; chMedianLine(:)]; %#ok<AGROW>
        end
        if obj.bShowSD(axIndex) && ~isempty(chSD)
            TheseSimItems = [TheseSimItems; chSD(:)]; %#ok<AGROW>
        end
        
        
%         if obj.bShowTraces(axIndex) && obj.bShowQuantiles(axIndex)
%             % Process trace to only set ONE display name per unique entry
%             if ~isempty(chMeanLine)
%                 TheseSimItems = [TheseSimItems; chMeanLine(:)]; %#ok<AGROW>
%             end
%             if ~isempty(chTrace)
%                 TheseSimItems = [TheseSimItems; chTrace(:)]; %#ok<AGROW>
%             end
%         elseif obj.bShowTraces(axIndex) && ~obj.bShowQuantiles(axIndex)
%             % Process trace to only set ONE display name per unique entry
%             if ~isempty(chWeightedMeanLine)
%                 TheseSimItems = [TheseSimItems; chWeightedMeanLine(:)]; %#ok<AGROW>
%             end
%             if ~isempty(chTrace)
%                 TheseSimItems = [TheseSimItems; chTrace(:)]; %#ok<AGROW>
%             end
%         elseif ~obj.bShowTraces(axIndex) && obj.bShowQuantiles(axIndex) && ~isempty(chMeanLine)
%             % Process quantile to only set ONE display name per unique entry
%             TheseSimItems = chMeanLine;
%         elseif ~obj.bShowTraces(axIndex) && ~obj.bShowQuantiles(axIndex) && ~isempty(chWeightedMeanLine)
%             % Process mean line to only set ONE display name per unique
%             % entry
%             TheseSimItems = chWeightedMeanLine;
%         end
        

        % Append errorbar (necessary for export, if errorbar is the only
        % item plotted)        
        if ~isempty(chErrorbar)
            TheseSimItems = [TheseSimItems(:); chErrorbar(:)];
        end
        
        % Process species related content
        if ~isempty(TheseSimItems)
            
            % Get user data
            SelectedUserData = get(TheseSimItems,'UserData'); % Just [sIdx,itemIdx]
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
                ThisDisplayName = obj.PlotSpeciesTable{sIdx,5};
                FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotItemTable{itemIdx,5});
                FormattedFullDisplayName = regexprep(sprintf('%s [Sim]',FullDisplayName),'_','\\_'); % For export, use patch since line width is not applied
                
                % Get line style
                ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
                % Set display name for selection only
                set(TheseSimItems(thisIdx),'DisplayName',FormattedFullDisplayName);
                % Do not set line style for errorbars
                if ~isa(TheseSimItems(thisIdx),'matlab.graphics.chart.primitive.ErrorBar')
                    MatchIdx = ismember(SelectedUserData(:,1),sIdx);
                    set(TheseSimItems(MatchIdx),'LineStyle',ThisLineStyle);
                    % NOTE: Don't just apply line style to the unique entry                    
                    %                     set(TheseSimItems(thisIdx),'LineStyle',ThisLineStyle);
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
        dIdx = SelectedUserData(thisIdx,1);
        ThisDisplayName = obj.PlotSpeciesTable{dIdx,5};
        FullDisplayName = sprintf('%s [Data]',ThisDisplayName); % For export, use patch since line width is not applied
        set(TheseItems(thisIdx),'DisplayName',FullDisplayName);
    end
    
    if ~isempty(ch)
        
        % Set DummyLine - MarkerStyle
        IsDummyLine = strcmpi(get(ch,'Tag'),'DummyLine');
        
        TheseChildren = ch(~IsDummyLine);
        
        % Process dataset related content
        if ~isempty(TheseChildren)
            
            set(TheseChildren,'DisplayName','');
            
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
                ThisDisplayName = obj.PlotSpeciesTable{dIdx,5};
                FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotItemTable{itemIdx,5});
                FormattedFullDisplayName = regexprep(sprintf('%s [Data]',FullDisplayName),'_','\\_'); % For export, use patch since line width is not applied
                
                % Set display name for selection only
                set(TheseChildren(thisIdx),'DisplayName',FormattedFullDisplayName);
            end
            
            % Toggle visibility
            ItemIndices = cell2mat(obj.PlotItemTable(:,1));
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
    end
end