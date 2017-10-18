close all; 
clear all; 
clc;

% Set parameters
n_days = 4; % horizon of the model (number of days)
n_nodes = 10; % number of nodes per a stage on the lattice
n_batteries = 5; % number of batteries
%% Import the data and build the lattice
% a) import the load data
load('data/load_1000_weekdays.mat');
% b) import the pv generation data
load('data/pv_1000_sample.mat');

% c) refine the data
[~,col]=find(pv);
start_time = min(col); % find the eariest sunrise time in the data
n_hours = size(pv,2);  % number of hours to the horizon
data_size = size(pv,1);
pv = [pv(:,start_time:n_hours) ,pv(:,1:start_time-1)]; % redefine PV data
load_weekdays = [load_weekdays(:,start_time:n_hours),...
    load_weekdays(:,1:start_time-1)]; % redefine load data

% c) build net load scenario
net_load = zeros(data_size,size(pv,2)*n_days);
for i= 1:n_days
    perm1 = randperm(data_size);
    perm2 = randperm(data_size);
    for k = 1:data_size
        net_load(k,(n_hours*(i-1)+1):n_hours*i) = ...
            load_weekdays(perm1(k),:) - pv(perm2(k),:);
    end
end

% d) build the lattice
H = size(net_load,2); % set horizon H
[transitionProba, data] = transprob(n_nodes,net_load);

% e) visualize the lattice
lattice = Lattice.latticeEasyMarkovNonConst(H, transitionProba, data); 
figure ;
lattice.plotLattice(@(data) num2str(data));
%% Set the variables
var.ls = sddpVar(H); % load shedding
var.ps = sddpVar(H); % production shedding
var.s  = sddpVar(n_batteries,H); % battery storage
var.pd = sddpVar(n_batteries,H); % pumping demand for batteries
var.pb = sddpVar(n_batteries,H); % supply of battery 
var.pg = sddpVar(H); % thermal energy production
var.pi = sddpVar(H); % importing energy
var.cg = sddpVar(H); % cost of generator

params = sddpSettings('algo.McCount',25, ...
                      'stop.iterationMax',15,...
                      'stop.pereiraCoef',2,...
                      'stop.stdMcCoef',0.1,...
                      'stop.stopWhen','pereira and std',...
                      'solver','gurobi') ;

lattice = compileLattice(lattice,@(scenario)nlds(scenario,var),params) ;
%% Solve the problem 
output = sddp(lattice,params) ;
plotOutput(output);

