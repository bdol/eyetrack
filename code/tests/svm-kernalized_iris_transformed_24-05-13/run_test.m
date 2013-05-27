%% Load data
clear;
dataPath = '~/code/eyetrack_data/cropped_eyes_clean/';
% [X_left Y_left X_right Y_right, S] = ...
%     load_cropped_eyes_iris_clean(dataPath);

[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_edges_clean(dataPath, 'canny');

% keep_idx = bsxfun(@or, Y_left(:, 1)==1, Y_left(:, 1)==2);
% X_left(~keep_idx, :) = [];
% X_right(~keep_idx, :) = [];
% Y_left(~keep_idx, :) = [];
% Y_right(~keep_idx, :) = [];
% S(~keep_idx) = [];

ignore_idx = bsxfun(@or, bsxfun(@or, Y_left(:, 1)==6, Y_left(:, 1)==7), bsxfun(@or, Y_left(:, 1)==8, Y_left(:, 1)==9));
X_left(ignore_idx, :) = [];
X_right(ignore_idx, :) = [];
Y_left(ignore_idx, :) = [];
Y_right(ignore_idx, :) = [];
S(ignore_idx) = [];

%% Set up cross validation
K = 5;
X = [X_left X_right];
Y = Y_left(:, 1);
S_ind = Y_left(:, 2);
N_subjects = max([S.subj_index]);
N_withold = 20; % Number of subjects to withold per fold
N_folds = floor(N_subjects/N_withold);

% Generate the subject numbers to withold for each fold
subjs = unique(Y_left(:, 2));
subjs = subjs(randperm(length(subjs)));

% Make sure we pick up the subjects that don't fit neatly into the folds
extra_subjs = [];
if numel(subjs)>(N_withold*N_folds)
    extra_subjs = subjs(N_withold*N_folds+1:end);
end

subjs = reshape(subjs(1:N_withold*N_folds), N_withold, N_folds);
if ~isempty(extra_subjs)
    N_folds = N_folds+1;
    subjs = [subjs zeros(size(subjs, 1), 1)];
    subjs(1:numel(extra_subjs), end) = extra_subjs;
end

assert(numel(unique(subjs))-1==N_subjects);

% Generate the index of the samples to withold in each fold
test_fold_idx = zeros(size(X, 1), N_folds);
for i=1:N_folds
    for j=1:N_withold
        test_fold_idx(:, i) = bsxfun(@or, test_fold_idx(:, i), S_ind==subjs(j, i));
    end
end

%% Run SVM test all 9 classes
addpath kernels/
addpath libsvm/

k_linear = @(x, x2)kernel_poly(x, x2, 1);
k_quadratic = @(x, x2)kernel_poly(x, x2, 2);
k_cubic = @(x, x2)kernel_poly(x, x2, 3);
k_gaussian = @(x, x2)kernel_gaussian(x, x2, 100000);

test_error_linear = zeros(N_folds, 1);
test_error_quadratic = zeros(N_folds, 1);
test_error_cubic = zeros(N_folds, 1);
test_error_gaussian = zeros(N_folds, 1);
train_error_linear = zeros(N_folds, 1);
train_error_quadratic = zeros(N_folds, 1);
train_error_cubic = zeros(N_folds, 1);
for i=1:N_folds
    test_idx = logical(test_fold_idx(:, i));
    X_train = X(~test_idx, :);
    Y_train = Y(~test_idx);
    X_test = X(test_idx, :);
    Y_test = Y(test_idx);
    
    [test_error_linear(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_linear); 
    [test_error_quadratic(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_quadratic); 
    [test_error_cubic(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_cubic);
    
%     [test_error_gaussian(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
%         Y_test, k_gaussian); 
    fprintf('%f\n%f\n%f\n', test_error_linear(i), test_error_quadratic(i), test_error_cubic(i));
end

%% Investigate why some folds did poorly
idx = find(test_fold_idx(:, 4)==1);
for i=1:numel(idx)
    close all;
    figure;
    left = reshape(X_left(idx(i), :), 50, 100);
    right = reshape(X_right(idx(i), :), 50, 100);
    subplot(1, 2, 1); imshow(right/255);
    subplot(1, 2, 2); imshow(left/255);
    keyboard;
end