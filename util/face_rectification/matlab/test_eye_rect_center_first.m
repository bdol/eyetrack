%% Transform correspondences to 0 mean
w = 100;
h = 50;
r_idx = 37:42;
l_idx = 43:48;

fbase = '~/Desktop/out_rect/';
flist = dir([fbase '*.txt']);
ilist = importdata('~/code/eyetrack/util/face_rectification/bin/frames.txt');

im_canon = imread('/Users/bdol/Desktop/png_data/1146.2.N/IM_For_Katie_0.png');
im_canon = flipdim(im_canon, 2);
c_canon = importdata('~/Desktop/out_rect/H_0.txt');


for i=2:numel(flist)
    close all; 
    
    im_turned = flipdim(imread(ilist{i}), 2);
    c_turned = importdata([fbase 'H_' num2str(i-1) '.txt']);
    
    R = rectify_eyes_final(im_canon, im_turned, c_canon, c_turned, w, h);
    subplot(3, 2, 1); imshow(R.im_canon_crop_r); 
    hold on; plot_corresp(R.X_c_crop_r, 'gx'); hold off;
    subplot(3, 2, 2); imshow(R.im_canon_crop_l); 
    hold on; plot_corresp(R.X_c_crop_l, 'gx'); hold off;
    subplot(3, 2, 3); imshow(R.im_turned_crop_r); 
    hold on; plot_corresp(R.X_t_crop_r, 'gx'); hold off;
    subplot(3, 2, 4); imshow(R.im_turned_crop_l); 
    hold on; plot_corresp(R.X_t_crop_l, 'gx'); hold off;
    subplot(3, 2, 5); imshow(R.r_eye_rect/255);
    hold on; plot_corresp(R.X_c_crop_r, 'bo');
    subplot(3, 2, 6); imshow(R.l_eye_rect/255);
    hold on; plot_corresp(R.X_c_crop_l, 'bo');
    
    keyboard;
end