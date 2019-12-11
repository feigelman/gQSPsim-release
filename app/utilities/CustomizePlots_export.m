function varargout = CustomizePlots_export(varargin)
% CustomizePlots_export UI
%
%   Syntax:
%       CustomizePlots_export
%
% CUSTOMIZEPLOTS_EXPORT MATLAB code for CustomizePlots_export.fig
%      CUSTOMIZEPLOTS_EXPORT, by itself, creates a new CUSTOMIZEPLOTS_EXPORT or raises the existing
%      singleton*.
%
%      H = CUSTOMIZEPLOTS_EXPORT returns the handle to a new CUSTOMIZEPLOTS_EXPORT or the handle to
%      the existing singleton*.
%
%      CUSTOMIZEPLOTS_EXPORT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CUSTOMIZEPLOTS_EXPORT.M with the given input arguments.
%
%      CUSTOMIZEPLOTS_EXPORT('Property','Value',...) creates a new CUSTOMIZEPLOTS_EXPORT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CustomizePlots_export_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CustomizePlots_export_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%   Copyright 2017 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
% ---------------------------------------------------------------------

% Edit the above text to modify the response to help CustomizePlots_export

% Last Modified by GUIDE v2.5 27-Mar-2019 07:07:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @CustomizePlots_export_OpeningFcn, ...
    'gui_OutputFcn',  @CustomizePlots_export_OutputFcn, ...
    'gui_LayoutFcn',  @CustomizePlots_export_LayoutFcn, ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% Suppress Messages
%#ok<*DEFNU>


% --- Executes just before CustomizePlots_export is made visible.
function CustomizePlots_export_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CustomizePlots_export (see VARARGIN)

% For debugging:
set(handles.GUIFigure,'WindowStyle','modal')
set(handles.GUIFigure,'Resize','on');
set(handles.Settings1_PANEL,'Units','normalized');
set(handles.Settings2_PANEL,'Units','normalized');
set(handles.Settings3_PANEL,'Units','normalized');
set(handles.Settings4_PANEL,'Units','normalized');
set(handles.OK_PUSHBUTTON,'Units','normalized');

p = inputParser;

p.addParameter('Settings',QSP.PlotSettings.empty(0,1),@(x)all(isa(x,'QSP.PlotSettings')));

% Parse and distribute results
p.parse(varargin{:});

% Distribute
Settings = p.Results.Settings;

