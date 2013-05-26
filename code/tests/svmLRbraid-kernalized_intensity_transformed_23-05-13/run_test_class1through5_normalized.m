%% Load data
clear;
dataPath = '~/code/eyetrack_data/cropped_eyes_clean/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_intensity_clean(dataPath);

ignore_idx = bsxfun(@or, bsxfun(@or, Y_left(:, 1)==6, Y_left(:, 1)==7), bsxfun(@or, Y_left(:, 1)==8, Y_left(:, 1)==9));
X_left(ignore_idx, :) = [];
X_right(ignore_idx, :) = [];
Y_left(ignore_idx, :) = [];
Y_right(ignore_idx, :) = [];
S(ignore_idx) = [];


X_left = bsxfun(@rdivide, X_left, max(X_left, [], 2));
X_right = bsxfun(@rdivide, X_right, max(X_right, [], 2));

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

%% Run SVM test
addpath kernels/
addpath libsvm/
addpath(genpath('liblinear-1.92'));

k_linear = @(x, x2)kernel_poly(x, x2, 1);
k_quadratic = @(x, x2)kernel_poly(x, x2, 2);
k_cubic = @(x, x2)kernel_poly(x, x2, 3);
k_gaussian = @(x, x2)kernel_gaussian(x, x2, 100000);

test_error_linear = zeros(N_folds, 1);
test_error_quadratic = zeros(N_folds, 1);
test_error_cubic = zeros(N_folds, 1);
test_error_gaussian = zeros(N_folds, 1);

test_acc_cubic_braid = zeros(N_folds, 1);
train_acc_cubic_svm = zeros(N_folds, 1);
train_acc_cubic_lr = zeros(N_folds, 1);
for i=1:N_folds
    test_idx = logical(test_fold_idx(:, i));
    X_train = X(~test_idx, :);
    Y_train = Y(~test_idx);
    X_test = X(test_idx, :);
    Y_test = Y(test_idx);
    
    % First divide the training fold into N_svm partitions. We will do xval on
    % these with an SVM to obtain their predictions.
    N_svm = 3;
    train_pred = zeros(size(X_train, 1), K);
    svm_idx = ceil(rand(size(X_train, 1), 1)*N_svm);
    for j=1:N_svm
        test_idx = svm_idx==j;
        X_train_svm = X_train(~test_idx, :);
        Y_train_svm = Y_train(~test_idx);
        X_test_svm = X_train(test_idx, :);
        Y_test_svm = Y_train(test_idx);
        
        [~, info] = kernelized_svm(X_train_svm, Y_train_svm, X_test_svm, ...
            Y_test_svm, k_cubic);
        
        train_pred(test_idx, :) = info.vals;
    end
    keyboard;
    
    % Now that we have all the training predictions (on unseen data), train
    % the LR model
    lr_model = train(Y_train, sparse(train_pred), '-s 0');
    [~, acc, ~] = predict(Y_train, sparse(train_pred), lr_model, '-b 1');
    train_acc_cubic_lr(i) = acc(1);
    
    % Now generate the predictions for the whole set
    [test_error_cubic(i), info] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_cubic);
    train_acc_cubic_svm(i) = info.train_acc;
    
    [pred, acc, est] = predict(Y_test, sparse(info.vals), lr_model, '-b 1');
    
    test_acc_cubic_braid(i) = acc(1)/100;
end
beep