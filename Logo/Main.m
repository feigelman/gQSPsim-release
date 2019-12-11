function Main
logo_gQSPSim
end

function logo_gQSPSim
clear all
close all
load QSP_Sim.mat

set(gcf, 'Position', [1 1 700 700]);
set(gcf, 'PaperPositionMode', 'auto');

for ii = 1 : 100
    plot(0:0.1:28, Xsim_ary(:, (ii-1)*3+3), 'LineWidth', 5, 'Color', [77 190 238]/255)
    alpha(0.1)
    hold on
end

t = [0 0.1 0.2 1 3 7 14 21];
LB = [383.96 399.81 415.00 529.17 731.03 898.81 970.95 977.03]
UB = [742.51 790.51 833.47 1256.27 2238.40 3910.94 5407.40 5377.09]
plot(t, LB, 'LineStyle', 'none', 'Marker', 'h', ...
    'MarkerEdgeColor', 'k', ...
    'MarkerFaceColor', 'k', ...
    'MarkerSize', 60);
hold on
plot(t, UB, 'LineStyle', 'none', 'Marker', 'h', ...
    'MarkerEdgeColor', 'k', ...
    'MarkerFaceColor', 'k', ...
    'MarkerSize', 60);

ylim([0, 10000]);
xlim([0, 25]);
set(gca, 'XTickLabels', '');
set(gca, 'YTickLabels', '');
set(gca, 'Linewidth', 24);
set(gca, 'Ticklength', [0, 0]);
set(gca, 'Color', [225, 225, 225]/255);
set(gcf, 'Color', [225, 225, 225]/255);
set(gca, 'XColor', [96, 96, 96]/255);
set(gca, 'YColor', [96, 96, 96]/255);
set(gcf, 'InvertHardcopy', 'off');
text(9.9, 9000, '1.3', 'FontSize', 250, 'FontWeight', 'bold', 'color', 'k')

box off
print(gcf, '-loose', '-dtiff', '-r150', 'QSP_logo_v2.tiff')
print(gcf, '-loose', '-dpng', '-r150', 'QSP_logo_v2.png')

end

function logo_gPKPDSim

clear all
close all
t = [0.003 0.042 0.167 0.333 1 2 8 8.003 8.333 9 10 15 22 29 36 43];
d = [39.457 24.517 15.961 11.510 7.129 4.478 1.812 34.558 12.703 7.718 5.902 2.745 1.274 0.557 0.232 0.100];
load res.mat

set(gcf, 'Position', [1 1 700 700]);
set(gcf, 'PaperPositionMode', 'auto');
    
semilogy(res.Time, res.CentralConcmcgmL, 'LineWidth', 50, 'Color', [77 190 238]/255);
semilogy(res.Time, res.CentralConcmcgmL, 'LineWidth', 50, 'Color', [51 153 255]/255);

hold on
semilogy(res.Time, res.PeriConcmcgmL*1.9, 'LineWidth', 50, 'Color', 'r');

semilogy(t, d, 'LineStyle', 'none', 'Marker', 'h', ...
    'MarkerEdgeColor', 'k', ...
    'MarkerFaceColor', 'k', ...
    'MarkerSize', 60);
ylim([10^0, 10^2]);
xlim([0, 25]);
set(gca, 'XTickLabels', '');
set(gca, 'YTickLabels', '');
set(gca, 'Linewidth', 24);
set(gca, 'Ticklength', [0, 0]);
set(gca, 'Color', [225, 225, 225]/255);
set(gcf, 'Color', [225, 225, 225]/255);
set(gca, 'XColor', [96, 96, 96]/255);
set(gca, 'YColor', [96, 96, 96]/255);
set(gcf, 'InvertHardcopy', 'off');

text(11.5, 60, '1.1', 'FontSize', 250, 'FontWeight', 'bold')

box off

% print(gcf, '-loose', '-dtiff', '-r150', 'logo_v2.tiff')
% print(gcf, '-loose', '-dpng', '-r150', 'logo_v2.png')

end