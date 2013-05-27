function P = prob_to_point(probs)
% Returns an Nx2 vector P consisting of the point determined by finding the
% weighted average of all points, weighted by the probs variable.

N = size(probs, 1);
P = zeros(N, 2);
[~, Pos_norm] = get_positions;
for i=1:N
    P(i, :) = sum(bsxfun(@times, probs(i, :)', Pos_norm));
end

end