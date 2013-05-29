function E = get_euclid_error(probs, Y, num_probs)

if nargin<3
    num_probs = size(probs, 2);
end

P = get_positions();
P_est = prob_to_point(probs, num_probs);
E = zeros(size(probs, 1), 1);
for i=1:size(P_est, 1)
    p_hat = P_est(i, :);
    p_actual = P(Y(i), :);
    E(i) = sqrt(sum((p_actual-p_hat).^2));
end