% -- Create table
handles.SettingsTable(1) = uitable(...
    'Parent',handles.Settings1_PANEL,...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Tag','SettingsTable1');
handles.SettingsTable(2) = uitable(...
    'Parent',handles.Settings2_PANEL,...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Tag','SettingsTable2');
handles.SettingsTable(3) = uitable(...
    'Parent',handles.Settings3_PANEL,...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Tag','SettingsTable3');
handles.SettingsTable(4) = uitable(...
    'Parent',handles.Settings4_PANEL,...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Tag','SettingsTable4');

for index = 1:numel(handles.SettingsTable)
    % Create context menu
    handles.SettingsTableContextMenu = uicontextmenu('Parent',handles.GUIFigure);
    uimenu(handles.SettingsTableContextMenu,...
        'Label','Apply to All Plots',...
        'Tag','ApplyAll',...
        'Callback',@(h,e)onSettingsTableContextMenu(h,e,handles,index));
    set(handles.SettingsTable(index),...
        'CellSelectionCallback',@(h,e)onSettingsTableSelection(h,e,handles,index),...
        'CellEditCallback',@(h,e)onSettingsTableEdited(h,e,handles,index),...
        'UIContextMenu',handles.SettingsTableContextMenu);
end


% -- Save in appdata
setappdata(handles.GUIFigure,'Settings',Settings);
setappdata(handles.GUIFigure,'CancelSelection',false);      
setappdata(handles.GUIFigure,'Row',1);
setappdata(handles.GUIFigure,'Col',1);
PropertyGroup = {...
    'SettablePropertiesGroup1',...
    'SettablePropertiesGroup2',...
    'SettablePropertiesGroup3',...
    'SettablePropertiesGroup4',...
    };
setappdata(handles.GUIFigure,'PropertyGroup',PropertyGroup);

% -- Set GUI name and all labels
set(handles.GUIFigure,'Name','Customize Plot Settings');
i_UpdateViewer(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CustomizePlots_export wait for user response (see UIRESUME)
uiwait(handles.GUIFigure);


% --- Outputs from this function are returned to the command line.
function varargout = CustomizePlots_export_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% First, check if handles is not empty - it is empty when the user presses
% X to close the GUI
if ~isempty(handles)
    cancelselection = getappdata(handles.GUIFigure,'CancelSelection');
    varargout{1} = ~cancelselection;
    if ~cancelselection
        varargout{2} = getappdata(handles.GUIFigure,'Settings');        
    else
        varargout{2} = [];        
    end
    close(handles.GUIFigure);
else
    % Treat as user pressed cancel and assign next output args to be empty
    varargout{1} = false;
    varargout{2} = [];    
end


% --- Executes on button press in OK_PUSHBUTTON.
function OK_PUSHBUTTON_Callback(hObject, eventdata, handles) %#ok<*INUSL>
% hObject    handle to OK_PUSHBUTTON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(handles.GUIFigure);


% --- Executes on button press in Cancel_PUSHBUTTON.
function Cancel_PUSHBUTTON_Callback(~, ~, handles)
% hObject    handle to Cancel_PUSHBUTTON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Choose default command line output for CustomizePlots_export

% Resume control if user pressed cancel
setappdata(handles.GUIFigure,'CancelSelection',true);
uiresume(handles.GUIFigure);


function onSettingsTableContextMenu(hObject, eventData, handles, index)

Settings = getappdata(handles.GUIFigure,'Settings');
PropertyGroup = getappdata(handles.GUIFigure,'PropertyGroup');
ThisPropGroup = PropertyGroup{index};

Row = getappdata(handles.GUIFigure,'Row');
Col = getappdata(handles.GUIFigure,'Col');

ThisData = get(handles.SettingsTable(index),'Data');
for index = 1:numel(Settings)
    Settings(index).(Settings(index).(ThisPropGroup){Col,1}) = ThisData{Row,Col};
end

setappdata(handles.GUIFigure,'Settings',Settings);

% Update viewer
i_UpdateViewer(handles);


function onSettingsTableSelection(hObject, eventData, handles, index) %#ok<INUSD>

if ~isempty(eventData) && isprop(eventData,'Indices') && numel(eventData.Indices) == 2
    Indices = eventData.Indices;
    setappdata(handles.GUIFigure,'Row',Indices(1));
    setappdata(handles.GUIFigure,'Col',Indices(2));     
end
    

function onSettingsTableEdited(hObject, eventData, handles, index)

NewData = get(hObject,'Data');
PropertyGroup = getappdata(handles.GUIFigure,'PropertyGroup');
ThisPropGroup = PropertyGroup{index};

Settings = getappdata(handles.GUIFigure,'Settings');
if ~isempty(eventData) && isprop(eventData,'Indices') && numel(eventData.Indices) == 2
    Indices = eventData.Indices;
    Row = Indices(1);
    Col = Indices(2);
    try
        Settings(Row).(Settings(Row).(ThisPropGroup){Col,1}) = NewData{Row,Col};
    catch ME  
        NewData{Row,Col} = Settings(Row).(Settings(Row).(ThisPropGroup){Col,1});
        set(hObject,'Data',NewData); 
        hDlg = errordlg(sprintf('Invalid value entered. %s',ME.message),'Invalid Value','modal');
        uiwait(hDlg);
    end
    setappdata(handles.GUIFigure,'Row',Indices(1));
    setappdata(handles.GUIFigure,'Col',Indices(2));
end

% Update viewer
i_UpdateViewer(handles);


%% Helper function: i_UpdateViewer
function i_UpdateViewer(handles)

Settings = getappdata(handles.GUIFigure,'Settings');
PropertyGroup = getappdata(handles.GUIFigure,'PropertyGroup');

if ~isempty(Settings)
    for pIndex = 1:numel(PropertyGroup)
        Summary = {};
        for index = 1:numel(Settings)
            ThisSummary = struct2cell(Settings(index).getSummary(PropertyGroup{pIndex}));
            ThisSummary = ThisSummary(:)';
            Summary = [Summary; ThisSummary]; %#ok<AGROW>
        end
        Fields = Settings(1).(PropertyGroup{pIndex})(:,1);
        ColumnFormat = Settings(1).(PropertyGroup{pIndex})(:,2);
        RowNames = cellfun(@(x)sprintf('Plot %d',x),num2cell(1:numel(Settings)),'UniformOutput',false);
        
        % Set table
        set(handles.SettingsTable(pIndex),...
            'RowName',RowNames(:),...
            'ColumnName',Fields,...
            'ColumnEditable',true(1,numel(Fields)),...
            'ColumnFormat',ColumnFormat(:)',...
            'Data',Summary);

    end
else
    Fields = {};
    Summary = {};
    ColumnFormat = {};
    RowNames = {};
    
    for pIndex = 1:numel(PropertyGroup)
        % Set table
        set(handles.SettingsTable(pIndex),...
            'RowName',RowNames,...
            'ColumnName',Fields,...
            'ColumnEditable',true(1,numel(Fields)),...
            'ColumnFormat',ColumnFormat(:)',...
            'Data',Summary);
    end
end


% --- Creates and returns a handle to the GUI figure. 
function h1 = CustomizePlots_export_LayoutFcn(policy)
% policy - create a new figure or use a singleton. 'new' or 'reuse'.

persistent hsingleton;
if strcmpi(policy, 'reuse') & ishandle(hsingleton)
    h1 = hsingleton;
    return;
end
load CustomizePlots_export.mat


appdata = [];
appdata.GUIDEOptions = mat{1};
appdata.lastValidTag = 'GUIFigure';
appdata.GUIDELayoutEditor = [];
appdata.initTags = struct(...
    'handle', [], ...
    'tag', 'GUIFigure');

h1 = figure(...
'Units',get(0,'defaultfigureUnits'),...
'Position',[520 314 601.6 488],...
'Visible','on',...
'IntegerHandle','off',...
'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
'MenuBar','none',...
'ToolBar','none',...
'Name','Create New Signal',...
'NumberTitle','off',...
'Tag','GUIFigure',...
'UserData',[],...
'WindowStyle','modal',...
'Resize','off',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
'ScreenPixelsPerInchMode','manual',...
'HandleVisibility','callback',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'OK_PUSHBUTTON';

h2 = uicontrol(...
'Parent',h1,...
'FontUnits',get(0,'defaultuicontrolFontUnits'),...
'Units',get(0,'defaultuicontrolUnits'),...
'String','OK',...
'Position',[256.2 9 92 27.2],...
'BackgroundColor',[0.8 0.8 0.8],...
'Callback',@(hObject,eventdata)CustomizePlots_export('OK_PUSHBUTTON_Callback',hObject,eventdata,guidata(hObject)),...
'Children',[],...
'Tag','OK_PUSHBUTTON',...
'FontSize',get(0,'defaultuicontrolFontSize'),...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'Settings1_PANEL';

h3 = uipanel(...
'Parent',h1,...
'FontUnits',get(0,'defaultuipanelFontUnits'),...
'Units','pixels',...
'Title',blanks(0),...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
'Tag','Settings1_PANEL',...
'Position',[19 367 282 100],...
'FontSize',get(0,'defaultuipanelFontSize'),...
'FontAngle','italic');

appdata = [];
appdata.lastValidTag = 'Settings2_PANEL';

h4 = uipanel(...
'Parent',h1,...
'FontUnits',get(0,'defaultuipanelFontUnits'),...
'Units','pixels',...
'Title',blanks(0),...
'ResizeFcn',blanks(0),...
'ButtonDownFcn',blanks(0),...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
'DeleteFcn',blanks(0),...
'Tag','Settings2_PANEL',...
'Position',[19.4 262.6 564.8 100],...
'FontSize',get(0,'defaultuipanelFontSize'),...
'FontAngle','italic');

appdata = [];
appdata.lastValidTag = 'Settings3_PANEL';

h5 = uipanel(...
'Parent',h1,...
'FontUnits',get(0,'defaultuipanelFontUnits'),...
'Units','pixels',...
'Title',blanks(0),...
'ResizeFcn',blanks(0),...
'ButtonDownFcn',blanks(0),...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
'DeleteFcn',blanks(0),...
'Tag','Settings3_PANEL',...
'Position',[19.4 157.8 564.8 100],...
'FontSize',get(0,'defaultuipanelFontSize'),...
'FontAngle','italic');

appdata = [];
appdata.lastValidTag = 'Settings4_PANEL';

h6 = uipanel(...
'Parent',h1,...
'FontUnits',get(0,'defaultuipanelFontUnits'),...
'Units','pixels',...
'Title',blanks(0),...
'ResizeFcn',blanks(0),...
'ButtonDownFcn',blanks(0),...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
'DeleteFcn',blanks(0),...
'Tag','Settings4_PANEL',...
'Position',[19.4 52.2 564.8 100],...
'FontSize',get(0,'defaultuipanelFontSize'),...
'FontAngle','italic');

appdata = [];
appdata.lastValidTag = 'Settings5_PANEL';

h7 = uipanel(...
'Parent',h1,...
'FontUnits',get(0,'defaultuipanelFontUnits'),...
'Units','pixels',...
'Title',blanks(0),...
'ResizeFcn',blanks(0),...
'ButtonDownFcn',blanks(0),...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} ,...
'DeleteFcn',blanks(0),...
'Tag','Settings5_PANEL',...
'Position',[301 367 282 100],...
'FontSize',get(0,'defaultuipanelFontSize'),...
'FontAngle','italic');


hsingleton = h1;


% --- Set application data first then calling the CreateFcn. 
function local_CreateFcn(hObject, eventdata, createfcn, appdata)

if ~isempty(appdata)
   names = fieldnames(appdata);
   for i=1:length(names)
       name = char(names(i));
       setappdata(hObject, name, getfield(appdata,name));
   end
end

if ~isempty(createfcn)
   if isa(createfcn,'function_handle')
       createfcn(hObject, eventdata);
   else
       eval(createfcn);
   end
end


% --- Handles default GUIDE GUI creation and callback dispatch
function varargout = gui_mainfcn(gui_State, varargin)

gui_StateFields =  {'gui_Name'
    'gui_Singleton'
    'gui_OpeningFcn'
    'gui_OutputFcn'
    'gui_LayoutFcn'
    'gui_Callback'};
gui_Mfile = '';
for i=1:length(gui_StateFields)
    if ~isfield(gui_State, gui_StateFields{i})
        error(message('MATLAB:guide:StateFieldNotFound', gui_StateFields{ i }, gui_Mfile));
    elseif isequal(gui_StateFields{i}, 'gui_Name')
        gui_Mfile = [gui_State.(gui_StateFields{i}), '.m'];
    end
end

numargin = length(varargin);

if numargin == 0
    % CUSTOMIZEPLOTS_EXPORT
    % create the GUI only if we are not in the process of loading it
    % already
    gui_Create = true;
elseif local_isInvokeActiveXCallback(gui_State, varargin{:})
    % CUSTOMIZEPLOTS_EXPORT(ACTIVEX,...)
    vin{1} = gui_State.gui_Name;
    vin{2} = [get(varargin{1}.Peer, 'Tag'), '_', varargin{end}];
    vin{3} = varargin{1};
    vin{4} = varargin{end-1};
    vin{5} = guidata(varargin{1}.Peer);
    feval(vin{:});
    return;
elseif local_isInvokeHGCallback(gui_State, varargin{:})
    % CUSTOMIZEPLOTS_EXPORT('CALLBACK',hObject,eventData,handles,...)
    gui_Create = false;
else
    % CUSTOMIZEPLOTS_EXPORT(...)
    % create the GUI and hand varargin to the openingfcn
    gui_Create = true;
end

if ~gui_Create
    % In design time, we need to mark all components possibly created in
    % the coming callback evaluation as non-serializable. This way, they
    % will not be brought into GUIDE and not be saved in the figure file
    % when running/saving the GUI from GUIDE.
    designEval = false;
    if (numargin>1 && ishghandle(varargin{2}))
        fig = varargin{2};
        while ~isempty(fig) && ~ishghandle(fig,'figure')
            fig = get(fig,'parent');
        end
        
        designEval = isappdata(0,'CreatingGUIDEFigure') || (isscalar(fig)&&isprop(fig,'GUIDEFigure'));
    end
        
    if designEval
        beforeChildren = findall(fig);
    end
    
    % evaluate the callback now
    varargin{1} = gui_State.gui_Callback;
    if nargout
        [varargout{1:nargout}] = feval(varargin{:});
    else       
        feval(varargin{:});
    end
    
    % Set serializable of objects created in the above callback to off in
    % design time. Need to check whether figure handle is still valid in
    % case the figure is deleted during the callback dispatching.
    if designEval && ishghandle(fig)
        set(setdiff(findall(fig),beforeChildren), 'Serializable','off');
    end
else
    if gui_State.gui_Singleton
        gui_SingletonOpt = 'reuse';
    else
        gui_SingletonOpt = 'new';
    end

    % Check user passing 'visible' P/V pair first so that its value can be
    % used by oepnfig to prevent flickering
    gui_Visible = 'auto';
    gui_VisibleInput = '';
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        % Recognize 'visible' P/V pair
        len1 = min(length('visible'),length(varargin{index}));
        len2 = min(length('off'),length(varargin{index+1}));
        if ischar(varargin{index+1}) && strncmpi(varargin{index},'visible',len1) && len2 > 1
            if strncmpi(varargin{index+1},'off',len2)
                gui_Visible = 'invisible';
                gui_VisibleInput = 'off';
            elseif strncmpi(varargin{index+1},'on',len2)
                gui_Visible = 'visible';
                gui_VisibleInput = 'on';
            end
        end
    end
    
    % Open fig file with stored settings.  Note: This executes all component
    % specific CreateFunctions with an empty HANDLES structure.

    
    % Do feval on layout code in m-file if it exists
    gui_Exported = ~isempty(gui_State.gui_LayoutFcn);
    % this application data is used to indicate the running mode of a GUIDE
    % GUI to distinguish it from the design mode of the GUI in GUIDE. it is
    % only used by actxproxy at this time.   
    setappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]),1);
    if gui_Exported
        gui_hFigure = feval(gui_State.gui_LayoutFcn, gui_SingletonOpt);

        % make figure invisible here so that the visibility of figure is
        % consistent in OpeningFcn in the exported GUI case
        if isempty(gui_VisibleInput)
            gui_VisibleInput = get(gui_hFigure,'Visible');
        end
        set(gui_hFigure,'Visible','off')

        % openfig (called by local_openfig below) does this for guis without
        % the LayoutFcn. Be sure to do it here so guis show up on screen.
        movegui(gui_hFigure,'onscreen');
    else
        gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        % If the figure has InGUIInitialization it was not completely created
        % on the last pass.  Delete this handle and try again.
        if isappdata(gui_hFigure, 'InGUIInitialization')
            delete(gui_hFigure);
            gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        end
    end
    if isappdata(0, genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]))
        rmappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]));
    end

    % Set flag to indicate starting GUI initialization
    setappdata(gui_hFigure,'InGUIInitialization',1);

    % Fetch GUIDE Application options
    gui_Options = getappdata(gui_hFigure,'GUIDEOptions');
    % Singleton setting in the GUI MATLAB code file takes priority if different
    gui_Options.singleton = gui_State.gui_Singleton;

    if ~isappdata(gui_hFigure,'GUIOnScreen')
        % Adjust background color
        if gui_Options.syscolorfig
            set(gui_hFigure,'Color', get(0,'DefaultUicontrolBackgroundColor'));
        end

        % Generate HANDLES structure and store with GUIDATA. If there is
        % user set GUI data already, keep that also.
        data = guidata(gui_hFigure);
        handles = guihandles(gui_hFigure);
        if ~isempty(handles)
            if isempty(data)
                data = handles;
            else
                names = fieldnames(handles);
                for k=1:length(names)
                    data.(char(names(k)))=handles.(char(names(k)));
                end
            end
        end
        guidata(gui_hFigure, data);
    end

    % Apply input P/V pairs other than 'visible'
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        len1 = min(length('visible'),length(varargin{index}));
        if ~strncmpi(varargin{index},'visible',len1)
            try set(gui_hFigure, varargin{index}, varargin{index+1}), catch break, end
        end
    end

    % If handle visibility is set to 'callback', turn it on until finished
    % with OpeningFcn
    gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
    if strcmp(gui_HandleVisibility, 'callback')
        set(gui_hFigure,'HandleVisibility', 'on');
    end

    feval(gui_State.gui_OpeningFcn, gui_hFigure, [], guidata(gui_hFigure), varargin{:});

    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        % Handle the default callbacks of predefined toolbar tools in this
        % GUI, if any
        guidemfile('restoreToolbarToolPredefinedCallback',gui_hFigure); 
        
        % Update handle visibility
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);

        % Call openfig again to pick up the saved visibility or apply the
        % one passed in from the P/V pairs
        if ~gui_Exported
            gui_hFigure = local_openfig(gui_State.gui_Name, 'reuse',gui_Visible);
        elseif ~isempty(gui_VisibleInput)
            set(gui_hFigure,'Visible',gui_VisibleInput);
        end
        if strcmpi(get(gui_hFigure, 'Visible'), 'on')
            figure(gui_hFigure);
            
            if gui_Options.singleton
                setappdata(gui_hFigure,'GUIOnScreen', 1);
            end
        end

        % Done with GUI initialization
        if isappdata(gui_hFigure,'InGUIInitialization')
            rmappdata(gui_hFigure,'InGUIInitialization');
        end

        % If handle visibility is set to 'callback', turn it on until
        % finished with OutputFcn
        gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
        if strcmp(gui_HandleVisibility, 'callback')
            set(gui_hFigure,'HandleVisibility', 'on');
        end
        gui_Handles = guidata(gui_hFigure);
    else
        gui_Handles = [];
    end

    if nargout
        [varargout{1:nargout}] = feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    else
        feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    end

    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
    end
