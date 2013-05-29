%% Try file exchange code
clear; close all;
addpath LK' Tracker'/

im1 = im2double(imread('~/code/eyetrack_data/cropped_eyes_clean/1001.2.E/straight/straight_left.png'));
im2 = im2double(imread('~/code/eyetrack_data/cropped_eyes_clean/1001.2.E/1/IM_1_1_left.png'));
[h w d] = size(im1);

imgseq = zeros(h, w, 2);
imgseq(:, :, 1) = rgb2gray(im1);
imgseq(:, :, 2) = rgb2gray(im2);

LKTrackWrapper(imgseq);



%% Try 2-D cross correlation
clear; close all;
[E_left E_right] = get_mean_templates('~/code/eyetrack_data/cropped_eyes_clean/');

%%
im = rgb2gray(im2double(imread('~/code/eyetrack_data/cropped_eyes_clean/1020.2.E/1/IM_1_1_left.png')));
w = 100;
h = 50;
% 
template = E_left(:, :, 1);
template = template-mean(mean(template));
C = xcorr2(im, template);

[~, m] = max(C);
[~, max_x] = max(max(C));
max_y = m(max_x);

close all;
subplot(1, 3, 1);
imagesc(template); hold on;
plot(50, 25, 'mx');
subplot(1, 3, 2);
imagesc(C); hold on;
plot(max_x, max_y, 'gx');
subplot(1, 3, 3);
imshow(im); hold on; 
plot(50, 25, 'mx');
plot(max_x-w/2, max_y-h/2, 'gx');