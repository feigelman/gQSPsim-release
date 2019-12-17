clear
clc
close all
mycurfullpathwithfilename = mfilename('fullpath'); 
mycurfilename = mfilename(); 
mycurfullpath = erase(mycurfullpathwithfilename, mycurfilename); 
mysessionfullpath = erase(mycurfullpath,'Plotting_validation\');
mySimResultsfullpath = [mysessionfullpath,'SimResults\']; 


[file1040, path1040] = uigetfile([mySimResultsfullpath,'*validation*.mat'], 'Select simulation results for 40mg (no statin) group:');  
[file2040, path2040] = uigetfile([mySimResultsfullpath,'*validation*.mat'], 'Select simulation results for 40mg (with statin) group:');  
[file1150, path1150] = uigetfile([mySimResultsfullpath,'*validation*.mat'], 'Select simulation results for 150mg (no statin) group:');  
[file2150, path2150] = uigetfile([mySimResultsfullpath,'*validation*.mat'], 'Select simulation results for 150mg (with statin) group:');  

%reading the clinical data file
T_data = readtable([mysessionfullpath,'DataFiles\data_modelvalidation.xlsx']); 

data_plot_marker = 'k.'; 
count = 0; 
for resulttype = [1]
    count = count + 1; 
    if resulttype == 1
        %% Paper cohort
        Sim_1040 = load([path1040, file1040]);
        Sim_2040 = load([path2040, file2040]);
        Sim_1150 = load([path1150, file1150]);
        Sim_2150 = load([path2150, file2150]);
%         vpop_para = readtable('..\VPopFiles\cohort_para_paper_gQSPsim_run_statin.xlsx'); 
        shadecolor = [0.8 0.8 0.8]; linecolor = 'k-'; 
        legendentry = 'Paper';
    
    end

axislabel_fontsize = 20; 
ticklabel_fontsize = 18; 
F1 = figure(1);
set(F1, 'Position', [1 1 1200 900])
subplot(2,2,1)
[time, LDLp, w0] = extract_time_LDLp(Sim_1040.Results);
% plot_prctile(time,LDLp, 10, 90, shadecolor, linecolor)
weightedQuantilePlot(time, LDLp, w0, shadecolor)       ;
hold on
plot(T_data.Time(T_data.Group==1040), T_data.LDLp(T_data.Group==1040), data_plot_marker)
xlim([-100 120])
ylim([0 300])

set(gca,'fontsize',ticklabel_fontsize,'FontWeight','bold')
xlabel('Time (days)', 'FontSize', axislabel_fontsize, 'FontWeight', 'normal')
ylabel('LDL (% of baseline)', 'FontSize', axislabel_fontsize, 'FontWeight', 'normal')
grid on

subplot(2,2,2)
[time, LDLp, w0] = extract_time_LDLp(Sim_2040.Results);
% plot_prctile(time,LDLp, 10, 90, shadecolor, linecolor)
weightedQuantilePlot(time, LDLp, w0, shadecolor) ;
hold on
plot(T_data.Time(T_data.Group==2040), T_data.LDLp(T_data.Group==2040), data_plot_marker)
xlim([-100 120])
ylim([0 300])

set(gca,'fontsize',ticklabel_fontsize,'FontWeight','bold')
xlabel('Time (days)', 'FontSize', axislabel_fontsize, 'FontWeight', 'normal')
ylabel('LDL (% of baseline)', 'FontSize', axislabel_fontsize, 'FontWeight', 'normal')
grid on

subplot(2,2,3)
[time, LDLp, w0] = extract_time_LDLp(Sim_1150.Results);
% plot_prctile(time,LDLp, 10, 90, shadecolor, linecolor)
weightedQuantilePlot(time, LDLp, w0, shadecolor) ;
hold on
plot(T_data.Time(T_data.Group==1150), T_data.LDLp(T_data.Group==1150), data_plot_marker)
xlim([-100 120])
ylim([0 300])
xlabel('Time (days)')
ylabel('LDL (% of baseline)')

set(gca,'fontsize',ticklabel_fontsize,'FontWeight','bold')
xlabel('Time (days)', 'FontSize', axislabel_fontsize, 'FontWeight', 'normal')
ylabel('LDL (% of baseline)', 'FontSize', axislabel_fontsize, 'FontWeight', 'normal')
grid on

subplot(2,2,4)
[time, LDLp, w0] = extract_time_LDLp(Sim_2150.Results);
% plot_prctile(time,LDLp, 10, 90, shadecolor, linecolor)
weightedQuantilePlot(time, LDLp, w0, shadecolor) ;
hold on
plot(T_data.Time(T_data.Group==2150), T_data.LDLp(T_data.Group==2150), data_plot_marker)
xlim([-100 120])
ylim([0 300])
xlabel('Time (days)')
ylabel('LDL (% of baseline)')

set(gca,'fontsize',ticklabel_fontsize,'FontWeight','bold')
xlabel('Time (days)', 'FontSize', axislabel_fontsize, 'FontWeight', 'normal')
ylabel('LDL (% of baseline)', 'FontSize', axislabel_fontsize, 'FontWeight', 'normal')
grid on

annotation('textbox', [0.05, 1, 0, 0], 'string', 'A' ,'FontSize', axislabel_fontsize)
annotation('textbox', [0.55, 1, 0, 0], 'string', 'B' ,'FontSize', axislabel_fontsize)
annotation('textbox', [0.05, 0.5, 0, 0], 'string', 'C' ,'FontSize', axislabel_fontsize)
annotation('textbox', [0.55, 0.5, 0, 0], 'string', 'D' ,'FontSize', axislabel_fontsize)

% if count == 1 
%     ParaName_Plot_List = vpop_para.Properties.VariableNames; 
% else
%     
% end
% figure(2)
% for i = 1:length(ParaName_Plot_List)
%     curParaName = ParaName_Plot_List(i);
%     curParaToHist = table2array(vpop_para(:,strcmp(vpop_para.Properties.VariableNames, curParaName))); 
%     if isempty(curParaToHist) == 1
%         continue
%     end
%     subplot(5,5,i)
%     hold on
%     histogram(curParaToHist, 10, 'FaceColor', shadecolor)
%     title(curParaName)
% end

legend_ary{count} = legendentry; 
end
% figure(1)
% subplot(2,2,1); legend(legend_ary); 
% figure(2)
% subplot(5,5,20); legend(legend_ary);





% saveas(figure(1),'Validation_v1.tif')










%% Functions
function [time, LDLp, w0] = extract_time_LDLp(Results)
[npts_time, datalength] = size(Results.Data); 
n_species = length(Results.SpeciesNames); 
n_vs = datalength/n_species; 
vs_id = 1:n_vs; 

if isempty(Results.VpopWeights) == 1
    w0 = ones(n_vs,1).*1./n_vs; 
else
    w0 = Results.VpopWeights; 
end

time = Results.Time - 100; 
LDLch = Results.Data(:,(vs_id-1).*n_species + find(strcmp('LDLch', Results.SpeciesNames)==1)); 
LDL_baseline = LDLch(time==0,:); 

LDLp = LDLch./repmat(LDL_baseline,npts_time,1).*100; 
end

function plot_prctile(x,y, prctile_lo, prctile_hi, shadecolor, linecolor)
data_hi = prctile(y,prctile_hi,2);
data_lo = prctile(y,prctile_lo,2);
data_median = prctile(y,50,2);

hold on
H1 = fill([x',fliplr(x')], [data_hi', fliplr(data_lo')], shadecolor);
H1.FaceAlpha = 0.5; H1.LineStyle = 'none';

plot(x,data_median,linecolor)

end