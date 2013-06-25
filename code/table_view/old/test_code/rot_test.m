clear;
Xw = [-0.5502   -0.5378   -0.5285   -0.5163   -0.5435   -0.5337   -0.5236   -0.5092   -0.5362   -0.5249   -0.5146   -0.5041];
Yw = [-0.2766   -0.2821   -0.2894   -0.2951   -0.2568   -0.2638   -0.2708   -0.2750   -0.2376   -0.2428   -0.2499   -0.2561];
Zw = [1.5049    1.5115    1.5247    1.5313    1.4985    1.5115    1.5247    1.5247    1.4921    1.4985    1.5115    1.5247];

P = [Xw' Yw' Zw'];
P = bsxfun(@minus, P, mean(P));
[n rho Xp Yp Zp] = svd_find_plane(P);
close all;
P = P';
plot3(P(1, :), P(2, :), P(3, :), 'r*'); hold on;
mesh(Xp,Yp,Zp);colormap([.8 .8 .8])
axis equal
hold off;

[~, ~, V] = svd(P*P');
P = V'*P;
Xp = Xp(:); Yp = Yp(:); Zp = Zp(:); 

Pp = [Xp Yp Zp]';
Pp = V'*Pp;
Xp = reshape(Pp(1, :), 5, 6);
Yp = reshape(Pp(2, :), 5, 6);
Zp = reshape(Pp(3, :), 5, 6);

P_proj = point_plane_intersection([0 0 1], [0 0 0], P')';

figure;
plot3(P(1, :), P(2, :), P(3, :), 'r*'); hold on;
plot3(P_proj(1, :), P_proj(2, :), P_proj(3, :), 'b*'); hold on;
% mesh(Xp,Yp,Zp);colormap([.8 .8 .8])
axis equal