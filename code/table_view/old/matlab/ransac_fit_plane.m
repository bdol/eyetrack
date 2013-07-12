function [n_est n_inliers Xplane Yplane Zplane] = ransac_fit_plane(Pw)

Xw = Pw(:,1);   Yw = Pw(:,2);   Zw = Pw(:,3);
valid_idx = find(Zw>0);
n_iter = 200;
n_inliers = 0;
thresh = 0.01;

%%
for i = 1: n_iter
   % randomly pick 3 points
   rand_idx = randi([1 numel(valid_idx)], 1, 3);
   % plane given by these three points
   point1 = [Xw(rand_idx(1)); Yw(rand_idx(1)); Zw(valid_idx(rand_idx(1)))];
   point2 = [Xw(rand_idx(2)); Yw(rand_idx(2)); Zw(valid_idx(rand_idx(2)))];
   point3 = [Xw(rand_idx(3)); Yw(rand_idx(3)); Zw(valid_idx(rand_idx(3)))];
   normal = cross(point1-point2, point1-point3);
   
   % find distance of each point from this plane
   unit_normal = normal./norm(normal, 2);
   v = bsxfun(@minus, Pw', point1);
   dist = abs(v'*unit_normal);
   
   % calculate the number of inliers
   current_n_inliers = sum(dist<thresh);
   if(current_n_inliers > n_inliers)
       n_est = unit_normal;
       n_inliers = current_n_inliers;
       Xplane = Xw(dist<thresh);
       Yplane = Yw(dist<thresh);
       Zplane = Zw(dist<thresh);
   end
end

end