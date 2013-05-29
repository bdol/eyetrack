function P = prob_to_point(probs, num_prob)
% Returns an Nx2 vector P consisting of the point determined by finding the
% weighted average of all points, weighted by the probs variable.

if nargin<2
    num_prob = size(probs, 2);
end

N = size(probs, 1);
P = zeros(N, 2);
Pos = get_positions;
for i=1:N
    prob = probs(i, :);
    [prob_sort, idx] = sort(prob, 'descend');
    p_sum = [0 0];
    for j=1:num_prob
       p_sum = p_sum+prob_sort(j)*Pos(idx(j), :);
    end
    P(i, :) = p_sum./sum(prob_sort(1:num_prob));
end

end