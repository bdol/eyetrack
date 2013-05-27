%% Load data
clear;
dataPath = '~/code/eyetrack_data/cropped_eyes_transformed_tps_corrected/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_intensity(dataPath);

%% Set up cross validation
K = 9;
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

train_error_linear = zeros(N_folds, 1);
train_error_quadratic = zeros(N_folds, 1);
train_error_cubic = zeros(N_folds, 1);
test_error_linear = zeros(N_folds, 1);
test_error_quadratic = zeros(N_folds, 1);
test_error_cubic = zeros(N_folds, 1);

yhat_linear = {};
yhat_quad = {};
yhat_cubic = {};

for i=1:N_folds
    test_idx = logical(test_fold_idx(:, i));
    X_train = X(~test_idx, :);
    Y_train = Y(~test_idx);
    X_test = X(test_idx, :);
    Y_test = Y(test_idx);
    
    fprintf('Testing linear classifier...\n');
    [test_error_linear(i) info_linear] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_linear);
    
    fprintf('Done linear. Testing quadratic classifier...\n');
    [test_error_quadratic(i) info_quad] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_quadratic);
    
    fprintf('Done quadratic. Testing cubic classifier...\n');
    [test_error_cubic(i) info_cubic] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_cubic);
    fprintf('Done cubic.\n');
    
    train_error_linear(i) = info_linear.train_err;
    train_error_quadratic(i) = info_quad.train_err;
    train_error_cubic(i) = info_cubic.train_err;
    
    yhat_linear{i} = info_linear.yhat;
    yhat_quad{i} = info_quad.yhat;
    yhat_cubic{i} = info_cubic.yhat;

    beep;
    
    fprintf('Done fold %d.\nTrain Errors:\nLinear:\t%f\nQuad:\t%f\nCubic:\t%f\nTest Errors:\nLinear:\t%f\nQuad:\t%f\nCubic:\t%f\n\n', ...
        i, train_error_linear(i), train_error_quadratic(i), train_error_cubic(i), test_error_linear(i), test_error_quadratic(i), test_error_cubic(i))
    keyboard;
end