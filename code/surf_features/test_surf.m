clear; close all;

addpath(genpath('OpenSURF_version1c'));

I1 = imread('~/code/eyetrack_data/cropped_eyes_transformed_tps_corrected/1005.2.E/2/IM_2_3_left.png');
% I1 = imread('~/code/eyetrack_data/cropped_eyes_clean/1005.2.E/2/IM_2_1_left.png');
% I2 = imread('~/code/eyetrack_data/cropped_eyes_clean/1005.2.E/2/IM_2_2_left.png');

% 
% Options.tresh = 0.0001;
% Options.init_sample = 1;
% Options.octaves = 5;
% Ipts1 = OpenSurf(I1, Options);
% Ipts2 = OpenSurf(I2, Options);
% 
% 
% PaintSURF(I2, Ipts2);

% Try MATLAB's implementation
pts1 = detectSURFFeatures(rgb2gray(I1), 'MetricThreshold', 300);
figure;
imshow(I1); hold on;
plot(pts1.Location(:, 1), pts1.Location(:, 2), 'gx');

%%
clear;
dataPath = '~/code/eyetrack_data/cropped_eyes_transformed_tps_corrected/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_SURF(dataPath, 300);