function [Xp Yp Zp] = gen_plane_points(norm, dist)

R = determine_plane_rotation(norm);
[X,Y]=meshgrid(-1:.2:1,-1:.2:1);
[ph pw] = size(X);
Z = zeros(size(X));

P = [X(:) Y(:) Z(:)];
P_rot = (R*P')';
% P_rot_trans = P_rot;
P_rot_trans = bsxfun(@plus, (dist*norm)', P_rot);
[Xp Yp Zp] = deal(P_rot_trans(:, 1), P_rot_trans(:, 2), P_rot_trans(:, 3));

Xp = reshape(Xp, ph, pw);
Yp = reshape(Yp, ph, pw);
Zp = reshape(Zp, ph, pw);


end