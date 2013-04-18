function R = rectify_eyes_final(im_canon, im_turned, c_canon, c_turned, w, h)

r_idx = 37:42;
l_idx = 43:48;
centroid_canon_l = mean(c_canon(l_idx, :));
centroid_canon_r = mean(c_canon(r_idx, :));
centroid_turned_l = mean(c_turned(l_idx, :));
centroid_turned_r = mean(c_turned(r_idx, :));

% Crop images
[im_canon_crop_r cx_canon_r cy_canon_r] = crop_eye(im_canon, c_canon(r_idx, :), w, h);
[im_canon_crop_l cx_canon_l cy_canon_l] = crop_eye(im_canon, c_canon(l_idx, :), w, h);
[im_turned_crop_l cx_turned_l cy_turned_l] = crop_eye(im_turned, c_turned(l_idx, :), w, h);
[im_turned_crop_r cx_turned_r cy_turned_r] = crop_eye(im_turned, c_turned(r_idx, :), w, h);

X_canon_l = bsxfun(@minus, c_canon(l_idx, :), centroid_canon_l);
X_canon_r = bsxfun(@minus, c_canon(r_idx, :), centroid_canon_r);
X_turned_l = bsxfun(@minus, c_turned(l_idx, :), centroid_turned_l);
X_turned_r = bsxfun(@minus, c_turned(r_idx, :), centroid_turned_r);

H_L = findHomography(X_canon_l, X_turned_l);
H_R = findHomography(X_canon_r, X_turned_r);

r_eye_rect = rectify_eye_image_center_first(im_turned, w, h, H_R, centroid_turned_r);
l_eye_rect = rectify_eye_image_center_first(im_turned, w, h, H_L, centroid_turned_l);

% Figure out the correspondence points in the new cropped space
cx = centroid_canon_r(1)-w/2; cy = centroid_canon_r(2)-h/2;
X_c_crop_r = bsxfun(@minus, c_canon(r_idx, :), [cx cy]);
cx = centroid_canon_l(1)-w/2; cy = centroid_canon_l(2)-h/2;
X_c_crop_l = bsxfun(@minus, c_canon(l_idx, :), [cx cy]);
cx = centroid_turned_r(1)-w/2; cy = centroid_turned_r(2)-h/2;
X_t_crop_r = bsxfun(@minus, c_turned(r_idx, :), [cx cy]);
cx = centroid_turned_l(1)-w/2; cy = centroid_turned_l(2)-h/2;
X_t_crop_l = bsxfun(@minus, c_turned(l_idx, :), [cx cy]);

X_r_crop_r = 0;
X_r_crop_l = 0;

R.im_canon_crop_r = im_canon_crop_r;
R.im_canon_crop_l = im_canon_crop_l;
R.im_turned_crop_r = im_turned_crop_r;
R.im_turned_crop_l = im_turned_crop_l;
R.r_eye_rect = r_eye_rect;
R.l_eye_rect = l_eye_rect;
R.X_c_crop_r = X_c_crop_r;
R.X_c_crop_l = X_c_crop_l;
R.X_t_crop_r = X_t_crop_r;
R.X_t_crop_l = X_t_crop_l;
R.X_r_crop_r = X_r_crop_r;
R.X_r_crop_l = X_r_crop_l;

end