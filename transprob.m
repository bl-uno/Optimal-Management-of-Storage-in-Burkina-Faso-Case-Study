function [transitionProba_cell,nodeValue] = transprob(n_nodes,net_load)
% Generate transition probability (cell) and 
% corresponding node values (matrix)

n_scenario = size(net_load,1);
n_hours = size(net_load,2);
transitionNode = zeros(n_nodes,n_nodes,n_hours-1);
transitionProb = zeros(n_nodes,n_nodes,n_hours-1);
transitionProba_cell = cell(n_hours-1,1);

% make ranges
ranges = zeros(n_nodes+1,n_hours); % ranges of net loads
nodeValue = zeros(n_hours,n_nodes); % node values
sort_nl = sort(net_load,1); % sorted net load
ranges(1,:) = sort_nl(1,:);
for i = 1:n_nodes
    for t = 1:n_hours
        ranges(i+1,t) = sort_nl(round(n_scenario/n_nodes*i),t);
        if i == 1
           nodeValue(t,i) = mean(sort_nl(1:round(n_scenario/n_nodes*i),t)); % take the average within the range
        else
           nodeValue(t,i) = mean(sort_nl(round(n_scenario/n_nodes*(i-1)):round(n_scenario/n_nodes*i),t));
        end
    end
end

% Building transition probability
for i=1:n_scenario
    transisionCount = zeros(n_nodes,n_hours); % count the pv_values that in the range
    for t=1:n_hours
        for j=1:n_nodes
            if j ~= 1
                if ranges(j,t) < net_load(i,t) && net_load(i,t) <= ranges(j+1,t) 
                    transisionCount(j,t) = transisionCount(j,t)+1; 
                end
            else
                if ranges(j,t) <= net_load(i,t) && net_load(i,t) <= ranges(j+1,t) 
                    transisionCount(j,t) = transisionCount(j,t)+1; 
                end
            end
        end
    end
    for t = 2:n_hours
        for l = 1:n_nodes
            for q = 1:n_nodes
                if transisionCount(l,t-1) == 1 && transisionCount(q,t) == 1
                    transitionNode(l,q,t-1) = transitionNode(l,q,t-1) + 1;
                end
            end
        end
    end
end

for t = 1:n_hours-1
    for j = 1:n_nodes
        for k = 1:n_nodes
            if sum(transitionNode(j,:,t)) == 0
                transitionProb(j,k,t) = 0;
            else
                transitionProb(j,k,t) = transitionNode(j,k,t)/sum(transitionNode(j,:,t));
            end
        end
    end
end

for t = 1:n_hours-1
    transitionProba_cell{t} = transitionProb(:,:,t);
end

end