%% Load data
clear;
dataPath = '~/Desktop/cropped_eyes_transformed/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_intensity(dataPath);
%% Set up cross validation
K = 9;
X = [X_left X_right];
Y = Y_left(:, 1);
S_ind = Y_left(:, 2);
N_subjects = S(end).subj_index;
N_withold = 10; % Number of subjects to withold per fold
N_folds = floor(N_subjects/N_withold);

% Generate the subject numbers to withold for each fold
subjs = unique(Y_left(:, 2));
subjs = subjs(randperm(length(subjs)));
% Note: some subjects may not be tested with this method
subjs = reshape(subjs(1:N_withold*N_folds), N_withold, N_folds);

% Generate the index of the samples to withold in each fold
test_fold_idx = zeros(size(X, 1), N_folds);
for i=1:N_folds
    for j=1:N_withold
        test_fold_idx(:, i) = bsxfun(@or, test_fold_idx(:, i), S_ind==subjs(j, i));
    end
end

% Two eyes for every subject witheld, times K classes
assert(all(sum(test_fold_idx)==N_withold*2*K));

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