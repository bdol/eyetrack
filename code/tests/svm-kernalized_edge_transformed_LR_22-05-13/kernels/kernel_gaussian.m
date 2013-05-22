function K = kernel_gaussian(X, X2, sigma)
% Evaluates the Gaussian Kernel with specified sigma
%
% Usage:
%
%    K = KERNEL_GAUSSIAN(X, X2, SIGMA)
%
% For a N x D matrix X and a M x D matrix X2, computes a M x N kernel
% matrix K where K(i,j) = k(X(i,:), X2(j,:)) and k is the Guassian kernel
% with parameter sigma.

n = size(X,1);
m = size(X2,1);
K = zeros(m, n);

% HINT: Transpose the sparse data matrix X, so that you can operate over columns. Sparse
% column operations in matlab are MUCH faster than row operationperations.os.

Xt = X';
X2t = X2';

for i=1:size(Xt, 2)
    difference = repmat(Xt(:, i), 1, size(X2t, 2)) - X2t;
    numerator = sum(difference.*difference);
    K(:, i) = numerator'/(2*(sigma^2));
end

K = full(exp(-K));