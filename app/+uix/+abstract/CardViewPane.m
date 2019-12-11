classdef (Abstract) CardViewPane < uix.abstract.ViewPane
    % CardViewPane - A base class for building view panes
    % ---------------------------------------------------------------------
    % This is an abstract base class and cannot be instantiated. It
    % provides the basic properties needed for a view pane that will
    % contain a group of graphics objects to build a complex view pane.
    %
    
    %   Copyright 2008-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $
    %   $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
    
    properties (AbortSet=true, SetObservable)
        TempData
        Selection = 1
        IsDeleted = false
        SelectedPlotLayout = '1x1'
        PlotSettings = QSP.PlotSettings.empty(0,1)
    end
    
    properties (SetAccess=protected)
       bShowTraces = []
       bShowQuantiles = []
       bShowMean = []
       bShowMedian = []
       bShowSD = []
    end
    
    properties (SetAccess=private)        
        UseRunVis = false
        LastPath = pwd
    end
    
    properties (Access=private, Constant=true)
        NoParent_ = matlab.graphics.GraphicsPlaceholder.empty(0,0)
    end
    
    properties (Constant=true)
        MaxNumPlots = 12
        PlotLayoutOptions = {'1x1','1x2','2x1','2x2','3x2','3x3','3x4'}
    end
    
    events( NotifyAccess = protected )
        TempDataEdited
        NavigationChanged
        MarkDirty
    end
    
    %% Constructor and Destructor
    methods
        function obj = CardViewPane( UseRunVis, varargin )
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj = obj@uix.abstract.ViewPane( varargin{:} );
            
            % Assign PV pairs to properties
            obj.assignPVPairs(varargin{:});
            
            % Set UseRunVis before calling create
            obj.UseRunVis = UseRunVis;
            
        end
    end
    
    methods (Access=protected)
        function create(obj)
            
            WidgetSize = 30;
            LabelWidth = 80;
            Pad = 2;
            VSpace = 4;
            HSpace = 6; %Space between controls
            TitleColor = [0.6235    0.7255    0.8314];
            
            hFigure = ancestor(obj.UIContainer,'Figure');
            
            % Turn off border for UIContainer
            set(obj.UIContainer,'BorderType','none');
            
            
            obj.h.MainLayout = uix.VBox(...
                'Parent',obj.UIContainer);
            
            % Buttons
            obj.h.ButtonLayout = uix.HBox(...
                'Parent',obj.h.MainLayout);
            
            % Create card panel
            obj.h.CardPanel = uix.CardPanel(...
                'Parent',obj.h.MainLayout);
            
            % Sizes
            obj.h.MainLayout.Heights = [WidgetSize -1];
            
            %%% Summary
            obj.h.SummaryPanel = uix.BoxPanel(...
                'Parent',obj.h.CardPanel,...
                'Title','Summary',...
                'ForegroundColor',[0 0 0],...
                'TitleColor',TitleColor,...
                'FontSize',10,...
                'Padding',Pad);
            % Add Summary widget
            obj.h.SummaryContent = uix.widget.Summary(...
                'Parent',obj.h.SummaryPanel);
            
            %%% Add/Edit
            obj.h.EditPanel = uix.BoxPanel(...
                'Parent',obj.h.CardPanel,...
                'Title','Edit',...
                'ForegroundColor',[0 0 0],...
                'TitleColor',TitleColor,...
                'FontSize',10,...
                'Padding',5);
            obj.h.EditLayout = uix.VBox(...
                'Parent',obj.h.EditPanel,...
                'Padding',5,...
                'Spacing',12);
            % Row 1: File/Description, Row 2: Contents, Row 3: Buttons
            obj.h.FileSelectRows(1) = uix.HBox(...
                'Parent',obj.h.EditLayout,...
                'Padding',0,...
                'Spacing',5);
            obj.h.EditContentsPanel = uix.Panel(...
                'Parent',obj.h.EditLayout,...
                'BorderType','none');
            obj.h.EditButtonLayout = uix.HBox(...
                'Parent',obj.h.EditLayout);
            obj.h.EditLayout.Heights = [WidgetSize -1 WidgetSize];
            
            %%% Row 1
            obj.h.FileSelect(1) = uicontrol(...
                'Parent',obj.h.FileSelectRows(1),...
                'Style','text',...
                'String','Name',...
                'FontSize',10,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');
            obj.h.FileSelect(2) = uicontrol(...
                'Parent',obj.h.FileSelectRows(1),...
                'Style','edit',...
                'HorizontalAlignment','left',...
                'FontSize',10,...
                'Callback',@(h,e)onEditName(obj,h,e));
            obj.h.FileSelect(3) = uicontrol(...
                'Parent',obj.h.FileSelectRows(1),...
                'Style','text',...
                'String','Description',...
                'FontSize',10,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');
            obj.h.FileSelect(4) = uicontrol(...
                'Parent',obj.h.FileSelectRows(1),...
                'Style','edit',...
                'HorizontalAlignment','left',...
                'FontSize',10,...
                'Callback',@(h,e)onEditDescription(obj,h,e));
            set(obj.h.FileSelectRows(1),'Widths',[LabelWidth -1 LabelWidth -2]);
            
            %%% Row 3
            uix.Empty('Parent',obj.h.EditButtonLayout);
            obj.h.RemoveButton = uicontrol(...
                'Parent',obj.h.EditButtonLayout,...
                'Style','pushbutton',...
                'Tag','RemoveInvalid',...
                'String','Remove Invalid',...
                'TooltipString','Remove Invalid Entries',...
                'FontSize',10,...
                'Callback',@(h,e)onButtonPress(obj,h,e));
            obj.h.SaveButton = uicontrol(...
                'Parent',obj.h.EditButtonLayout,...
                'Style','pushbutton',...
                'Tag','Save',...
                'String','OK',...
                'TooltipString','Apply and Save Changes to Selection',...
                'FontSize',10,...
                'Callback',@(h,e)onButtonPress(obj,h,e));
            obj.h.CancelButton = uicontrol(...
                'Parent',obj.h.EditButtonLayout,...
                'Style','pushbutton',...
                'Tag','Cancel',...
                'String','Cancel',...
                'TooltipString','Close without Saving',...
                'FontSize',10,...
                'Callback',@(h,e)onButtonPress(obj,h,e));
            obj.h.EditButtonLayout.Widths = [-1 125 75 75];
            
            %%% Visualize
            if obj.UseRunVis
                obj.h.VisualizePanel = uix.BoxPanel(...
                    'Parent',obj.h.CardPanel,...
                    'Title','Visualize',...
                    'ForegroundColor',[0 0 0],...
                    'TitleColor',TitleColor,...
                    'FontSize',10,...
                    'Padding',Pad);
                obj.h.VisualizeLayout = uix.HBoxFlex(...
                    'Parent',obj.h.VisualizePanel,...
                    'Spacing',10);
                % LHS: Grid
                obj.h.PlotGrid = uix.Grid(...
                    'Parent',obj.h.VisualizeLayout,...
                    'Padding',5);
                for index = 1:obj.MaxNumPlots
                    % Add container and axes
                    obj.h.MainAxesContainer(index) = uicontainer(...
                        'Parent',obj.h.PlotGrid);
                    obj.h.MainAxes(index) = axes(...
                        'Parent',obj.h.MainAxesContainer(index),...
                        'Visible','off');
                    
                    % Initialize Plot ID and also FontSizeMode to auto
                    % This an issue with FontSizes values changing
                    % (i.e. 11 to 8.8) for small axes (off screen), even
                    % when FontUnits is points
                    set(obj.h.MainAxes(index),'FontSizeMode','manual')
                    
                    title(obj.h.MainAxes(index),sprintf('Plot %d',index));
                    xlabel(obj.h.MainAxes(index),QSP.PlotSettings.DefaultXLabel);
                    ylabel(obj.h.MainAxes(index),QSP.PlotSettings.DefaultYLabel);
                    set(get(obj.h.MainAxes(index),'Title'),'FontSize',QSP.PlotSettings.DefaultTitleFontSize,'FontWeight',QSP.PlotSettings.DefaultTitleFontWeight)
                    % First set ruler, then set label
                    hThis = get(obj.h.MainAxes(index),'XRuler');
                    set(hThis,'FontSize',QSP.PlotSettings.DefaultXTickLabelFontSize,'FontWeight',QSP.PlotSettings.DefaultXTickLabelFontWeight);
                    hThis = get(obj.h.MainAxes(index),'YRuler');
                    set(hThis,'FontSize',QSP.PlotSettings.DefaultYTickLabelFontSize,'FontWeight',QSP.PlotSettings.DefaultYTickLabelFontWeight);
                    set(get(obj.h.MainAxes(index),'xlabel'),'FontSize',QSP.PlotSettings.DefaultXLabelFontSize,'FontWeight',QSP.PlotSettings.DefaultXLabelFontWeight)
                    set(get(obj.h.MainAxes(index),'ylabel'),'FontSize',QSP.PlotSettings.DefaultYLabelFontSize,'FontWeight',QSP.PlotSettings.DefaultYLabelFontWeight)
                    
                    set(obj.h.MainAxes(index),...
                        'XGrid',QSP.PlotSettings.DefaultXGrid,...
                        'YGrid',QSP.PlotSettings.DefaultYGrid,...
                        'XMinorGrid',QSP.PlotSettings.DefaultXMinorGrid,...
                        'YMinorGrid',QSP.PlotSettings.DefaultYMinorGrid,...
                        'YScale',QSP.PlotSettings.DefaultYScale,...
                        'XLim',str2num(QSP.PlotSettings.DefaultCustomXLim),...
                        'XLimMode',QSP.PlotSettings.DefaultXLimMode,...
                        'YLim',str2num(QSP.PlotSettings.DefaultCustomYLim),...
                        'YLimMode',QSP.PlotSettings.DefaultYLimMode); %#ok<ST2NM>
                    
                    % Assign plot settings
                    obj.PlotSettings(index) = QSP.PlotSettings(obj.h.MainAxes(index));
                    obj.PlotSettings(index).Title = sprintf('Plot %d',index);
                    
                    % Add contextmenu
                    obj.h.ContextMenu(index) = uicontextmenu('Parent',hFigure);
                    obj.h.ContextMenuYScale(index) = uimenu(obj.h.ContextMenu(index),...
                        'Label','Y-Scale',...
                        'Tag','YScale');
                    uimenu(obj.h.ContextMenuYScale(index),...
                        'Label','Linear',...
                        'Tag','YScaleLinear',...
                        'Checked','on',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    uimenu(obj.h.ContextMenuYScale(index),...
                        'Label','Log',...
                        'Tag','YScaleLog',...
                        'Checked','off',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    uimenu(obj.h.ContextMenu(index),...
                        'Label','Save Current Axes...',...
                        'Tag','ExportSingleAxes',...
                        'Separator','on',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    uimenu(obj.h.ContextMenu(index),...
                        'Label','Save Full View...',...
                        'Tag','ExportAllAxes',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));                    
                    
                    if strcmpi(class(obj),'QSPViewer.VirtualPopulationGeneration')
                        obj.bShowTraces(index) = false; % default off
                        obj.bShowQuantiles(index) = true; % default on
                        obj.bShowMean(index) = true; % default on
                        obj.bShowMedian(index) = false; % default off
                        obj.bShowSD(index) = false; % default off
                    else
                        obj.bShowTraces(index) = false; % default off
                        obj.bShowQuantiles(index) = true; % default on
                        obj.bShowMean(index) = false; % default off
                        obj.bShowMedian(index) = true; % default on
                        obj.bShowSD(index) = false; % default off
                    end
                    
                    % Show traces/quantiles/mean/median/SD
                    obj.h.ContextMenuTraces(index) = uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Traces',...
                        'Checked',uix.utility.tf2onoff(obj.bShowTraces(index)),...
                        'Separator','on',...
                        'Tag','ShowTraces',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                     obj.h.ContextMenuQuantiles(index) = uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Upper/Lower Quantiles',...
                        'Checked',uix.utility.tf2onoff(obj.bShowQuantiles(index)),...
                        'Tag','ShowQuantiles',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    obj.h.ContextMenuMean(index) = uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Mean (Weighted)',...
                        'Checked',uix.utility.tf2onoff(obj.bShowMean(index)),...
                        'Tag','ShowMean',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    obj.h.ContextMenuMedian(index) =uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Median (Weighted)',...
                        'Checked',uix.utility.tf2onoff(obj.bShowMedian(index)),...
                        'Tag','ShowMedian',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    obj.h.ContextMenuSD(index) =uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Standard Deviation (Weighted)',...
                        'Checked',uix.utility.tf2onoff(obj.bShowSD(index)),...
                        'Tag','ShowSD',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    
                    set(obj.h.MainAxes(index),'UIContextMenu',obj.h.ContextMenu(index));

                end
                set(obj.h.MainAxes(1),'Visible','on');
                
                % RHS: Settings
                obj.h.PlotSettingsLayout = uix.VBox(...
                    'Parent',obj.h.VisualizeLayout,...
                    'Padding',5,...
                    'Spacing',10);
               obj.h.VisualizeLayout.Widths = [-2 -1];
                
                % RHS: Settings Panel
                obj.h.PlotConfigPopup = uix.widget.PopupFieldWithLabel(...
                    'Parent',obj.h.PlotSettingsLayout,...
                    'Tag','PlotConfigPopup',...
                    'String',{' '},...
                    'LabelString','Plot Layout',...
                    'LabelFontSize',10,...
                    'LabelFontWeight','bold',...
                    'Callback',@(h,e)onPlotConfigChange(obj,h,e));
                obj.h.PlotSettingsPanel = uix.Panel(...
                    'Parent',obj.h.PlotSettingsLayout,...
                    'BorderType','none');
                obj.h.RemoveInvalidVisualizationButtonLayout = uix.HButtonBox(...
                    'Parent',obj.h.PlotSettingsLayout);
                obj.h.RemoveInvalidVisualizationButton = uicontrol(...
                    'Parent',obj.h.RemoveInvalidVisualizationButtonLayout,...
                    'Style','pushbutton',...
                    'Tag','RemoveInvalid',...
                    'String','Remove Invalid',...
                    'TooltipString','Remove Invalid Entries',...
                    'FontSize',10,...
                    'Callback',@(h,e)onRemoveInvalidVisualization(obj,h,e));
                obj.h.RemoveInvalidVisualizationButtonLayout.ButtonSize = [125 WidgetSize];
                    
                obj.h.PlotSettingsLayout.Heights = [WidgetSize -1 WidgetSize];
            end
            
            % Update selection
            obj.h.CardPanel.Selection = obj.Selection;
            
            %%% Buttons
            obj.h.SummaryButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'report_24.png' ), ...
                'TooltipString', 'View summary',...
                'Callback', @(h,e)onNavigation(obj,'Summary') );
            obj.h.EditButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'edit_24.png' ), ...
                'TooltipString', 'Edit the selected item',...
                'Callback', @(h,e)onNavigation(obj,'Edit') );
            obj.h.RunButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'play_24.png' ), ...
                'TooltipString', 'Run the selected item',...
                'Callback', @(h,e)onNavigation(obj,'Run') );
            uix.Empty('Parent',obj.h.ButtonLayout);
            obj.h.VisualizeButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'visualize_24.png' ), ...
                'TooltipString', 'Visualize the selected item',...
                'Callback', @(h,e)onNavigation(obj,'Visualize') );
            obj.h.PlotSettingsButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'settings_24.png' ), ...
                'TooltipString', 'Customize plot settings for the selected item',...
                'Callback', @(h,e)onNavigation(obj,'CustomizeSettings') );
            CData = load('zoom.mat');
            CData = CData.zoomCData;
            obj.h.ZoomInButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'togglebutton', ...
                'CData', CData, ...
                'TooltipString', 'Zoom In',...
                'Callback', @(h,e)onNavigation(obj,'ZoomIn') );
            CData = load('zoomminus.mat');
            CData = CData.cdata;
            obj.h.ZoomOutButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'togglebutton', ...
                'CData', CData, ...
                'TooltipString', 'Zoom Out',...
                'Callback', @(h,e)onNavigation(obj,'ZoomOut') );
            CData = load('pan.mat');
            CData = CData.cdata;
            obj.h.PanButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'togglebutton', ...
                'CData', CData, ...
                'TooltipString', 'Pan',...
                'Callback', @(h,e)onNavigation(obj,'Pan') );
            CData = load('datatip.mat');
            CData = CData.cdata;
            obj.h.DatacursorButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'togglebutton', ...
                'CData', CData, ...
                'TooltipString', 'Explore',...
                'Callback', @(h,e)onNavigation(obj,'Datacursor') );
            uix.Empty('Parent',obj.h.ButtonLayout);
            
            obj.h.ButtonLayout.Widths = [WidgetSize WidgetSize WidgetSize WidgetSize WidgetSize WidgetSize WidgetSize WidgetSize WidgetSize WidgetSize -1];
            
        end %function
        
    end
    
    methods
        
        function onEditName(obj,h,e) %#ok<*INUSD>
            % Update the name
            if ~isempty(obj.TempData)
                obj.TempData.Name = get(h,'String');
            end
            
            % Update the view
            updateNameDescription(obj);
            
        end %function
        
        function onEditDescription(obj,h,e)
            
            % Update the description
            if ~isempty(obj.TempData)
                obj.TempData.Description = get(h,'String');
            end
            
            % Update the view
            updateNameDescription(obj);
            
        end %function
        
        function onButtonPress(obj,h,e)
            
            ThisTag = get(h,'Tag');
            
            hFigure = ancestor(obj.h.MainLayout,'figure');
            set(hFigure,'pointer','watch');
            drawnow;
            
            switch ThisTag
                case 'RemoveInvalid'
                    
                    FlagRemoveInvalid = true;
                    % Remove the invalid entries
                    validate(obj.TempData,FlagRemoveInvalid);
                   
                case 'Save'
                    
                    FlagRemoveInvalid = false;
                    [StatusOK,Message] = validate(obj.TempData,FlagRemoveInvalid);
                    
                    [StatusOK,Message] = checkDuplicateNames(obj,StatusOK,Message);
                    
                    if StatusOK
                        % Copy from TempData into Data, using obj.Data as a
                        % starting point
                        
                        % Update time
                        updateLastSavedTime(obj.TempData);
                        PreviousName = obj.Data.Name;
                        NewName = obj.TempData.Name;
                        obj.Data = copy(obj.TempData,obj.Data); % This triggers a refresh                        
                        
                        obj.Selection = 1;
                        set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','on');
                        % Notify
                        View = 'Summary';
                        EventData = uix.abstract.NavigationEventData('Name',View);
                        notify(obj,'NavigationChanged',EventData);
                   
                        % Call the callback
                        evt.InteractionType = sprintf('Updated %s',class(obj.Data));
                        evt.Name = obj.Data.Name;
                        evt.NameChanged = ~isequal(NewName,PreviousName);
                        obj.callCallback(evt);
                        
                        % Mark Dirty
                        notify(obj,'MarkDirty');
                    else
                        hDlg = errordlg(sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save','modal');
                        uiwait(hDlg);
                    end
                   
                case 'Cancel'
                    if ~isPublicPropsEqual(obj.Data,obj.TempData)
                        Prompt = sprintf('Changes have not been saved. How would you like to continue?');
                        Result = questdlg(Prompt,'Continue?','Save','Don''t Save','Cancel','Cancel');
                        if strcmpi(Result,'Save')
                            
                            FlagRemoveInvalid = false;
                            [StatusOK,Message] = validate(obj.TempData,FlagRemoveInvalid);
                            
                            [StatusOK,Message] = checkDuplicateNames(obj,StatusOK,Message);
                            
                                                        
                            if StatusOK
                                obj.Selection = 1;
                                set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','on');
                                % Copy from TempData into Data, using obj.Data as a
                                % starting point
                                % Update time
                                updateLastSavedTime(obj.TempData);
                                PreviousName = obj.Data.Name;
                                NewName = obj.TempData.Name;
                                obj.Data = copy(obj.TempData,obj.Data); % This triggers a refresh
                        
                                % Call the callback
                                evt.InteractionType = sprintf('Updated %s',class(obj.Data));
                                evt.Name = obj.Data.Name;
                                evt.NameChanged = ~isequal(NewName,PreviousName);
                                obj.callCallback(evt);
                                
                                % Notify
                                View = 'Summary';
                                EventData = uix.abstract.NavigationEventData('Name',View);
                                notify(obj,'NavigationChanged',EventData);
                                
                                % Mark Dirty
                                notify(obj,'MarkDirty');
                            else
                                hDlg = errordlg(sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save','modal');
                                uiwait(hDlg);
                            end
                            
                        elseif strcmpi(Result,'Don''t Save')
                            obj.Selection = 1;
                            set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','on');
                            % Copy from Data into TempData, using obj.TempData as a
                            % starting point
                            obj.TempData = copy(obj.Data,obj.TempData);                            
                            % Notify
                            View = 'Summary';
                            EventData = uix.abstract.NavigationEventData('Name',View);
                            notify(obj,'NavigationChanged',EventData);
                        end %Else, do nothing
                    else
                        obj.Selection = 1;
                        set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','on');
                        % Copy from Data into TempData, using obj.TempData as a
                        % starting point
                        obj.TempData = copy(obj.Data,obj.TempData);
                        % Notify
                        View = 'Summary';
                        EventData = uix.abstract.NavigationEventData('Name',View);
                        notify(obj,'NavigationChanged',EventData);
                    end
            end
            
            % Update the view
            update(obj);
            
            set(hFigure,'pointer','arrow');
            drawnow;
            
        end %function
        
        function turnOffZoomPanDatacursor(obj)
            hFigure = ancestor(obj.h.MainLayout,'figure');
            obj.h.ZoomInButton.Value = false;
            obj.h.ZoomOutButton.Value = false;
            obj.h.PanButton.Value = false;
            obj.h.DatacursorButton.Value = false;
            zoom(hFigure,'off');
            pan(hFigure,'off');
            datacursormode(hFigure,'off');
        end %function
        
        function [StatusOK, Message] = checkDuplicateNames(obj, StatusOK, Message)
            % check for duplicate name
            ref_obj = [];
            switch class(obj)
                case 'QSPViewer.Session'
                    ref_obj = obj.Data; %obj.Data.Session;
                case 'QSPViewer.OptimizationData'
                    ref_obj = obj.Data.Session.Settings.OptimizationData;
                case 'QSPViewer.Parameters'
                    ref_obj = obj.Data.Session.Settings.Parameters;                    
                case 'QSPViewer.Task'
                    ref_obj = obj.Data.Session.Settings.Task;
                case 'QSPViewer.VirtualPopulationData'
                    ref_obj = obj.Data.Session.Settings.VirtualPopulationData;
                case 'QSPViewer.VirtualPopulation'
                    ref_obj = obj.Data.Session.Settings.VirtualPopulation;
                case 'QSPViewer.Simulation'
                    ref_obj = obj.Data.Session.Simulation;
                case 'QSPViewer.Optimization'
                    ref_obj = obj.Data.Session.Optimization;
                case 'QSPViewer.CohortGeneration'
                    ref_obj = obj.Data.Session.CohortGeneration;                    
                case 'QSPViewer.VirtualPopulationGeneration'
                    ref_obj = obj.Data.Session.VirtualPopulationGeneration;
                case 'QSPViewer.VirtualPopulationGenerationData'
                    ref_obj = obj.Data.Session.Settings.VirtualPopulationGenerationData;
            end
            
            ixDup = find(strcmp( obj.TempData.Name, {ref_obj.Name}));
            if ~isempty(ixDup) && (ref_obj(ixDup) ~= obj.Data)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
        function onRemoveInvalidVisualization(obj,h,e)
            
            if ~obj.UseRunVis
                return;
            end
            
            ThisTag = get(h,'Tag');
            
            switch ThisTag
                case 'RemoveInvalid'
                    
                    removeInvalidVisualization(obj);
                    
            end
        end %function
        
        function onNavigation(obj,View)
            
            switch View
                case 'Summary'
                    if obj.Selection == 2 && ~isPublicPropsEqual(obj.Data,obj.TempData)
                        Prompt = sprintf('Do you want to continue without saving changes?');
                        Result = questdlg(Prompt,'Continue','Yes','Cancel','Yes');
                        if strcmpi(Result,'Yes')
                            obj.Selection = 1;
                            % Copy from Data into TempData, using obj.TempData as a
                            % starting point
                            obj.TempData = copy(obj.Data,obj.TempData);                            
                        end
                    else
                        obj.Selection = 1;
                        set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','on');                        
                    end
                    
                    % Update the view
                    update(obj);
                    
                    % Notify
                    EventData = uix.abstract.NavigationEventData('Name',View);
                    notify(obj,'NavigationChanged',EventData);
                    
                case 'Edit'
                    
                    % Copy from Data into TempData, using obj.TempData as a
                    % starting point (Visualization view edits obj.Data and
                    % TempData may be out of date)
                    obj.TempData = copy(obj.Data,obj.TempData);
                    
                    % Validate when switching to 'Edit'
%                     [StatusOK, Message] = validate(obj.TempData,false); %
%                     TODO: Do we need to validate here? Don't think it is
%                     needed here. Only on save. UpdateEditView will take
%                     care of updating the editing panel
            
                    obj.Selection = 2;
                    set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton,obj.h.ZoomInButton,obj.h.ZoomOutButton,obj.h.PanButton,obj.h.DatacursorButton],'Enable','off');
                    
                    % Update the view
                    update(obj);
                    
                    % Resize
                    resize(obj);
                    
                    % Notify
                    EventData = uix.abstract.NavigationEventData('Name',View);
                    notify(obj,'NavigationChanged',EventData);
                    
                case 'Run'
                    % Run
                    
                    hFigure = ancestor(obj.UIContainer,'Figure');
                    set(hFigure,'pointer','watch');
                    drawnow;
                    
                    set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','on');                    
                    
                    [StatusOK,Message,vpopObj] = run(obj.Data);
                    if ~StatusOK
                        hDlg = errordlg(Message,'Run Failed','modal');
                        uiwait(hDlg);
                    elseif ~isempty(vpopObj)
                        % Call the callback
                        evt.InteractionType = sprintf('Updated %s',class(vpopObj));
                        evt.Data = vpopObj;
                        hWbar = uix.utility.CustomWaitbar(0,'Updating','Updating tree items',false);
                        obj.callCallback(evt);
                        delete(hWbar)
                    end
                        
                    if StatusOK
                        % Mark Dirty
                        notify(obj,'MarkDirty');
                    end
                    
                    set(hFigure,'pointer','arrow');
                    drawnow;
                    
                    % Switch to summary view
                    obj.Selection = 1;
                    
                    % Update the view
                    update(obj);
                    
                    % Notify
                    EventData = uix.abstract.NavigationEventData('Name',View);
                    notify(obj,'NavigationChanged',EventData);
                    
                case 'Visualize'
                    % Visualize
                    if obj.Selection == 2
                        Prompt = sprintf('Do you want to continue without saving changes?');
                        Result = questdlg(Prompt,'Continue','Yes','Cancel','Yes');
                        if strcmpi(Result,'Yes')
                            obj.Selection = 3;
                            set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','on');
                            updateVisualizationView(obj);
                            resize(obj);
                        end
                    else
                        obj.Selection = 3;
                        set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','on');
                        updateVisualizationView(obj);
                        resize(obj);
                    end
                    
                    % Update the view
                    update(obj);
                    
                    % Notify
                    EventData = uix.abstract.NavigationEventData('Name',View);
                    notify(obj,'NavigationChanged',EventData);
                    
                case 'CustomizeSettings'

                    bandPlotLB = [obj.PlotSettings.BandplotLowerQuantile];
                    bandPlotUB = [obj.PlotSettings.BandplotUpperQuantile];
                    
                    [StatusOk,NewSettings] = CustomizePlots(...
                        'Settings',obj.PlotSettings);                    
                    if StatusOk
                        replot = false;
                        if any([NewSettings.BandplotLowerQuantile] ~= bandPlotLB | ...
                            [NewSettings.BandplotUpperQuantile] ~= bandPlotUB)
                                replot = true;
                        end
                        
                        obj.PlotSettings = NewSettings;
                        % Update the view
                        update(obj);     

                        if replot
                            obj.plotData();
                        end
                       
                        % Mark Dirty
                        notify(obj,'MarkDirty');
                    end
                    
                case 'ZoomIn'
                    
                    hFigure = ancestor(obj.UIContainer,'Figure');
                    ThisValue = get(obj.h.ZoomInButton,'Value');
                    zoomObj = zoom(hFigure);
                    set(zoomObj,'Enable',uix.utility.tf2onoff(ThisValue),'Direction','in');
                    pan(hFigure,'off');
                    datacursorObj = datacursormode(hFigure);
                    datacursorObj.Enable = 'off';
                    
                    % Update toggle buttons
                    updateToggleButtons(obj);
                    
                case 'ZoomOut'
                    
                    hFigure = ancestor(obj.UIContainer,'Figure');
                    ThisValue = get(obj.h.ZoomOutButton,'Value');
                    zoomObj = zoom(hFigure);
                    set(zoomObj,'Enable',uix.utility.tf2onoff(ThisValue),'Direction','out');
                    set(zoomObj,'Direction','out');
                    pan(hFigure,'off');
                    datacursorObj = datacursormode(hFigure);
                    datacursorObj.Enable = 'off';
                    
                    % Update toggle buttons
                    updateToggleButtons(obj);
                    
                case 'Pan'
                    
                    hFigure = ancestor(obj.UIContainer,'Figure');
                    ThisValue = get(obj.h.PanButton,'Value');
                    pan(hFigure,uix.utility.tf2onoff(ThisValue));
                    zoom(hFigure,'off');
                    datacursorObj = datacursormode(hFigure);
                    datacursorObj.Enable = 'off';
                    
                    % Update toggle buttons
                    updateToggleButtons(obj);
                    
                case 'Datacursor'
                    
                    hFigure = ancestor(obj.UIContainer,'Figure');
                    ThisValue = get(obj.h.DatacursorButton,'Value');
                    datacursorObj = datacursormode(hFigure);
                    datacursorObj.Enable = uix.utility.tf2onoff(ThisValue);
                    zoom(hFigure,'off');
                    pan(hFigure,'off');
                    
                    % Update toggle buttons
                    updateToggleButtons(obj);
            end
            
        end %function
        
        function onPlotConfigChange(obj,h,e)
            
            hFigure = ancestor(obj.UIContainer,'Figure');
            set(hFigure,'pointer','watch');
            % drawnow; %Remove drawnow - maybe causing axes sizing issues
            
            Value = get(h,'Value');
            obj.SelectedPlotLayout = obj.PlotLayoutOptions{Value};
            
            % Update the view
            updateVisualizationView(obj);
            update(obj);
            
            notify(obj,'MarkDirty');
            set(hFigure,'pointer','arrow');
            % drawnow; %Remove drawnow - maybe causing axes sizing issues
        end
        
        function onAxesContextMenu(obj,h,~,axIndex)
            
            ThisTag = get(h,'Tag');
            
            switch ThisTag
                case 'YScaleLinear'
                    % Manage context menu states here for ease
                    set(get(get(h,'Parent'),'Children'),'Checked','off');
                    set(h,'Checked','on')
                    set(obj.h.MainAxes(axIndex),'YScale','linear');
                case 'YScaleLog'
                    % Manage context menu states here for ease
                    set(get(get(h,'Parent'),'Children'),'Checked','off');
                    set(h,'Checked','on')
                    set(obj.h.MainAxes(axIndex),'YScale','log');                    
                case 'ExportSingleAxes'
                    % Prompt the user for a filename
                    Spec = {...
                        '*.png','PNG';
                        '*.tif;*.tiff','TIFF';...
                        '*.eps','EPS';...
                        '*.fig','MATLAB Figure';...
                        };
                    Title = 'Save as';
                    SaveFilePath = pwd; % obj.LastPath;
                    [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
                    if ~isequal(SaveFileName,0)
                        
                        hFigure = ancestor(obj.h.MainLayout,'figure');
                        set(hFigure,'pointer','watch');
                        drawnow;
                        
                        SaveFilePath = fullfile(SavePathName,SaveFileName);
                        ThisAxes = get(obj.h.MainAxesContainer(axIndex),'Children');
                        
                        % Call helper to copy axes, format, and print
                        printAxesHelper(obj,ThisAxes,SaveFilePath,obj.PlotSettings(axIndex))                        
                        
                        set(hFigure,'pointer','arrow');
                        drawnow;
                        
                    end %if
                    
                case 'ExportAllAxes'
                    % Prompt the user for a filename
                    Spec = {...
                        '*.png','PNG';
                        '*.tif;*.tiff','TIFF';...
                        '*.eps','EPS';...
                        '*.fig','MATLAB Figure'...
                        };
                    Title = 'Save as';
                    SaveFilePath = pwd; %obj.LastPath;
                    [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
                    if ~isequal(SaveFileName,0)
                        
                        hFigure = ancestor(obj.h.MainLayout,'figure');
                        set(hFigure,'pointer','watch');
                        drawnow;
                        
                        % Print using option
                        [~,~,FileExt] = fileparts(SaveFileName);
                        
                        % Get children and remove not-shown axes
                        Ch = flip(get(obj.h.PlotGrid,'Children'));
                        
                        switch obj.SelectedPlotLayout
                            case '1x1'
                                Ch = Ch(1);
                            case '1x2'     
                                Ch = Ch(1:2);
                            case '2x1'     
                                Ch = Ch(1:2);
                            case '2x2'
                                Ch = Ch(1:4);
                            case '3x2'
                                Ch = Ch(1:6);
                            case '3x3'
                                Ch = Ch(1:9);
                            case '3x4'
                                Ch = Ch(1:12);
                        end
                        
                        for index = 1:numel(Ch)
                            
                            % Append _# to file name
                            [~,BaseSaveFileName] = fileparts(SaveFileName);
                            SaveFilePath = fullfile(SavePathName,[BaseSaveFileName,'_',num2str(index),FileExt]);
                            
                            ThisAxes = get(Ch(index),'Children');
                            
                            % Check if the plot has children
                            TheseChildren = get(ThisAxes,'Children');     
                            if ~isempty(TheseChildren) && iscell(TheseChildren) 
                                HasVisibleItem = true(1,numel(TheseChildren));
                                for chIdx = 1:numel(TheseChildren)
                                    
                                    ThisGroup = TheseChildren{chIdx};
                                    ThisGroupChildren = get(ThisGroup,'Children');
                                    if ~iscell(ThisGroupChildren)
                                        ThisGroupChildren = {ThisGroupChildren};
                                    end
                                    if ~isempty(ThisGroupChildren)
                                        HasVisibleItem(chIdx) = any(strcmpi(get(vertcat(ThisGroupChildren{:}),'Visible'),'on') &...
                                            ~strcmpi(get(vertcat(ThisGroupChildren{:}),'Tag'),'DummyLine'));
                                    else
                                        HasVisibleItem(chIdx) = false;
                                    end
                                    
                                    
                                end
                                % Filter to only allow export of plots that
                                % have children (at least one visible item
                                % that is not a dummyline)
                                TheseChildren = TheseChildren(HasVisibleItem);
                            end
                            
                            if ~isempty(TheseChildren)
                                % Call helper to copy axes and format
                                printAxesHelper(obj,ThisAxes,SaveFilePath,obj.PlotSettings(index))                            
                            end
                          
                        end % for
                        
                        set(hFigure,'pointer','arrow');
                        drawnow;
                        
                    end %if
                    
%                 case 'ExportSingleAxes'
%                     % Prompt the user for a filename
%                     Spec = {...
%                         '*.png','PNG';
%                         '*.tif;*.tiff','TIFF';...
%                         '*.eps','EPS';...
%                         '*.fig','MATLAB Figure';...
%                         };
%                     Title = 'Save as';
%                     SaveFilePath = obj.LastPath;
%                     [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
%                     if ~isequal(SaveFileName,0)
%                         SaveFilePath = fullfile(SavePathName,SaveFileName);
%                         hTempFig = figure('Visible','off');
%                         ThisAxes = get(obj.h.MainAxesContainer(axIndex),'Children');
%                         hNewAxes = copyobj(ThisAxes,hTempFig);
%                         set(hTempFig,'Color','white');
%                         
%                         % Print using option
%                         [~,~,FileExt] = fileparts(SaveFilePath);
%                         if strcmpi(FileExt,'.fig')
%                             % Delete the legend from hThisAxes
%                             delete(hNewAxes(strcmpi(get(hNewAxes,'Tag'),'legend')));
%                             hNewAxes = hNewAxes(ishandle(hNewAxes));
%                             % Create a new legend
%                             OrigLegend = ThisAxes(strcmpi(get(ThisAxes,'Tag'),'legend'));
%                             if ~isempty(OrigLegend)
%                                 % Make current axes and place legend
%                                 axes(hNewAxes);                                
%                                 legend(OrigLegend.String{:});
%                             end
%                             set(hTempFig,'Visible','on')
%                             saveas(hTempFig,SaveFilePath);
%                         else
%                             if strcmpi(FileExt,'.png')
%                                 Option = '-dpng';
%                             elseif strcmpi(FileExt,'.eps')
%                                 Option = '-depsc';
%                             else
%                                 Option = '-dtiff';
%                             end
%                             print(hTempFig,Option,SaveFilePath)
%                         end
%                         close(hTempFig)                        
%                     end
%                 case 'ExportAllAxes'
%                     % Prompt the user for a filename
%                      Spec = {...
%                         '*.png','PNG';
%                         '*.tif;*.tiff','TIFF';...
%                         '*.eps','EPS';...
%                         '*.fig','MATLAB Figure'...
%                         };
%                     Title = 'Save as';
%                     SaveFilePath = obj.LastPath;
%                     [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
%                     if ~isequal(SaveFileName,0)
%                         SaveFilePath = fullfile(SavePathName,SaveFileName);
%                         
%                         % Print using option
%                         [~,~,FileExt] = fileparts(SaveFilePath);
%                         
%                         if strcmpi(FileExt,'.fig')
%                             hTempFig = figure('Visible','off');
%                             Pos = get(obj.h.PlotGrid,'Position');
%                             set(hTempFig,'Units',obj.Figure.Units,'Position',[obj.Figure.Position(1:2) Pos(3) Pos(4)],'Color','white');
%                             
%                             Ch = get(obj.h.PlotGrid,'Children');
%                             for index = 1:numel(Ch)
%                                 hThisContainer = uicontainer('Parent',hTempFig,'Units','pixels','Position',get(Ch(index),'Position'));
%                                 
%                                 ThisAxes = get(Ch(index),'Children');
%                                 hNewAxes = copyobj(ThisAxes,hThisContainer);
%                                 
%                                 % Delete the legend from hThisAxes
%                                 delete(hNewAxes(strcmpi(get(hNewAxes,'Tag'),'legend')));
%                                 hNewAxes = hNewAxes(ishandle(hNewAxes));
%                                 % Create a new legend
%                                 OrigLegend = ThisAxes(strcmpi(get(ThisAxes,'Tag'),'legend'));
%                                 if ~isempty(OrigLegend)
%                                     % Make current axes and place legend
%                                     axes(hNewAxes); %#ok<LAXES>
%                                     legend(OrigLegend.String{:});
%                                 end
%                                 set(hThisContainer,'BackgroundColor','white','Units','normalized');
%                             end
%                             
%                             set(hTempFig,'Visible','on')
%                             saveas(hTempFig,SaveFilePath);
%                             
%                         else
%                             
%                             hTempFig = figure('Visible','off');
%                             hGrid = copyobj(obj.h.PlotGrid,hTempFig);
%                             Units = get(obj.h.PlotGrid,'Units');
%                             Pos = get(obj.h.PlotGrid,'Position');
%                             set(hGrid,'BackgroundColor','white','Units',Units,'Position',[0 0 Pos(3) Pos(4)]);
%                             hContainers = get(hGrid,'Children');
%                             set(hContainers,'BackgroundColor','white');
%                             hFigure = ancestor(obj.UIContainer,'Figure');
%                             set(hTempFig,'Units',hFigure.Units,'Position',[hFigure.Position(1:2) Pos(3) Pos(4)],'Color','white');
%                             
%                             if strcmpi(FileExt,'.png')
%                                 Option = '-dpng';
%                             elseif strcmpi(FileExt,'.eps')
%                                 Option = '-depsc';
%                             else
%                                 Option = '-dtiff';
%                             end
%                             print(hTempFig,Option,SaveFilePath)
%                             
%                             close(hTempFig)
%                         end
%                     end
                case 'ShowTraces'
                    obj.bShowTraces(axIndex) = ~obj.bShowTraces(axIndex);
                    h.Checked = uix.utility.tf2onoff(obj.bShowTraces(axIndex));
                case 'ShowQuantiles'
                    obj.bShowQuantiles(axIndex) = ~obj.bShowQuantiles(axIndex);
                    h.Checked = uix.utility.tf2onoff(obj.bShowQuantiles(axIndex));
                case 'ShowMean'
                    obj.bShowMean(axIndex) = ~obj.bShowMean(axIndex);
                    h.Checked = uix.utility.tf2onoff(obj.bShowMean(axIndex));                    
                case 'ShowMedian'
                    obj.bShowMedian(axIndex) = ~obj.bShowMedian(axIndex);
                    h.Checked = uix.utility.tf2onoff(obj.bShowMedian(axIndex));
                case 'ShowSD'
                    obj.bShowSD(axIndex) = ~obj.bShowSD(axIndex);
                    h.Checked = uix.utility.tf2onoff(obj.bShowSD(axIndex));
            end
            
            % Update the display
            obj.updateVisualizationView();
            
            if strcmp(ThisTag,'ShowTraces') || strcmp(ThisTag,'ShowQuantiles') || strcmp(ThisTag,'ShowMean') || strcmp(ThisTag,'ShowMedian') || strcmp(ThisTag,'ShowSD')
                if any(strcmpi(class(obj),{'QSPViewer.Simulation','QSPViewer.CohortGeneration','QSPViewer.VirtualPopulationGeneration'}))
                    [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                        obj.Data,obj.h.MainAxes,obj.h.SpeciesGroup,obj.h.DatasetGroup,...
                        'AxIndices',axIndex);
                    obj.h.AxesLegend(axIndex) = UpdatedAxesLegend(axIndex);
                    obj.h.AxesLegendChildren(axIndex) = UpdatedAxesLegendChildren(axIndex);
                else
                    obj.plotData();
                end
            end
            
        end %function
        
        function refresh(obj)
            
            %%% Update TempData
            if ~isempty(obj.Data)
                % Copy from Data into TempData, using obj.TempData as a
                % starting point
                obj.TempData = copy(obj.Data,obj.TempData);
                
                if obj.UseRunVis
                   % Copy Data's PlotSettings struct (backend) to PlotSettings (frontend)
                   for index = 1:obj.MaxNumPlots
                       Summary = obj.Data.PlotSettings(index);
                       % If Summary is empty (i.e., new node), then use
                       % defaults
                       if isempty(fieldnames(Summary))
                           Summary = QSP.PlotSettings.getDefaultSummary();
                       end
                       set(obj.PlotSettings(index),fieldnames(Summary),struct2cell(Summary)');
                   end
                end
            end
            
        end %function
        
        function updateNameDescription(obj)
            
            %%% Edit View (Use TempData)
            % Name, Description
            if ~isempty(obj.TempData)
                set(obj.h.FileSelect(2),'String',obj.TempData.Name);
                set(obj.h.FileSelect(4),'String',obj.TempData.Description);
            else
                set(obj.h.FileSelect(2),'String','');
                set(obj.h.FileSelect(4),'String','');
            end
            
        end %function
        
        function updateToggleButtons(obj)
            
            hFigure = ancestor(obj.UIContainer,'Figure');
            
            if ~isempty(hFigure) && ishandle(hFigure)
                zoomObj = zoom(hFigure);
                panObj = pan(hFigure);
                datacursorObj = datacursormode(hFigure);
                Direction = get(zoomObj,'Direction');
                if strcmpi(get(zoomObj,'Enable'),'on') && strcmpi(Direction,'in')
                    set(obj.h.ZoomInButton,'Value',true);
                else
                    set(obj.h.ZoomInButton,'Value',false);
                end
                if strcmpi(get(zoomObj,'Enable'),'on') && strcmpi(Direction,'out')
                    set(obj.h.ZoomOutButton,'Value',true);
                else
                    set(obj.h.ZoomOutButton,'Value',false);
                end
                if strcmpi(get(panObj,'Enable'),'on')
                    set(obj.h.PanButton,'Value',true);
                else
                    set(obj.h.PanButton,'Value',false);
                end
                if strcmpi(get(datacursorObj,'Enable'),'on')
                    set(obj.h.DatacursorButton,'Value',true);
                else
                    set(obj.h.DatacursorButton,'Value',false);
                end
            end
            
        end %function
        
        function update(obj)
            
            %%% Buttons
            % Toggle visibility
            set([obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Visible',uix.utility.tf2onoff(obj.UseRunVis));            
            set([obj.h.ZoomInButton,obj.h.ZoomOutButton,obj.h.PanButton,obj.h.DatacursorButton],'Visible',uix.utility.tf2onoff(obj.UseRunVis));
            if obj.Selection == 3
                set([obj.h.ZoomInButton,obj.h.ZoomOutButton,obj.h.PanButton,obj.h.DatacursorButton],'Enable','on');
            else
                set([obj.h.ZoomInButton,obj.h.ZoomOutButton,obj.h.PanButton,obj.h.DatacursorButton],'Enable','off');
            end
            
            %%% Update toggle buttons
            updateToggleButtons(obj);
            
            %%% Summary (Use Data)
            if ~isempty(obj.Data)
                set(obj.h.SummaryContent,'AllItems',getSummary(obj.Data));
            else
                set(obj.h.SummaryContent,'AllItems',cell(0,2));
            end
            
            %%% Edit View (Use TempData)
            updateNameDescription(obj)
            
            %%%% Plots
            if obj.UseRunVis
                
                % Copy PlotSettings (frontend) back to Data struct
                % (backend)
                if ~isempty(obj.Data)
                    obj.Data.PlotSettings = getSummary(obj.PlotSettings);
                end
                
                % Plot configuration
                MatchIndex = find(strcmp(obj.SelectedPlotLayout,obj.PlotLayoutOptions));
                set(obj.h.PlotConfigPopup,'String',obj.PlotLayoutOptions,'Value',MatchIndex);
                
                switch obj.SelectedPlotLayout
                    case '1x1'
                        set(obj.h.MainAxesContainer(1),'Parent',obj.h.PlotGrid);
                        set(obj.h.MainAxesContainer(2:end),'Parent',obj.NoParent_);
                        obj.h.PlotGrid.Heights = -1;
                        obj.h.PlotGrid.Widths = -1;
%                         obj.h.PlotGrid.Heights = [-1 zeros(1,obj.MaxNumPlots-1)];
%                         obj.h.PlotGrid.Widths = -1;
                        set(obj.h.MainAxes(1),'Visible','on');
                        set(obj.h.MainAxes(2:end),'Visible','off');
                    case '1x2'
                        set(obj.h.MainAxesContainer(1:2),'Parent',obj.h.PlotGrid);
                        set(obj.h.MainAxesContainer(3:end),'Parent',obj.NoParent_);
                        obj.h.PlotGrid.Heights = -1;
                        obj.h.PlotGrid.Widths = [-1 -1];
%                         obj.h.PlotGrid.Heights = -1;
%                         obj.h.PlotGrid.Widths = [-1 -1 zeros(1,obj.MaxNumPlots-2)];
                        set(obj.h.MainAxes(1:2),'Visible','on');
                        set(obj.h.MainAxes(3:end),'Visible','off');                        
                    case '2x1'
                        set(obj.h.MainAxesContainer(1:2),'Parent',obj.h.PlotGrid);
                        set(obj.h.MainAxesContainer(3:end),'Parent',obj.NoParent_);
                        obj.h.PlotGrid.Heights = [-1 -1];
                        obj.h.PlotGrid.Widths = -1;
%                         obj.h.PlotGrid.Heights = [-1 -1 zeros(1,obj.MaxNumPlots-2)];
%                         obj.h.PlotGrid.Widths = -1;
                        set(obj.h.MainAxes(1:2),'Visible','on');
                        set(obj.h.MainAxes(3:end),'Visible','off');
                    case '2x2'
                        set(obj.h.MainAxesContainer(1:4),'Parent',obj.h.PlotGrid);
                        set(obj.h.MainAxesContainer(5:end),'Parent',obj.NoParent_);
                        obj.h.PlotGrid.Heights = [-1 -1];
                        obj.h.PlotGrid.Widths = [-1 -1];
%                         obj.h.PlotGrid.Heights = [-1 -1];
%                         obj.h.PlotGrid.Widths = [-1 -1 0 0 0 0];
                        set(obj.h.MainAxes(1:4),'Visible','on');
                        set(obj.h.MainAxes(5:end),'Visible','off');                        
                    case '3x2'
                        set(obj.h.MainAxesContainer(1:6),'Parent',obj.h.PlotGrid);
                        set(obj.h.MainAxesContainer(7:end),'Parent',obj.NoParent_);
                        obj.h.PlotGrid.Heights = [-1 -1 -1];
                        obj.h.PlotGrid.Widths = [-1 -1];
%                         obj.h.PlotGrid.Heights = [-1 -1 -1];
%                         obj.h.PlotGrid.Widths = [-1 -1 0 0];
                        set(obj.h.MainAxes(1:6),'Visible','on');
                        set(obj.h.MainAxes(7:end),'Visible','off');                        
                    case '3x3'
                        set(obj.h.MainAxesContainer(1:9),'Parent',obj.h.PlotGrid);
                        set(obj.h.MainAxesContainer(10:end),'Parent',obj.NoParent_);
                        obj.h.PlotGrid.Heights = [-1 -1 -1];
                        obj.h.PlotGrid.Widths = [-1 -1 -1];
%                         obj.h.PlotGrid.Heights = [-1 -1 -1];
%                         obj.h.PlotGrid.Widths = [-1 -1 -1 0];
                        set(obj.h.MainAxes(1:9),'Visible','on');
                        set(obj.h.MainAxes(10:end),'Visible','off');                        
                    case '3x4'
                        set(obj.h.MainAxesContainer(1:end),'Parent',obj.h.PlotGrid);
                        obj.h.PlotGrid.Heights = [-1 -1 -1];
                        obj.h.PlotGrid.Widths = [-1 -1 -1 -1];
%                         obj.h.PlotGrid.Heights = [-1 -1 -1];
%                         obj.h.PlotGrid.Widths = [-1 -1 -1 -1];
                        set(obj.h.MainAxes(1:end),'Visible','on');                  
                end
                
                % Attach contextmenu
                
                for index = 1:obj.MaxNumPlots
                    hFigure = ancestor(obj.h.MainAxesContainer(index),'Figure');
                    obj.h.ContextMenu(index).Parent = hFigure;                
                    set(obj.h.MainAxes(index),'UIContextMenu',obj.h.ContextMenu(index));
                end
                
                % Update legends from PlotSettings
                updateLegends(obj);

                % Update lines from PlotSettings
                updateLines(obj);

            end
            
        end %function
        
        function Value = getAxesOptions(obj)
            % Get axes options for dropdown
            
            Value = num2cell(1:obj.MaxNumPlots)';
            Value = cellfun(@(x)num2str(x),Value,'UniformOutput',false);
            Value = vertcat({' '},Value);
            
        end %function
        
        function resize(obj) %#ok<MANU>
            % Do nothing for now
        end
        
    end %methods
    
    
    methods (Access=protected)
        
        function updateLines(obj)
            
            % Iterate through each axes and turn on SelectedProfileRow
            if isfield(obj.h,'SpeciesGroup') && ~isempty(obj.h.SpeciesGroup)
                for axIndex = 1:size(obj.h.SpeciesGroup,2)
                    MeanLineWidth = obj.Data.PlotSettings(axIndex).MeanLineWidth;
                    MedianLineWidth = obj.Data.PlotSettings(axIndex).MedianLineWidth;
                    StandardDevLineWidth = obj.Data.PlotSettings(axIndex).StandardDevLineWidth;
                    BoundaryLineWidth = obj.Data.PlotSettings(axIndex).BoundaryLineWidth;
                    LineWidth = obj.Data.PlotSettings(axIndex).LineWidth;
                    
                    hPlots = obj.h.SpeciesGroup(:,axIndex,:);
                    if iscell(hPlots)
                        hPlots = horzcat(hPlots{:});
                    end
                    hPlots(~ishandle(hPlots)) = [];
                    if ~isempty(hPlots) && isa(hPlots,'matlab.graphics.primitive.Group')
                        hPlots = vertcat(hPlots.Children);
                        hPlots(~ishandle(hPlots)) = [];
                    end         
                    ThisTag = get(hPlots,'Tag');
                    IsMeanLine = strcmpi(ThisTag,'MeanLine');
                    IsMedianLine = strcmpi(ThisTag,'MedianLine');
                    IsStandardDevLine = strcmpi(ThisTag,'WeightedSD');
%                     IsWeightedMeanLine = strcmpi(ThisTag,'WeightedMeanLine');
                    IsBoundaryLine = strcmpi(ThisTag,'BoundaryLine');
                    if ~isempty(hPlots)
                        set(hPlots(IsMeanLine),...
                            'LineWidth',MeanLineWidth);
                        set(hPlots(IsMedianLine),...
                            'LineWidth',MedianLineWidth);
                        set(hPlots(IsStandardDevLine),...
                            'LineWidth',StandardDevLineWidth);
                        set(hPlots(IsBoundaryLine),...
                            'LineWidth',BoundaryLineWidth);
                        set(hPlots(~IsMeanLine & ~IsMedianLine & ~IsStandardDevLine & ~IsBoundaryLine),...
                            'LineWidth',LineWidth);
                    end
                end
            end
            
            % Dataset line
            if isfield(obj.h,'DatasetGroup') && ~isempty(obj.h.DatasetGroup)
                for axIndex = 1:size(obj.h.DatasetGroup,2)
                    DataSymbolSize = obj.Data.PlotSettings(axIndex).DataSymbolSize;
                    
                    hPlots = obj.h.DatasetGroup(:,axIndex);
                    if iscell(hPlots)
                        hPlots = horzcat(hPlots{:});
                    end
                    hPlots(~ishandle(hPlots)) = [];
                    if ~isempty(hPlots) && isa(hPlots,'matlab.graphics.primitive.Group')
                        hPlots = vertcat(hPlots.Children);
                        hPlots(~ishandle(hPlots)) = [];
                    end
                    ThisTag = get(hPlots,'Tag');
                    IsDummyLine = strcmpi(ThisTag,'DummyLine');
                    if ~isempty(hPlots)
                        set(hPlots(~IsDummyLine),...
                            'MarkerSize',DataSymbolSize);
                    end
                end
            end
            
        end %function
        
        function updateLegends(obj)
            
            if isfield(obj.h,'AxesLegend') && ~isempty(obj.h.AxesLegend)
                for axIndex = 1:numel(obj.Data.PlotSettings)
                    if ~isempty(obj.h.AxesLegend{axIndex}) && ishandle(obj.h.AxesLegend{axIndex})
                        % Visible, Location
                        obj.h.AxesLegend{axIndex}.Visible = obj.Data.PlotSettings(axIndex).LegendVisibility;
                        obj.h.AxesLegend{axIndex}.Location = obj.Data.PlotSettings(axIndex).LegendLocation;
                        obj.h.AxesLegend{axIndex}.FontSize = obj.Data.PlotSettings(axIndex).LegendFontSize;
                        obj.h.AxesLegend{axIndex}.FontWeight = obj.Data.PlotSettings(axIndex).LegendFontWeight;
                        
                        % FontSize, FontWeight
                        if isfield(obj.h,'AxesLegendChildren') && ~isempty(obj.h.AxesLegendChildren)
                            
                            ch = obj.h.AxesLegendChildren{axIndex};
                            if all(ishandle(ch))
                                for cIndex = 1:numel(ch)
                                    if isprop(ch(cIndex),'FontSize')
                                        ch(cIndex).FontSize = obj.Data.PlotSettings(axIndex).LegendFontSize;
                                    end
                                    if isprop(ch(cIndex),'FontWeight')
                                        ch(cIndex).FontWeight = obj.Data.PlotSettings(axIndex).LegendFontWeight;
                                    end
                                end %legend chidlren
                            end %ishandle
                        end
                    end %ishandle
                end %for
            end %if
            
        end %function
        
        function printAxesHelper(obj,hAxes,SaveFilePath,PlotSettings)
            
            % Print using option
            [~,~,FileExt] = fileparts(SaveFilePath);
                        
            hNewFig = figure('Visible','off');
            set(hNewFig,'Color','white');
            
            % Use current axes to determine which line handles should be
            % used for the legend
            hUIAxes = hAxes(~strcmpi(get(hAxes,'Tag'),'legend'));
            theseGroups = get(hUIAxes,'Children');
            
            for index = 1:numel(theseGroups)
                ch = get(theseGroups(index),'Children');
                
                % Turn off all and turn on 
                hAnn = get(ch,'Annotation');
                if ~iscell(hAnn)
                    hAnn = {hAnn};
                end
                hAnn = cellfun(@(x)get(x,'LegendInformation'),hAnn,'UniformOutput',false);
                IconDisplayStyle = cellfun(@(x)get(x,'IconDisplayStyle'),hAnn,'UniformOutput',false);
                ForRestoreAnn{index} = IconDisplayStyle; %#ok<AGROW>
                
                % Set icondisplaystyle for export
                if strcmpi(get(theseGroups(index),'Tag'),'Data') && strcmpi(PlotSettings.LegendDataGroup,'off')
                    % If Data and legend data group is off
                    KeepIdxOn = false(1,numel(hAnn));
                else
                    % Species or Data Group is on
                    if numel(ch) > 1
                        KeepIdxOn = ~strcmpi(get(ch,'Tag'),'DummyLine') & ~cellfun(@isempty,(get(ch,'DisplayName'))) & strcmpi(get(ch,'Visible'),'on');
                    else
                        KeepIdxOn = ~strcmpi(get(ch,'Tag'),'DummyLine') & ~isempty(get(ch,'DisplayName')) & strcmpi(get(ch,'Visible'),'on');
                    end
                end
                cellfun(@(x)set(x,'IconDisplayStyle','on'),hAnn(KeepIdxOn),'UniformOutput',false);
                cellfun(@(x)set(x,'IconDisplayStyle','off'),hAnn(~KeepIdxOn),'UniformOutput',false);
                
            end
            
%             % Keep all annotation-on
%             hAnn = get(theseGroups,'Annotation');
%             if ~iscell(hAnn)
%                 hAnn = {hAnn};
%             end
%             hAnn = cellfun(@(x)get(x,'LegendInformation'),hAnn,'UniformOutput',false);
%             hAnn = cellfun(@(x)get(x,'IconDisplayStyle'),hAnn,'UniformOutput',false);
%             KeepIdxOn = strcmpi(hAnn,'on');
            
%             % Remove all UI legend only handles
%             ThisTag = get(theseGroups,'Tag');
%             if ~iscell(ThisTag)
%                 ThisTag = {ThisTag};
%             end
%             KeepExportIdx = strcmpi(ThisTag,'ForExportLegend');
            
            % Aggregate - No need to use KeepIdxOn since groups are used
            % (to validate)
%             KeepIdx = KeepIdxOn & KeepExportIdx;
%             KeepIdx = KeepExportIdx;
            
            % Copy axes to figure
            hNewAxes = copyobj(hAxes,hNewFig);
            
            % Delete the legend from hThisAxes
            delete(hNewAxes(strcmpi(get(hNewAxes,'Tag'),'legend')));
            hNewAxes = hNewAxes(ishandle(hNewAxes));
            
            % Create new plot settings and initialize with values from
            % original plot settings
            NewPlotSettings = QSP.PlotSettings(hNewAxes);
            Summary = getSummary(PlotSettings);
            set(NewPlotSettings,fieldnames(Summary),struct2cell(Summary)');
            
            % Create a new legend
            OrigLegend = hAxes(strcmpi(get(hAxes,'Tag'),'legend'));
            if ~isempty(OrigLegend)
                hLine = get(hNewAxes,'Children');
%                 UserData = get(hLine,'UserData');
%                 if ~iscell(UserData)
%                     UserData = {UserData};
%                 end
                
                % Format display name
                for idx = 1:numel(hLine)
                    % Replace _ with \_
                    hLine(idx).DisplayName = regexprep(hLine(idx).DisplayName,'_','\\_');
                    % In case there is now a \\_ (if previous formatted in plotting code), replace it with \_
                    hLine(idx).DisplayName = regexprep(hLine(idx).DisplayName,'\\\\_','\\_');
                end
                
                Location = OrigLegend.Location;
                Visible = OrigLegend.Visible;
                FontSize = OrigLegend.FontSize;
                FontWeight = OrigLegend.FontWeight;
                
                % Make current axes and place legend
                axes(hNewAxes);
%                 hLine = hLine(KeepIdx);
                hLine = flipud(hLine(:));
                hLine = vertcat(hLine.Children);
                
                hAnn = get(hLine,'Annotation');
                if ~iscell(hAnn)
                    hAnn = {hAnn};
                end
                hAnn = cellfun(@(x)get(x,'LegendInformation'),hAnn,'UniformOutput',false);
                hAnn = cellfun(@(x)get(x,'IconDisplayStyle'),hAnn,'UniformOutput',false);
                KeepIdx = strcmpi(hAnn,'on');
                
                if any(KeepIdx)
                    [hLegend,hLegendChildren] = legend(hLine(KeepIdx));
                    % Set the legend - location and visibility
                    hLegend.Location = Location;
                    hLegend.Visible = Visible;
                    hLegend.EdgeColor = 'none';

                    % Set the fontsize and fontweight
                    hLegend.FontSize = FontSize;
                    hLegend.FontWeight = FontWeight;
                    [hLegendChildren(arrayfun(@(x)isprop(x,'FontSize'),hLegendChildren)).FontSize] = deal(FontSize);
                    [hLegendChildren(arrayfun(@(x)isprop(x,'FontWeight'),hLegendChildren)).FontWeight] = deal(FontWeight);

                    % Fit axes in Figure
                    uix.abstract.CardViewPane.fixAxesInFigure(hNewFig,[hNewAxes hLegend]);
                else
                    % Fit axes in Figure
                    uix.abstract.CardViewPane.fixAxesInFigure(hNewFig,hNewAxes);
                end
            else
                % Fit axes in Figure
                uix.abstract.CardViewPane.fixAxesInFigure(hNewFig,hNewAxes);
            end
            
            if strcmpi(FileExt,'.fig')
                set(hNewFig,'Visible','on')
                saveas(hNewFig,SaveFilePath);
            else
                if strcmpi(FileExt,'.png')
                    Option = '-dpng';
                elseif strcmpi(FileExt,'.eps')
                    Option = '-depsc';
                else
                    Option = '-dtiff';
                end
                print(hNewFig,Option,SaveFilePath,'-r300')
            end
            
            % Restore
            for index = 1:numel(theseGroups)
                ch = get(theseGroups(index),'Children');
                
                % Turn off all and turn on 
                hAnn = get(ch,'Annotation');
                if ~iscell(hAnn)
                    hAnn = {hAnn};
                end
                hAnn = cellfun(@(x)get(x,'LegendInformation'),hAnn,'UniformOutput',false);
                IsOn = strcmpi(ForRestoreAnn{index},'on');
                IsOff = strcmpi(ForRestoreAnn{index},'off');
                cellfun(@(x)set(x,'IconDisplayStyle','on'),hAnn(IsOn),'UniformOutput',false);
                cellfun(@(x)set(x,'IconDisplayStyle','off'),hAnn(IsOff),'UniformOutput',false);
            end
            
            close(hNewFig)
        end %function
        
    end %methods (protected)
    
    
    methods (Static)
        
        function fixAxesInFigure(hFigure,hAxes)
            % Fixed pixels dimensions for axes
            AxesDestW = 434; % Desired axes width
            AxesDestH = 342; % Desired axes height
            Buffer = 20; % Buffer within figure
            
            % Update main axes
            hMainAxes = hAxes(~strcmpi(get(hAxes,'Tag'),'legend'));
            set(hMainAxes,'Units','pixels');
            set(hMainAxes,'ActivePositionProperty','outerposition')  % needed?
            Position = get(hMainAxes,'Position');            
            set(hMainAxes,'Position',[Position(1:2) AxesDestW AxesDestH]);
            set(hMainAxes,'Units','normalized');
%             OuterPosition = get(hMainAxes,'OuterPosition');
%             set(hMainAxes,'OuterPosition',[0 0 OuterPosition(3:4)]);
            
            % Set Units to be pixels
            MaxW = 0;
            MaxH = 0;
            for index = 1:numel(hAxes)
                hAxes(index).Units = 'pixels';
                ThisPos = get(hAxes(index),'Position');
                if (ThisPos(1)+ThisPos(3)) > MaxW
                    MaxW = ThisPos(1)+ThisPos(3);
                end
                if (ThisPos(2)+ThisPos(4)) > MaxH
                    MaxH = ThisPos(2)+ThisPos(4);
                end
            end
            % Check against OuterPosition
            OuterPosition = get(hMainAxes,'OuterPosition');
            MaxW = max(MaxW,OuterPosition(1)+OuterPosition(3));
            MaxH = max(MaxH,OuterPosition(2)+OuterPosition(4));
            
            % Update main figure            
            set(hFigure,'Position',[50 50 MaxW+Buffer MaxH+Buffer]);
            
            % Set units to normalized
            for index = 1:numel(hAxes)
                set(hAxes(index),'Units','normalized');
            end
            
        end %function
        
        
         function [hThisLegend,hThisLegendChildren] = redrawLegend(hThisAxes,LegendItems,ThesePlotSettings)
            
             hThisLegend = [];
             hThisLegendChildren = [];
             
             if ~isempty(LegendItems)
                 try
                     % Add legend
                     [hThisLegend,hThisLegendChildren] = legend(hThisAxes,LegendItems);
                     
                     % Color, FontSize, FontWeight
                     for cIndex = 1:numel(hThisLegendChildren)
                         if isprop(hThisLegendChildren(cIndex),'FontSize')
                             hThisLegendChildren(cIndex).FontSize = ThesePlotSettings.LegendFontSize;
                         end
                         if isprop(hThisLegendChildren(cIndex),'FontWeight')
                             hThisLegendChildren(cIndex).FontWeight = ThesePlotSettings.LegendFontWeight;
                         end
                     end
                     
                     set(hThisLegend,...
                         'EdgeColor','none',...
                         'Visible',ThesePlotSettings.LegendVisibility,...
                         'Location',ThesePlotSettings.LegendLocation,...
                         'FontSize',ThesePlotSettings.LegendFontSize,...
                         'FontWeight',ThesePlotSettings.LegendFontWeight);
                 catch ME
                     warning(ME.message)
                 end
             else
                 Siblings = get(get(hThisAxes,'Parent'),'Children');
                 IsLegend = strcmpi(get(Siblings,'Type'),'legend');
                 
                 if any(IsLegend)
                     if isvalid(Siblings(IsLegend))
                         delete(Siblings(IsLegend));
                     end
                 end
                 
                 hThisLegend = [];
                 hThisLegendChildren = [];
             end
             
        end %function
        
    end % methods (Static)
    
    methods
        
        function set.IsDeleted(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.IsDeleted = Value;
            if obj.IsDeleted
                set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','off');
                obj.Selection = 1; %#ok<MCSUP>
            else
                if obj.Selection == 2 %#ok<MCSUP>
                    set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','off');                
                else
                    set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton,obj.h.PlotSettingsButton],'Enable','on');                
                end
            end
        end
        
        function set.Selection(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','>=',1,'<=',3});
            obj.Selection = Value;
            obj.h.CardPanel.Selection = Value;
        end
        
        function set.TempData(obj,Value)
            obj.TempData = Value;
            refresh(obj);
        end
        
        function set.SelectedPlotLayout(obj,Value)
            obj.SelectedPlotLayout = Value;
        end
        
    end
    
end % classdef