end

function gui_hFigure = local_openfig(name, singleton, visible)

% openfig with three arguments was new from R13. Try to call that first, if
% failed, try the old openfig.
if nargin('openfig') == 2
    % OPENFIG did not accept 3rd input argument until R13,
    % toggle default figure visible to prevent the figure
    % from showing up too soon.
    gui_OldDefaultVisible = get(0,'defaultFigureVisible');
    set(0,'defaultFigureVisible','off');
    gui_hFigure = matlab.hg.internal.openfigLegacy(name, singleton);
    set(0,'defaultFigureVisible',gui_OldDefaultVisible);
else
    % Call version of openfig that accepts 'auto' option"
    gui_hFigure = matlab.hg.internal.openfigLegacy(name, singleton, visible);  
%     %workaround for CreateFcn not called to create ActiveX
%         peers=findobj(findall(allchild(gui_hFigure)),'type','uicontrol','style','text');    
%         for i=1:length(peers)
%             if isappdata(peers(i),'Control')
%                 actxproxy(peers(i));
%             end            
%         end
end

function result = local_isInvokeActiveXCallback(gui_State, varargin)

try
    result = ispc && iscom(varargin{1}) ...
             && isequal(varargin{1},gcbo);
catch
    result = false;
end

function result = local_isInvokeHGCallback(gui_State, varargin)

try
    fhandle = functions(gui_State.gui_Callback);
    result = ~isempty(findstr(gui_State.gui_Name,fhandle.file)) || ...
             (ischar(varargin{1}) ...
             && isequal(ishghandle(varargin{2}), 1) ...
             && (~isempty(strfind(varargin{1},[get(varargin{2}, 'Tag'), '_'])) || ...
                ~isempty(strfind(varargin{1}, '_CreateFcn'))) );
catch
    result = false;
end


