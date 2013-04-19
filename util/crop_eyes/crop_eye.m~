function [E crop_x crop_y] = crop_eye(im, C, w, h)

centroid = calculate_eye_centroid(C);
x = centroid(1);
y = centroid(2);
E = im(y-h/2:y+h/2-1, x-w/2:x+w/2-1, :);
crop_x = x-w/2;
crop_y = y-h/2;


end