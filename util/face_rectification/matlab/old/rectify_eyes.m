function [r_eye, l_eye, r_eye_rect, l_eye_rect, c_trans_r, c_trans_l cr, cl] = rectify_eyes(canon_corresp, turned_corresp, w, h, im_canon, im_turned)

X_c_r = canon_corresp(37:42, :);
X_c_l = canon_corresp(43:48, :);
X_t_r = turned_corresp(37:42, :);
X_t_l = turned_corresp(43:48, :);

H_R = findHomography(X_c_r, X_t_r);
H_L = findHomography(X_c_l, X_t_l);
% Find eye centroids
cent_r = mean(X_c_r);
cent_l = mean(X_c_l);
% Find crop top right corner
cr = [cent_r(1)-w/2, cent_r(2)-h/2];
cl = [cent_l(1)-w/2, cent_l(2)-h/2];
r_eye_rect = rectify_eye_image(im_turned, cr(1), cr(2), w, h, H_R);
l_eye_rect = rectify_eye_image(im_turned, cl(1), cl(2), w, h, H_L);

r_eye = crop_eye(im_canon, X_c_r, w, h);
l_eye = crop_eye(im_canon, X_c_l, w, h);

% Transform to cropped space
X_c_r = bsxfun(@minus, X_c_r, cent_r);
X_c_l = bsxfun(@minus, X_c_l, cent_l);
X_t_r = bsxfun(@minus, X_t_r, cent_r);
X_t_l = bsxfun(@minus, X_t_l, cent_l);

% Find homography
H_R = findHomography(X_c_r, X_t_r);
H_L = findHomography(X_c_l, X_t_l);


c_trans_r = zeros(size(X_t_r));
for i=1:size(c_trans_r, 1)
    p = [X_t_r(i, :) 1]';
    pc = inv(H_R)*p;
    pc = pc./pc(3);
    pc = pc+[w/2; h/2; 0];
    c_trans_r(i, 1) = pc(1);
    c_trans_r(i, 2) = pc(2);
end


c_trans_l = zeros(size(X_t_r));
for i=1:size(c_trans_l, 1)
    p = [X_t_l(i, :) 1]';
    pc = inv(H_L)*p;
    pc = pc./pc(3);
    pc = pc+[w/2; h/2; 0];
    c_trans_l(i, 1) = pc(1);
    c_trans_l(i, 2) = pc(2);
end



end