function [ cntr, obj ] = nlds(scenario, var)
% Build NLDS for a given node

t = scenario.getTime() ;

% SETTING PARAMETERS AND VARIABLES
% parameters
VOLL = 1000;        % cost of load shedding (in $/unit) 
VOLP = 1e-5;        % cost of production shedding (in $/unit)
COST_BT = 0.6e-5;   % cost of charging battery ($/MWh)
MC = 200;           % Marginal cost of diesel $/MWh
CI = 100;           % Marginal cost of imports $/MWh
eta = 0.95;         % fraction of converted energy to batteries
mu = 0.97;          % fraction of converted energy from batteries 
s_0 = 0;            % level of energy in the batteries at the beginning
ST = 1000;          % capacity of battery storage
PD = 200;           % capacity of the pumping demand to store
PB = 200;           % capacity of the battery power to extract
PG = 300;           % total capacity of generators
PI = 200;           % capacity of importation

% Variables
ls = var.ls; % load shedding
ps = var.ps; % production shedding
s = var.s;   % battery storage 
pd = var.pd; % pumping demand for batteries
pb = var.pb; % supply of battery
pg = var.pg; % thermal energy production
pi = var.pi; % importing energy
cg = var.cg; % cost of generator
data = scenario.data; % extract the stocastic parameter
net_load = data; 

pd_total = sum(pd(:,t)); % total demand for batteries
pb_total = sum(pb(:,t)); % total supply of batteries

% OBJECTIVE FUNCTION
total_cost = ls(t)*VOLL + cg(t) + pi(t) * CI + ps(t) * VOLP + ...
    (pd_total +pb_total)* COST_BT;

% CONSTRAINTS
% generator cost function
generator_cost = cg(t) >= pg(t) * MC;

% Power balance
power_balance = net_load + pd_total + ps(t) ==...
    pb_total + pg(t) + pi(t) + ls(t) ;

% Storage balance in batteries
for i = 1:5
    if t>1
        storage_balance(i) = s(i,t) == ...
            s(i,t-1) + (eta*pd(i,t) - 1/mu*pb(i,t));
    else
        storage_balance(i) = s(i,t) == ...
            s_0 + (eta*pd(i,t) - 1/mu*pb(i,t));
    end
end

% Maximum capacity
for i = 1:5
    storage_capacity(i) = s(i,t) <= ST;
    pumping_demand_capacity(i) =  pd(i,t) <= PD;
    extract_power_capacity(i) = pb(i,t) <= PB;
end
power_generated_capacity = pg(t) <= PG;
power_imported_capacity = pi(t) <= PI;

% Nonnegativity
for i = 1:5
    s_non_negativity(i) = s(i,t) >= 0 ;
    pd_non_negativity(i) = pd(i,t) >= 0 ;
    pb_non_negativity(i) = pb(i,t) >= 0 ;
end
non_negativity = [s_non_negativity, pd_non_negativity, pb_non_negativity,...
    ls(t) >= 0, pg(t) >= 0, pi(t) >= 0, cg(t) >= 0 , ps(t) >= 0 ] ;

% Inserting the model in the FAST format
obj = total_cost;
cntr = [generator_cost,...
        power_balance, ...
        storage_balance, ...
        power_imported_capacity, ...
        power_generated_capacity, ...
        storage_capacity, ...
        pumping_demand_capacity, ...
        extract_power_capacity, ...
        non_negativity
        ] ;
end 


