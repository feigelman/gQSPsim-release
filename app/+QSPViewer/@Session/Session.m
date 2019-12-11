classdef Session < uix.abstract.CardViewPane
    % Session - View Pane for the object
    % ---------------------------------------------------------------------
    % Display a viewer/editor for the object
    %

    
    %   Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 259 $
    %   $Date: 2016-08-24 16:03:36 -0400 (Wed, 24 Aug 2016) $
    % ---------------------------------------------------------------------
  
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);        
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = Session(varargin)
            
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
        
        function delete(obj)
            % Destructor
            hTimer = timerfindall('Tag','QSPtimer');
            if ~isempty(hTimer)
                stop(hTimer)
                delete(hTimer)
            end
        end
        
    end %methods
    
    
    %% Callbacks
    methods
        
        function onFileSelection(vObj,h,evt) %#ok<*INUSD>
            
            % Which field was modified?
            Field = h.Tag;
            
            % Update the value, and trap errors
            try
                vObj.TempData.(Field) = evt.NewValue;
            catch err
                hDlg = errordlg(err.message,Field,'modal');
                uiwait(hDlg);
            end
            
            % Update the view
            update(vObj);
            
        end %function
        
        function onUDFSelection(vObj,h,evt)
            
            % remove old path
            removeUDF(vObj.TempData);
            
            % assign value & refresh
            onFileSelection(vObj,h,evt);
           
            % add new path
            addUDF(vObj.TempData);
        end %function
        
        function onParallelCheckbox(vObj,h,evt)
            vObj.TempData.UseParallel = h.Value;
            if ~vObj.TempData.UseParallel
                set(vObj.h.ParallelCluster, 'Enable', 'off')
            else
                set(vObj.h.ParallelCluster, 'Enable', 'on')
                if iscell(vObj.h.ParallelCluster.String)
                    if isempty(vObj.h.ParallelCluster.String)
                        vObj.h.ParallelCluster.String = parallel.clusterProfiles;
                    end
                    vObj.TempData.ParallelCluster = vObj.h.ParallelCluster.String{vObj.h.ParallelCluster.Value};
                else
                    vObj.TempData.ParallelCluster = vObj.h.ParallelCluster.String;
                end
            end
        end %function
        
        function onAutosaveTimerCheckbox(vObj,h,evt)
            vObj.TempData.UseAutoSaveTimer = logical(h.Value);
            if ~vObj.TempData.UseAutoSaveTimer
                set(vObj.h.AutoSaveFrequencyEdit, 'Enable', 'off')
            else
                set(vObj.h.AutoSaveFrequencyEdit, 'Enable', 'on')               
            end
            
            update(vObj);
            
        end %function        
        
        function onParallelClusterPopup(vObj,h,evt)
            vObj.TempData.ParallelCluster = h.String{h.Value};
        end %function
        
        function onAutoSaveFrequencyEdited(vObj,h,~) %#ok<*INUSD>
            
            % Update the value, and trap errors
            Field = 'AutoSaveFrequency';
            try
                vObj.TempData.AutoSaveFrequency = str2double(get(h,'String'));
            catch err
                hDlg = errordlg(err.message,Field,'modal');
                uiwait(hDlg);
            end
            
            % Update the view
            update(vObj);
            
        end %function
        
        function onAutoSaveBeforeRunChecked(vObj,h,~)
            
            vObj.TempData.AutoSaveBeforeRun = logical(h.Value);
            
            % Update the view
            update(vObj);
            
        end %function        
        
        function onButtonPress(vObj,h,e)
            
            ThisTag = get(h,'Tag');
            
            % remove old path
            removeUDF(vObj.TempData);
            
            % Stop and delete vObj.TempData (temporary) timer - BEFORE
            % Session copy, since no custom copy operation exists for
            % timer. Note, re-initialization happens for vObj.Data below
            deleteTimer(vObj.TempData);
            deleteTimer(vObj.Data);
            
            % Invoke superclass's onButtonPress
            onButtonPress@uix.abstract.CardViewPane(vObj,h,e);
            
            % add new path
            addUDF(vObj.TempData);
            
            % Re-initialize vObj.Data's timer
            initializeTimer(vObj.Data);
                        
            switch ThisTag
                case 'Save'
                    try
                        % Refresh data (no need to refresh data for auto-save path
                        % change)
                        refreshData(vObj.Data.Settings);
                        
                        % Stop to set the period and start delay
                        if strcmpi(vObj.Data.timerObj.Running,'on')
                            stop(vObj.Data.timerObj)
                        end
                        vObj.Data.timerObj.Period = vObj.Data.AutoSaveFrequency * 60; % minutes
                        vObj.Data.timerObj.StartDelay = 0; % Reduce start delay
                        % Only restart if UseAutoSave is true
                        if vObj.Data.UseAutoSaveTimer
                            start(vObj.Data.timerObj)
                        end
                        
                        % check if the parallel pool needs to be changed
                        
                    catch err

                        hDlg = errordlg(err.message,'modal');
                        uiwait(hDlg);
                    end
            end
        end %function        
        
    end %methods

end %classdef