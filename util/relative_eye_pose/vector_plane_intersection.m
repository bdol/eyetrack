function Pintersect = vector_plane_intersection(P, o, d)
% P = [X ;Y; Z] points on the plane >=3
% o = [o1 o2 o3] origin of vector
% d = [d1 d2 d3] direction of vector

% pick three points on the plane
rand_idx = randi([1, size(P,2)], 3, 1);
point1 = P(:,rand_idx(1));
point2 = P(:,rand_idx(2));
point3 = P(:,rand_idx(3));
normal = cross(point1-point2, point1-point3);
keyboard;
t = - dot(normal, [o(:) - point2(:)]) / dot(normal, d);

Pintersect = o(:) + t.*d(:);