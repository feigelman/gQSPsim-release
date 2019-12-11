function [hLegend,hLegendChildren] = updatePlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,varargin)
% updatePlots - Updates the plot
% -------------------------------------------------------------------------
% Abstract: Updates the plot
%
% Syntax:
%           updatePlots(obj,hAxes)
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


[hLegend,hLegendChildren] = QSP.updateVirtualCohortGenerationPlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,'Mode','VP',varargin{:});
return;


NumAxes = numel(hAxes);
hLegend = cell(1,NumAxes);
hLegendChildren = cell(1,NumAxes);

for axIndex = 1:NumAxes
    
    % Append
    LegendItems = [horzcat(hSpeciesGroup{:,axIndex}) horzcat(hDatasetGroup{:,axIndex})];
    
    if ~isempty(LegendItems) && all(isvalid(LegendItems))
        try
            % Add legend
            [hLegend{axIndex},hLegendChildren{axIndex}] = legend(hAxes(axIndex),LegendItems);
            set(hLegend{axIndex},...
                'EdgeColor','none',...
                'Visible',obj.PlotSettings(axIndex).LegendVisibility,...
                'Location',obj.PlotSettings(axIndex).LegendLocation,...
                'FontSize',obj.PlotSettings(axIndex).LegendFontSize,...
                'FontWeight',obj.PlotSettings(axIndex).LegendFontWeight);
            
            % Color, FontSize, FontWeight
            for cIndex = 1:numel(hLegendChildren{axIndex})
                if isprop(hLegendChildren{axIndex}(cIndex),'FontSize')
                    hLegendChildren{axIndex}(cIndex).FontSize = obj.PlotSettings(axIndex).LegendFontSize;
                end
                if isprop(hLegendChildren{axIndex}(cIndex),'FontWeight')
                    hLegendChildren{axIndex}(cIndex).FontWeight = obj.PlotSettings(axIndex).LegendFontWeight;
                end
            end
        catch ME
            warning('Cannot draw legend')
        end
    else
        hLegend{axIndex} = [];
        hLegendChildren{axIndex} = [];        
    end
end