function varargout = QSPapp()

if verLessThan('matlab','9.4') || ~verLessThan('matlab','9.5') % If version < R2018a (9.4) or >= R2018b (9.5)
    ThisVer = ver('matlab');
    warning('gQSPSim has been tested in MATLAB R2018a (9.4). This MATLAB release %s may not be supported for gQSPSim',ThisVer.Release);
end

EchoOutput = true;

warning('off','uix:ViewPaneManager:NoView')
warning('off','MATLAB:table:ModifiedAndSavedVarnames');
warning('off','MATLAB:Axes:NegativeDataInLogAxis')
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')

if ~isdeployed
    
    % Verify GUI Layout Toolbox
    if isempty(ver('layout')) || verLessThan('layout','2.1')
        
        % Toolbox is missing. Prompt to download
        hDlg = errordlg(['<html>Unable to locate GUI Layout Toolbox 2.1 or '...
            'greater. Please find and install "GUI Layout Toolbox" on '...
            'the MATLAB Add-On Explorer or File Exchange. '],...
            'WindowStyle','modal');
        uiwait(hDlg);
        
        if verLessThan('matlab','R2015b')
            % Launch Web Browser to GUI Layout Toolbox  (prior to R2016a)
            web('https://www.mathworks.com/matlabcentral/fileexchange/47982','-browser');
        elseif verLessThan('matlab','R2016a')
            % Launch Add-On Browser to GUI Layout Toolbox (R2016a only)
            matlab.internal.language.introspective.showAddon('e5af5a78-4a80-11e4-9553-005056977bd0');
        else
            % Launch Add-On Browser to GUI Layout Toolbox
            com.mathworks.addons.AddonsLauncher.showDetailPageInExplorerFor('e5af5a78-4a80-11e4-9553-005056977bd0','AO_CONSULTING')
        end
        
    end
       
    if isempty(mex.getCompilerConfigurations('C','Supported'))
        hDlg = errordlg(['Unable to locate C compiler. Please install a compatible compiler before launching. '...
            'See www.mathworks.com for more details.'],...
            'WindowStyle','modal');
        uiwait(hDlg);
        return
    end


    
end %if ~isdeployed


% Get the root directory, based on the path of this file
filename = mfilename('fullpath');
filename = regexprep(filename, 'gQSPsim/app/(\.\./app)+', 'gQSPsim/app');
filename = strrep(filename , '/../app', '');

RootPath = fileparts(filename);


%% Set up the paths to add to the MATLAB path

%************ EDIT BELOW %************

% The true/false argument specifies whether the given directory should
% include children (true) or just itself (false)

rootDirs={...
    fullfile(RootPath,'..','app'),true;... %root folder with children
    fullfile(RootPath,'..','utilities'),true;... %root folder with children
    fullfile(RootPath,'..','FromGenentech'),true;... %root folder with children
    
    };

%************ EDIT ABOVE %************

pathCell = regexp(path, pathsep, 'split');

%% Loop through the paths and add the necessary subfolders to the MATLAB path
for pCount = 1:size(rootDirs,1)
    
    rootDir=rootDirs{pCount,1};
    if rootDirs{pCount,2}
        % recursively add all paths
        rawPath=genpath(rootDir);
        rawPathCell=textscan(rawPath,'%s','delimiter',';');
        rawPathCell=rawPathCell{1};
        
    else
        % Add only that particular directory
        rawPath = rootDir;
        rawPathCell = {rawPath};
    end
    
    % remove undesired paths
    svnFilteredPath=strfind(rawPathCell,'.svn');
    slprjFilteredPath=strfind(rawPathCell,'slprj');
    sfprjFilteredPath=strfind(rawPathCell,'sfprj');
    rtwFilteredPath=strfind(rawPathCell,'_ert_rtw');
    
    % loop through path and remove all the .svn entries
    for pCount=1:length(svnFilteredPath), %#ok<FXSET>
        filterCheck=[svnFilteredPath{pCount},...
            slprjFilteredPath{pCount},...
            sfprjFilteredPath{pCount},...
            rtwFilteredPath{pCount}];
        if isempty(filterCheck)
            if EchoOutput
                disp(['Adding ',rawPathCell{pCount}]);
            end
            if ispc  % Windows is not case-sensitive
                if ~any(strcmpi(rawPathCell{pCount}, pathCell))
                    addpath(rawPathCell{pCount}); %#ok<MCAP>
                end
            else
                if ~any(strcmp(rawPathCell{pCount}, pathCell))
                    addpath(rawPathCell{pCount}); %#ok<MCAP>
                end
            end
        else
            % ignore
        end
    end
    
end



%% Add java class paths

% Disable warnings
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')
warning('off','MATLAB:Java:DuplicateClass');
warning('off','MATLAB:javaclasspath:jarAlreadySpecified')

if EchoOutput
    disp('Initializing Java paths for UI Widgets');
    disp('---------------------------------------------------');
end

% Tree controls and XLWRITE
Paths = {
    fullfile(RootPath,'+uix','+resource','UIExtrasTable.jar')
    fullfile(RootPath,'+uix','+resource','UIExtrasTree.jar')
    fullfile(RootPath,'20130227_xlwrite','poi_library','poi-3.8-20120326.jar')
    fullfile(RootPath,'20130227_xlwrite','poi_library','poi-ooxml-3.8-20120326.jar')
    fullfile(RootPath,'20130227_xlwrite','poi_library','poi-ooxml-schemas-3.8-20120326.jar')
    fullfile(RootPath,'20130227_xlwrite','poi_library','xmlbeans-2.3.0.jar')
    fullfile(RootPath,'20130227_xlwrite','poi_library','dom4j-1.6.1.jar')
    fullfile(RootPath,'20130227_xlwrite','poi_library','stax-api-1.0.1.jar')
    };

% Display
fprintf('%s\n',Paths{:});

% Add paths
javaaddpath(Paths);

if EchoOutput
    disp('---------------------------------------------------');
end

% run the units script
units

if nargout == 1
    varargout{1} = QSPViewer.App();
else
    QSPViewer.App();
end

end
