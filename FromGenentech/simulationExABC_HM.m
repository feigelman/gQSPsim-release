%% Simulation example

%% Task 1 (Backend)
addpath('app')
tObj = QSP.Task;

ProjectPath = fullfile(pwd,'models','ABC.sbproj');
ModelName = 'ABC';
[StatusOK,Message] = importModel(tObj,ProjectPath,ModelName);

tObj.Name = 'Task 1';
tObj.Description = 'Simple ABC Model';        
tObj.ActiveSpeciesNames = {'A'; 'B'; 'C'};
tObj.ActiveVariantNames = {'Var1','Var2'};
tObj.ActiveDoseNames = {};
tObj.ConfigSet.SolverOptions.OutputTimes = [0;0.005;0.05;0.5;1;1.5;2;2.5;5;10;15;25;30;40;50];
tObj.RunToSteadyState = true;
tObj.TimeToSteadyState = 100;

if StatusOK
    Summary = getSummary(tObj);
    disp(Summary);
    
    [ThisStatusOK,ThisMessage] = validate(tObj,false);
    ThisStatusOK
    ThisMessage
end
% IH: we should have a valid task object at this point


%% Virtual Population (Backend)
vObj = QSP.VirtualPopulation;
vObj.Name = 'ABC_vpop';
% VpopPath = fullfile(pwd,'vpop','ABC_vpop.xlsx');
VpopPath = fullfile(pwd,'results','Results - Optimization = ABC Optimization - Date = 04-Aug-2016_11-34-23.xls');
[StatusOK,Message] = importData(vObj,VpopPath);


%% Create Settings obj (Backend)
% IH: Simulation does not require Params, Vpop Data, or Optim Data
% IH: Optim Data is needed for visualizations
sObj = QSP.Settings;
sObj.Task = tObj;
sObj.VirtualPopulation = vObj;

% would be chosen in the GUI?
sObj.RootDirectory = pwd;


%% Virtual Population Data (Backend)
% vdObj = QSP.VirtualPopulationData;


%% Create Simulation obj (Backend)
simObj = QSP.Simulation('Settings',sObj);
simObj.Name = 'ABC sim';
simObj.RelativeFilePath = simObj.Settings.RootDirectory;
ResultsPath = fullfile(pwd,'results');
simObj.SimResultsFolderName = ResultsPath;

% create simulation items
for i = 1:length(simObj.Settings.Task)
    simItem(i) = QSP.TaskVirtualPopulation;
    simItem(i).TaskName = simObj.Settings.Task(i).Name;
    simItem(i).VPopName = simObj.Settings.VirtualPopulation(i).Name;
end

simObj.Item = simItem;

tic
run(simObj);
toc


%% Summary (FrontEnd)

fig = figure;
AllItems = tObj.getSummary;
w = uix.widget.Summary('Parent',fig,'AllItems',AllItems);

%% ListBuilder (FrontEnd)

AllItems = {'Alpha';'Bravo';'Charlie';'Delta';'Echo';'Foxtrot'};
AddedIndex = 2:numel(AllItems);
fig = figure;
w = uix.widget.ListBuilder('Parent',fig,'AllItems',AllItems,'AddedIndex',AddedIndex);

