clc, clear all, close all

% load time series data from csv
% chop off the header row and date column so we just have numbers
% column 4 and 7 contain emmplrate and rulc, respectively 
M = csvread('bizCycleData.csv', 1, 1);
%x = 1:size(M,1);
x = 1948:0.25:2014.25; % 1948 Q1 through 2014 Q2 

% TIME SERIES of interest 
emplrate = M(:,4);
rulc = M(:,7);
diff_emplrate = diff(emplrate);
diff_rulc = diff(rulc);

% plot them 
figure
[ax,p1,p2] = plotyy(x, emplrate, x(2:end), diff_emplrate)
ylabel(ax(1),'emplrate') 
ylabel(ax(2),'diff(emplrate)')
xlabel(ax(2),'Year')
set(p1, 'LineWidth', 2)
set(p1,'Color','blue')
set(p2,'Color','red')

figure
[ax,p1,p2] = plotyy(x, rulc, x(2:end), diff_rulc)
ylabel(ax(1),'rulc') 
ylabel(ax(2),'diff(rulc)')
xlabel(ax(2),'Year')
set(p1, 'LineWidth', 2)
set(p1,'Color','blue')
set(p2,'Color','red')