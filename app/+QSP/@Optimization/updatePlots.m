function [hLegend,hLegendChildren] = updatePlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,varargin)
% updatePlots - Updates the plot
% -------------------------------------------------------------------------
% Abstract: Updates the plot
%
% Syntax:
%           updatePlots(aObj,hAxes)
%
% Inputs:
%           obj - QSP.Optimization object
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
    
    RunIndices = [obj.PlotProfile.Show];
    VisibleRunIndices = find(RunIndices);
    InvisibleRunIndices = find(~RunIndices);
    
    % Get all children
    TheseSpeciesGroups = [hSpeciesGroup{:,axIndex,:}];
    ch = get(TheseSpeciesGroups,'Children');
    if iscell(ch)
        ch = vertcat(ch{:});
    end
    
    % Set SpeciesGroup - DisplayName
    SelectedUserData = get(TheseSpeciesGroups,'UserData'); %sIdx,runIdx
    if iscell(SelectedUserData)
        SelectedUserData = vertcat(SelectedUserData{:});
    end
    TheseItems = TheseSpeciesGroups;
    for thisIdx = 1:numel(TheseItems)
        sIdx = SelectedUserData(thisIdx,1);
        
        FormattedFullDisplayName = regexprep(...
            sprintf('%s [Sim]',obj.PlotSpeciesTable{sIdx,5}),...
            '_','\\_');
        set(TheseItems(thisIdx),'DisplayName',FormattedFullDisplayName);
    end
    
    
    if ~isempty(ch)
        % Set DummyLine - LineStyle for UI
        IsDummyLine = strcmpi(get(ch,'Tag'),'DummyLine');
        TheseDummyLines = ch(IsDummyLine);
        SelectedUserData = get(TheseDummyLines,'UserData'); %sIdx,runIdx
        if iscell(SelectedUserData)
            SelectedUserData = vertcat(SelectedUserData{:});
        end
        for thisIdx = 1:numel(TheseDummyLines)
            sIdx = SelectedUserData(thisIdx,1);
            ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
            set(TheseDummyLines(thisIdx),'LineStyle',ThisLineStyle);
        end
        
        
        % Get all Profiles
        TheseChildren = ch(~IsDummyLine);
        ChildrenUserData = get(TheseChildren,'UserData'); %sIdx,itemIdx,runIdx
        if iscell(ChildrenUserData)
            ChildrenUserData = vertcat(ChildrenUserData{:});
        end
        
        IsItemVisible = ismember(ChildrenUserData(:,2),VisibleItemIndices);
        IsRunVisible = ismember(ChildrenUserData(:,3),VisibleRunIndices);
        
        chVisible = TheseChildren(IsItemVisible & IsRunVisible);
        set(chVisible,'Visible','on')
        
        chInvisible = TheseChildren(~IsItemVisible | ~IsRunVisible);
        set(chInvisible,'Visible','off')
        
        TheseItems = chVisible;
        
        % Process species related content
        if ~isempty(TheseItems)
            
            % Get user data
            SelectedUserData = get(TheseItems,'UserData'); % Just [sIdx,itemIdx]
            if iscell(SelectedUserData)
                SelectedUserData = vertcat(SelectedUserData{:});
            end
            % Remove the last column (runIdx)
            SelectedUserData = SelectedUserData(:,1:2);
            % Find only unique entries (by [sIdx, itemIdx] combinations)
            [~,UniqueIdx] = unique(SelectedUserData,'rows');
            
            for thisIdx = 1:size(SelectedUserData,1)
                
                % Extract sIdx and itemIdx from UserData
                ThisUserData = SelectedUserData(thisIdx,:);
                sIdx = ThisUserData(1);
                itemIdx = ThisUserData(2);
                
                % Now create formatted display name
                ThisDisplayName = obj.PlotSpeciesTable{sIdx,5};
                
                % Get line style
                ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
                thisLineIdx = thisIdx( ~strcmp(class(TheseItems(thisIdx)), 'matlab.graphics.chart.primitive.Scatter'));
                set(TheseItems(thisLineIdx),'LineStyle',ThisLineStyle);
                
                % Only set DisplayName of unique indices
                FullDisplayName = sprintf('%s %s [Sim]',ThisDisplayName,obj.PlotItemTable{itemIdx,5});
                FormattedFullDisplayName = regexprep(FullDisplayName,'_','\\_'); % For export, use patch since line width is not applied
                
                % Set display name for selection only
                if ismember(thisIdx,UniqueIdx)
                    set(TheseItems(thisIdx),'DisplayName',FormattedFullDisplayName)
                else
                    set(TheseItems(thisIdx),'DisplayName','');
                end
                
            end
        end
        
    end
    
    
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
        ThisDisplayName = obj.PlotSpeciesTable{dIdx,5};
        FormattedFullDisplayName = regexprep(sprintf('%s [Data]',ThisDisplayName),'_','\\_'); % For export, use patch since line width is not applied
        set(TheseItems(thisIdx),'DisplayName',FormattedFullDisplayName);
    end
    
    if ~isempty(ch)
        
        % Get Children (other than DummyLine)
        IsDummyLine = strcmpi(get(ch,'Tag'),'DummyLine');
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
                ThisDisplayName = obj.PlotSpeciesTable{dIdx,5};
                FullDisplayName = sprintf('%s %s [Data]',ThisDisplayName,obj.PlotItemTable{itemIdx,5});                
                
                FormattedFullDisplayName = regexprep(FullDisplayName,'_','\\_'); % For export, use patch since line width is not applied
                
                % Set display name for selection only
                set(TheseChildren(thisIdx),'DisplayName',FormattedFullDisplayName);
            end
            
            % Toggle visibility
            % Set visible on
            MatchIdx = ismember(SelectedUserData(:,2),VisibleItemIndices);
            set(TheseChildren(MatchIdx),'Visible','on');
            % Set visible off
            MatchIdx = ismember(SelectedUserData(:,2),InvisibleItemIndices);
            set(TheseChildren(MatchIdx),'Visible','off');
            
        end
    end %if ~isempty(ch)
    
    
    
    % Append
    if size(hSpeciesGroup,3) > 0
        LegendItems = [horzcat(hSpeciesGroup{:,axIndex,1}) horzcat(hDatasetGroup{:,axIndex})];
    else
        LegendItems = [];
    end
    
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