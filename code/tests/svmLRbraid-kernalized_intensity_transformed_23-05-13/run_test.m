%% Load data
clear;
dataPath = '~/code/eyetrack_data/cropped_eyes_transformed_tps_new/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_iris(dataPath);
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
    Y_train_subjs = Y_left(~test_idx, 2);
    Y_test_subjs = Y_left(test_idx, 2);
    
    % First divide the training fold into N_svm partitions. We will do xval on
    % these with an SVM to obtain their predictions. Make sure to not
    % include the same subjects in training and testing.
    N_svm = 3;
    train_pred = zeros(size(X_train, 1), K);
    svm_idx = ceil(rand(size(X_train, 1), 1)*N_svm);
    N_per_fold_svm = ceil(numel(unique(Y_train_subjs))/N_svm);
    unique_train_subjs = unique(Y_train_subjs);
    svm_subjs = unique_train_subjs(randperm(length(unique_train_subjs)));
    svm_subjs_mat = zeros(N_per_fold_svm, N_svm);
    for k=1:numel(svm_subjs)
        svm_subjs_mat(k) = svm_subjs(k);
    end
    
    for j=1:N_svm
        test_idx = zeros(size(Y_train_subjs, 1), 1);
        for k=1:size(Y_train_subjs, 1)
            for p=1:N_per_fold_svm
                if test_idx(k)==0
                    test_idx(k) = Y_train_subjs(k) == svm_subjs_mat(p, j);
                end
            end
        end
        test_idx = logical(test_idx);
       
        X_train_svm = X_train(~test_idx, :);
        Y_train_svm = Y_train(~test_idx);
        X_test_svm = X_train(test_idx, :);
        Y_test_svm = Y_train(test_idx);
        
        [~, info] = kernelized_svm(X_train_svm, Y_train_svm, X_test_svm, ...
            Y_test_svm, k_cubic);
        
        train_pred(test_idx, :) = info.vals;
    end
    
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