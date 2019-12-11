function create(vObj)
% create - Creates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function creates all parts of the viewer display
%
% Syntax:
%           create(vObj)
%
% Inputs:
%           vObj - QSPViewer.VirtualPopulation
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
%   $Revision: 322 $  $Date: 2016-09-11 23:01:33 -0400 (Sun, 11 Sep 2016) $
% ---------------------------------------------------------------------

%% Parameters

LabelWidth = 80;
HSpace = 5; %Space between controls
WidgetHeight = 30;


%% Invoke super class's create

create@uix.abstract.CardViewPane(vObj);


%% Edit Content

EditLayout = uix.VBox(...
    'Parent',vObj.h.EditContentsPanel,...
    'Spacing',10);

% File layout
FileHLayout = uix.HBox(...
    'Parent',EditLayout,...
    'Spacing',HSpace);
% Empty
uix.Empty('Parent',EditLayout);
% Sizes
EditLayout.Heights = [WidgetHeight -1];


%%% File Layout
vObj.h.FileLabel = uicontrol(...
    'Parent',FileHLayout,...
    'Style','text',...
    'String','File',...
    'FontSize',10,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

vObj.h.FileSelector = uix.widget.FileSelector(...
    'Parent',FileHLayout,...
    'Value', '', ...
    'Units','pixels',...
    'Pattern', {'*.xlsx;*.xls','Excel File'}, ...
    'Title', 'Parameters XLSX/XLS file:', ...
    'HorizontalAlignment', 'left',...
    'InvalidForegroundColor',[1 0 0],...
    'Callback',@(h,e)onFileSelection(vObj,h,e) );

% Sizes
FileHLayout.Widths = [LabelWidth -1];