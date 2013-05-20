%% 9 class HOG features
clear;
dataPath = '~/Desktop/cropped_eyes_transformed/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_intensity(dataPath);

%% Get HOG
left = reshape(X_left(1, :), 50, 100);
cellSize = 8;
numOrient = 9;
% Get correct size for HOG data structure
HOG = vl_hog(im2single(left), cellSize, 'NumOrientations', numOrient, 'BilinearOrientations');
hogLeft = zeros(size(HOG, 1), size(HOG, 2), size(HOG, 3), 9);
hogRight = zeros(size(HOG, 1), size(HOG, 2), size(HOG, 3), 9);

N = size(X_left, 1);
tleft = CTimeleft(N);
for i=1:N
    tleft.timeleft();
    left = reshape(X_left(i, :), 50, 100);
    right = reshape(X_right(i, :), 50, 100);
    hogLeft(:, :, :, Y_left(i, 1)) = ...
        hogLeft(:, :, :, Y_left(i, 1)) + ...
        vl_hog(im2single(left), cellSize, 'NumOrientations', numOrient, 'BilinearOrientations');
    hogRight(:, :, :, Y_right(i, 1)) = ...
        hogRight(:, :, :, Y_right(i, 1)) + ...
        vl_hog(im2single(right), cellSize, 'NumOrientations', numOrient, 'BilinearOrientations');
end

%% Get edge map
tleft = CTimeleft(N);
edgeLeftTotal = zeros(50, 100, 9);
edgeRightTotal = zeros(50, 100, 9);
for i=1:N
    tleft.timeleft();
    left = reshape(X_left(i, :), 50, 100);
    right = reshape(X_right(i, :), 50, 100);
    edgeLeftTotal(:, :, Y_left(i, 1)) = ...
        edgeLeftTotal(:, :, Y_left(i, 1)) + ...
        edge(left, 'canny');
    edgeRightTotal(:, :, Y_right(i, 1)) = ...
        edgeRightTotal(:, :, Y_right(i, 1)) + ...
        edge(right, 'canny');
end

%% Show raw edge map
close all; figure;
for k=1:9
    subplot(9, 2, (k-1)*2+1); imagesc(edgeRightTotal(:, :, k)); colormap('gray'); axis off;
    subplot(9, 2, (k-1)*2+2); imagesc(edgeLeftTotal(:, :, k)); colormap('gray'); axis off;
end
tightfig;

%% Show mean HOG for entire dataset
hogLeftMean = im2single(sum(hogLeft, 4))./N;
hogRightMean = im2single(sum(hogRight, 4))./N;

close all;
figure;
imLeft = vl_hog('render', hogLeftMean, 'NumOrientations', numOrient);
imRight = vl_hog('render', hogRightMean, 'NumOrientations', numOrient);
subplot(1, 2, 1); imagesc(imLeft.^2); colormap('gray');
subplot(1, 2, 2); imagesc(imRight.^2); colormap('gray');
tightfig;
%% Classwise mean HOG
