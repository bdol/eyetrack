function d = point_plane_dist(v, X0, x)
% Determines the distance between a plane (specified by normal v and point
% X0) and a point x. This can be computed on a set of points by passing in
% an Nx3 matrix for x and 1x3 vectors for v, X0.
% Brian Dolhansky, 2013. bdol@seas.upenn.edu

N = size(x, 1);
v = repmat(v, N, 1);
X0 = repmat(X0, N, 1);
w = bsxfun(@minus, x, X0);
d = abs(sum(v.*w, 2))./sqrt(sum(v.^2, 2));

end