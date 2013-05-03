function x = minimizeAx(A)
[~, ~, V] = svd(A);
x = V(:, end)';

end