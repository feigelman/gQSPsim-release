%% VpopGen example

%% Task 1 (Backend)
addpath('app')
tObj_1 = QSP.Task;

ProjectPath = fullfile(pwd,'models','ABC.sbproj');
ModelName = 'ABC';
[StatusOK,Message] = importModel(tObj_1,ProjectPath,ModelName);

tObj_1.Name = 'Task 1';
tObj_1.Description = 'Simple ABC Model';        
tObj_1.ActiveSpeciesNames = {'A'; 'B'; 'C'};
tObj_1.ActiveVariantNames = {};
tObj_1.ActiveDoseNames = {'Dose 1'};
tObj_1.ConfigSet.SolverOptions.OutputTimes = [0.0, 0.05, 0.5, 1.0, 1.5, 2.0, 2.5, 5.0, 10.0, 15.0, 24.0, 25.0, 25.5, 26.0, 26.5, 27.0, 28.0, 30.0, 40.0, 50.0];
tObj_1.RunToSteadyState = false;

if StatusOK
    Summary = getSummary(tObj_1);
    disp(Summary);
    
    [ThisStatusOK,ThisMessage] = validate(tObj_1,false);
    ThisStatusOK
    ThisMessage
end

%% Task 2 (Backend)
addpath('app')
tObj_2 = QSP.Task;

ProjectPath = fullfile(pwd,'models','ABC.sbproj');
ModelName = 'ABC';
[StatusOK,Message] = importModel(tObj_2,ProjectPath,ModelName);

tObj_2.Name = 'Task 2';
tObj_2.Description = 'Simple ABC Model';        
tObj_2.ActiveSpeciesNames = {'A'; 'B'; 'C'};
tObj_2.ActiveVariantNames = {};
tObj_2.ActiveDoseNames = {};
tObj_2.ConfigSet.SolverOptions.OutputTimes = [0;5.00E-04;0.005;0.05;0.1;0.15;0.2;0.25;0.5;1;1.5;2.5;3;4;5];
tObj_2.RunToSteadyState = false;

if StatusOK
    Summary = getSummary(tObj_2);
    disp(Summary);
    
    [ThisStatusOK,ThisMessage] = validate(tObj_2,false);
    ThisStatusOK
    ThisMessage
end



%% Virtual Population (Backend)


%% Parameters (Backend)
pObj = QSP.Parameters;
pObj.Name = 'ABC Params';
pObj.RelativeFilePath = fullfile(pwd,'data','ABCparameters.xlsx');


%% Virtual Population Data (Backend)
vdObj = QSP.VirtualPopulationData;
vdObj.Name = 'ABC_Acceptance_Criteria_Dose';
vdObj.RelativeFilePath = fullfile(pwd,'data','ABC_Acceptance_Criteria_Dose');


%% Optimization Data (Backend)
% oObj = QSP.OptimizationData;
% oObj.FatTallDataset = false;
% oObj.Name = 'ABC Data';
% oObj.RelativeFilePath = fullfile(pwd,'data','ABCdata.xlsx');


%% Create Settings obj (Backend)
% IH: Simulation does not require Params, Vpop Data, or Optim Data
% IH: Optim Data is needed for visualizations
sObj = QSP.Settings;
sObj.Task = [tObj_1;tObj_2];
% sObj.VirtualPopulation = vObj;

sObj.Parameters = pObj;
% sObj.OptimizationData = oObj;
% sObj.VirtualPopulationData = vdObj;

% would be chosen in the GUI?
sObj.RootDirectory = pwd;
ResultsPath = fullfile(pwd,'results');
% sObj.ResultsFolder = ResultsPath; % What is this for?


%% Create and Run VpopGen object
vPopGenObj = QSP.VirtualPopulationGeneration('Settings',sObj);
vPopGenObj.Name = 'ABC Vpop Gen, Dose';
% vPopGenObj.RelativeFilePath = fullfile(pwd,'vpop');
vPopGenObj.VPopResultsFolderName = fullfile(pwd,'vpop');
vPopGenObj.Data = vdObj;
vPopGenObj.RefParam = pObj;

% create optimization item (task-group pair)
vpopItemObj_1 = QSP.TaskGroup;
vpopItemObj_1.TaskName = 'Task 1';
vpopItemObj_1.GroupID = '1';
vpopItemObj_2 = QSP.TaskGroup;
vpopItemObj_2.TaskName = 'Task 2';
vpopItemObj_2.GroupID = '2';
vPopGenObj.Item = [vpopItemObj_1;vpopItemObj_2];

% create species-data pairing
for i = 1:3
    speciesDataObj(i) = QSP.SpeciesData;
end
speciesDataObj(1).SpeciesName = 'A';
speciesDataObj(1).DataName = 'A';
speciesDataObj(1).FunctionExpression = 'x';
speciesDataObj(2).SpeciesName = 'B';
speciesDataObj(2).DataName = 'B';
speciesDataObj(2).FunctionExpression = 'x';
speciesDataObj(3).SpeciesName = 'C';
speciesDataObj(3).DataName = 'C';
speciesDataObj(3).FunctionExpression = 'x';
vPopGenObj.SpeciesData = speciesDataObj;


% run vpop generation
tic
run(vPopGenObj);
toc




%% Summary (FrontEnd)

fig = figure;
AllItems = tObj_1.getSummary;
w = uix.widget.Summary('Parent',fig,'AllItems',AllItems);

%% ListBuilder (FrontEnd)

AllItems = {'Alpha';'Bravo';'Charlie';'Delta';'Echo';'Foxtrot'};
AddedIndex = 2:numel(AllItems);
fig = figure;
w = uix.widget.ListBuilder('Parent',fig,'AllItems',AllItems,'AddedIndex',AddedIndex);

