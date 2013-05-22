%% Load data
clear;
dataPath = '~/code/eyetrack_data/cropped_eyes_transformed_new_pl/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_edges(dataPath, 'canny');
%% Set up cross validation
assert(all(all(Y_left==Y_right)));
K = 9;
X_L = X_left;
X_R = X_right;
Y_L = Y_left(:, 1);
Y_R = Y_right(:, 1);
S_ind = Y_left(:, 2);
N_subjects = max([S.subj_index]);
N_withold = 20; % Number of subjects to withold per fold
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

% TODO: some images are missing, ignore this for now
% Two eyes for every subject witheld, times K classes
% assert(all(sum(test_fold_idx)==N_withold*2*K));

%% Run SVM test on LEFT EYE on all 9 classes
addpath kernels/
addpath libsvm/

k_linear = @(x, x2)kernel_poly(x, x2, 1);
k_quadratic = @(x, x2)kernel_poly(x, x2, 2);
k_cubic = @(x, x2)kernel_poly(x, x2, 3);
k_gaussian = @(x, x2)kernel_gaussian(x, x2, 100000);

test_error_linear_L = zeros(N_folds, 1);
test_error_quadratic_L = zeros(N_folds, 1);
test_error_cubic_Lthi = zeros(N_folds, 1);
% test_error_gaussian = zeros(N_folds, 1);
for i=1:N_folds
    test_idx = logical(test_fold_idx(:, i));
    X_train = X_L(~test_idx, :);
    Y_train = Y_L(~test_idx);
    X_test = X_L(test_idx, :);
    Y_test = Y_L(test_idx);
    
    [test_error_linear_L(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_linear); 
    [test_error_quadratic_L(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_quadratic); 
    [test_error_cubic_L(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_cubic); 
%     [test_error_gaussian(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
%         Y_test, k_gaussian); 
end

%% Run SVM test on RIGHT EYE on all 9 classes
addpath kernels/
addpath libsvm/

k_linear = @(x, x2)kernel_poly(x, x2, 1);
k_quadratic = @(x, x2)kernel_poly(x, x2, 2);
k_cubic = @(x, x2)kernel_poly(x, x2, 3);
k_gaussian = @(x, x2)kernel_gaussian(x, x2, 100000);

test_error_linear_R = zeros(N_folds, 1);
test_error_quadratic_R = zeros(N_folds, 1);
test_error_cubic_R = zeros(N_folds, 1);
% test_error_gaussian_R = zeros(N_folds, 1);
for i=1:N_folds
    test_idx = logical(test_fold_idx(:, i));
    X_train = X_R(~test_idx, :);
    Y_train = Y_R(~test_idx);
    X_test = X_R(test_idx, :);
    Y_test = Y_R(test_idx);
    
    [test_error_linear_R(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_linear); 
    [test_error_quadratic_R(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_quadratic); 
    [test_error_cubic_R(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_cubic); 
%     [test_error_gaussian(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
%         Y_test, k_gaussian); 
end