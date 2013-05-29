function F = determine_k2_frame(C, fx, fy, cx, cy)

% First determine plane normal
Xw = []; Yw = []; Zw = [];
Xline = []; Yline = []; Zline = [];
N = size(C, 3);
% close all;
for i=1:N
    C_i = C(:, :, i);
    [X Y Z] = im_to_world(C_i(:, 1), C_i(:, 2), C_i(: ,3), fx, fy, cx, cy);
    Xw = [Xw; X];
    Yw = [Yw; Y];
    Zw = [Zw; Z];
    Xline = [Xline; X(5:8)];
    Yline = [Yline; Y(5:8)];
    Zline = [Zline; Z(5:8)];
    
%     plot3(X(1:4), Y(1:4), Z(1:4), 'bx'); hold on;
%     plot3(X(5:8), Y(5:8), Z(5:8), 'rx'); hold on;
%     plot3(X(9:12), Y(9:12), Z(9:12), 'bx');
end
n = svd_find_plane([Xw Yw Zw]);
if (n(3)>0)
    n = -n;
end

% Now determine horizontal vector that lies along front of kinect
% Project the line points onto the plane
P = point_plane_intersection(n', mean([Xw Yw Zw]), [Xline Yline Zline]);
P_centered = bsxfun(@minus, P, mean(P));
[~, ~, V] = svd(P_centered);
P_line = cross(V(:, end), V(:, end-1));
P_line = P_line./norm(P_line);


F = zeros(3, 3);
F(:, 1) = P_line;
F(:, 3) = n;
F(:, 2) = cross(P_line, n);

end