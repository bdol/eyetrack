%% 9 class HOG features
clear;
addpath ~/code/eyetrack/util/deva_features/
dataPath = '/scratch/bdol/cropped_eyes_transformed_new_pl/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_rgb(dataPath);
N = size(X_left, 1);

%% Get HOG averages
binsize = 6;
% Get right size of HoG images
left = reshape(X_left(1, :), 50, 100, 3);
hogLeft = features(left, binsize);
imLeft = HOGpicture(hogLeft);
hogLeftTotal = zeros(size(imLeft, 1), size(imLeft, 2), 9);
hogRightTotal = zeros(size(imLeft, 1), size(imLeft, 2), 9);

for i=1:N
    left = reshape(X_left(i, :), 50, 100, 3);
    right = reshape(X_right(i, :), 50, 100, 3);
    hogLeft = features(left, binsize);
    hogRight = features(right, binsize);
    
    imLeft = HOGpicture(hogLeft);
    imRight = HOGpicture(hogRight);
%     close all;
%     figure;
%     subplot(2, 2, 1); imagesc(uint8(left));
%     subplot(2, 2, 2); imagesc(uint8(right));
%     subplot(2, 2, 3); imagesc(imLeft); colormap('gray');
%     subplot(2, 2, 4); imagesc(imRight); colormap('gray');
%     keyboard;
    
    hogLeftTotal(:, :, Y_left(i, 1)) = ...
        hogLeftTotal(:, :, Y_left(i, 1)) + imLeft;
    hogRightTotal(:, :, Y_right(i, 1)) = ...
        hogRightTotal(:, :, Y_right(i, 1)) + imRight;
    
    if mod(i, 100)==0
        fprintf('%d of %d.\n', i, N);
    end
end
fprintf('Done!\n');

%% Plot HoG over entire dataset
hogLeftAvg = hogLeftTotal./N;
hogRightAvg = hogRightTotal./N;
close all; figure;
subplot(1, 2, 1); imagesc(hogRightAvg); colormap('gray');
subplot(1, 2, 2); imagesc(hogLeftAvg); colormap('gray');
tightfig;

%% Plot classwise HoG
mean_left = zeros(size(imLeft, 1), size(imLeft, 2), 9);
mean_right = zeros(size(imLeft, 1), size(imLeft, 2), 9);
for k=1:9
   ysum_left = sum(Y_left(:, 1)==k);
   ysum_right = sum(Y_right(:, 1)==k);
   mean_left(:, :, k) = (hogLeftTotal(:, :, k)/ysum_left);
   mean_left(:, :, k) = mean_left(:, :, k)/max(max(mean_left(:, :, k)));
   mean_right(:, :, k) = (hogRightTotal(:, :, k)/ysum_right);
   mean_right(:, :, k) = mean_right(:, :, k)/max(max(mean_right(:, :, k)));
end

close all;
figure;
for k=1:9
    subplot(9, 2, (k-1)*2+1); imagesc(mean_right(:, :, k)); colormap('gray'); axis off;
    subplot(9, 2, (k-1)*2+2); imagesc(mean_left(:, :, k)); colormap('gray'); axis off;
end
tightfig;

%% Get edge map
edgeLeftTotal = zeros(50, 100, 9);
edgeRightTotal = zeros(50, 100, 9);
for i=1:N
    left = rgb2gray(uint8(reshape(X_left(i, :), 50, 100, 3)));
    right = rgb2gray(uint8(reshape(X_right(i, :), 50, 100, 3)));

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
