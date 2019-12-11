classdef VirtualPopulationGenerationData < uix.abstract.CardViewPane
   
    
%% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);        
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = VirtualPopulationGenerationData(varargin)
            
            % Call superclass constructor
            RunVis = false;
            obj = obj@uix.abstract.CardViewPane(RunVis,varargin{:});
            
            % Create the graphics objects
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Mark construction complete to tell refresh the graphics exist
            obj.IsConstructed = true;
            
            % Refresh the view
            obj.refresh();
            
        end
        
    end %methods
    
    
    %RAJ - for callbacks:
    %notify(obj, 'DataEdited', <eventdata>);

    
    %% Callbacks
    methods
        
        function onFileSelection(vObj,h,e) %#ok<*INUSD>
            % Select file
            
            % Get string
            DataFilePath = e.NewValue;
            
            % Update the relative file path
            vObj.TempData.RelativeFilePath = DataFilePath;
            
            if exist(vObj.TempData.FilePath,'file')==2
                
                [StatusOK,Message] = importData(vObj.TempData, vObj.TempData.FilePath);
                if ~StatusOK
                    hDlg = errordlg(Message,'Error on Import','modal');
                    uiwait(hDlg);
                end
                
            end
            
            % Update the view
            update(vObj);
            
        end %function

        function onFileNewPress(vObj,h,e)
            % copy the template into the root directory and open it
            rootdir = vObj.Data.Session.RootDirectory;
            proceed = questdlg(sprintf('This will create a new Target Statistics file in %s. Proceed?', rootdir), 'Confirm new file creation', 'Yes');
            if strcmp(proceed,'Yes')
                try
                    appRoot = fullfile(fileparts(mfilename('fullpath')), '..', '..', '..', 'templates');
                    
                    rootFiles = dir(fullfile(rootdir, '*.xlsx'));                    
                    rootFiles = cellfun(@(f) strrep(f, '.xlsx', ''), {rootFiles.name}, 'UniformOutput', false);

                    newFile = [matlab.lang.makeUniqueStrings('TargetStatistics', rootFiles), '.xlsx'];
                    copyfile( fullfile(appRoot, 'TargetStatistics_Template.xlsx'), fullfile(rootdir, newFile) )
                    
                    if ispc
                        winopen(fullfile(rootdir,newFile))
                    else
                        system(sprintf('open "%s"', fullfile(rootdir,newFile)) )
                    end
                catch err
                    errordlg(sprintf('Error encountered creating new file: %s', err.message) )
                    return
                end
                
                vObj.TempData.RelativeFilePath = newFile ;
                
                update(vObj);
                
            end
            
        end        
        
    end
    
end

