function [PB_feat feat_vec_len] = extract_pb_features(image)

% PB Feature
PB_feat = struct('centroid_x',{},'centroid_y',{}, 'top_left_corner',{}, ...
    'bottom_right_corner',{},'d_left_corner',{}, 'd_right_corner',{}, ...
    'pb', {});
pb_thresh = 0.5;
[pb ~] = pbCGTG(image);
[n xout] = hist(pb(:));
highprob_ind = find(pb >  min(xout(xout>pb_thresh)));
PB_feat(1).pb = zeros(size(pb));
PB_feat(1).pb(highprob_ind) = pb(highprob_ind);
[x y] = ind2sub(size(pb), highprob_ind);
PB_feat(1).top_left_corner = [min(x) min(y)]; 
PB_feat(1).bottom_right_corner = [max(x) max(y)];
PB_feat(1).centroid_x = sum(x.*pb(highprob_ind))./sum(pb(highprob_ind));
PB_feat(1).centroid_y = sum(y.*pb(highprob_ind))./sum(pb(highprob_ind));
% imshow(highprob_pb); hold on; plot(centroid_y, centroid_x, 'r*', 'MarkerSize',14);
% rectangle('Position',[top_left_corner(2), top_left_corner(1), ...
%     bottom_right_corner(2) - top_left_corner(2), bottom_right_corner(1) - top_left_corner(1)]...
%     ,'LineWidth',1,'EdgeColor', 'r', 'LineStyle','--');
% Find distance of centroid from corners of eye detected by pb
PB_feat(1).d_left_corner = norm(PB_feat(1).top_left_corner - [PB_feat(1).centroid_x PB_feat(1).centroid_y]);
PB_feat(1).d_right_corner = norm(PB_feat(1).bottom_right_corner - [PB_feat(1).centroid_x PB_feat(1).centroid_y]);
feat_vec_len = length(PB_feat);
% line([centroid_y top_left_corner(2)], [centroid_x top_left_corner(1)], 'LineWidth',2, 'Color','y');
% line([centroid_y bottom_right_corner(2)], [centroid_x bottom_right_corner(1)], 'LineWidth',2, 'Color','g');
% hold off;