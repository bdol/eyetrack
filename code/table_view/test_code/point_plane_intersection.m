function p = point_plane_intersection(v, X0, x)
% Determines the nearest point p on a plane (specified by normal vector v
% and point X0) to the given point x;

N = size(x, 1);
X0 = repmat(X0, N, 1);
w = bsxfun(@minus, x, X0);
d = w*v'; % This assumes we have a unit normal vector
v = repmat(v, N, 1);
p = w-bsxfun(@times, d, v);
p = bsxfun(@plus, X0, p);

end