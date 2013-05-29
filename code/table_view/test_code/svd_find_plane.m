function [n rho X Y Z] = svd_find_plane(P)

pbar = mean(P);
Pshift = bsxfun(@minus, P, pbar);
A = Pshift'*Pshift;
[~, ~, V] = svd(A);
n = V(:, end);
rho = dot(n,pbar);

[X, Y] = meshgrid(linspace(min(P(:, 1)), max(P(:, 1)), 6), ...
                  linspace(min(P(:, 2)), max(P(:, 2)), 5));
              
Z=(rho-n(1).*X-n(2).*Y)/n(3);
end