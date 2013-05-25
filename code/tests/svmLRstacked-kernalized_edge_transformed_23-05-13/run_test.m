%% Load data
clear;
dataPath = '~/code/eyetrack_data/cropped_eyes_transformed_tps_new/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_intensity(dataPath);
%% Set up cross validation
K = 9;
X = [X_left X_right];
Y = Y_left(:, 1);
S_ind = Y_left(:, 2);
N_subjects = S(end).subj_index;
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
addpath(genpath('liblinear-1.92/'));

svm_train_portion = 0.5;

k_linear = @(x, x2)kernel_poly(x, x2, 1);
k_quadratic = @(x, x2)kernel_poly(x, x2, 2);
k_cubic = @(x, x2)kernel_poly(x, x2, 3);
k_gaussian = @(x, x2)kernel_gaussian(x, x2, 100000);

test_error_linear_svm = zeros(N_folds, 1);
test_error_linear_stack = zeros(N_folds, 1);
test_error_quadratic = zeros(N_folds, 1);
test_error_quadratic_svm = zeros(N_folds, 1);
test_error_cubic_svm = zeros(N_folds, 1);
test_error_cubic_stack = zeros(N_folds, 1);
test_error_gaussian = zeros(N_folds, 1);

yhat_stack_linear = zeros(500, N_folds);
y_actual = zeros(500, N_folds);
for i=1:N_folds
    test_idx = logical(test_fold_idx(:, i));
    X_train = X(~test_idx, :);
    Y_train = Y(~test_idx);
    X_test = X(test_idx, :);
    Y_test = Y(test_idx);
    
    % First partition the set into an SVM and a LR set
    svm_idx = rand(size(X_train, 1), 1)<svm_train_portion;
    X_train_svm = X_train(svm_idx, :);
    Y_train_svm = Y_train(svm_idx);
    X_train_notsvm = X_train(~svm_idx, :);
    Y_train_notsvm = Y_train(~svm_idx);
    assert((size(X_train_svm, 1)+size(X_train_notsvm, 1))==size(X_train, 1));
    % Next train the SVM on the SVM portion of the training set, and test
    % on the LR set
%     [~, info_linear] = kernelized_svm(X_train_svm, Y_train_svm, X_train_notsvm, ...
%         Y_train_notsvm, k_linear);
%     [~, info] = kernelized_svm(X_train_svm, Y_train_svm, X_train_notsvm, ...
%         Y_train_notsvm, k_quadratic);
    [~, info_cubic] = kernelized_svm(X_train_svm, Y_train_svm, X_train_notsvm, ...
        Y_train_notsvm, k_cubic); 
%     [test_error_gaussian(i) info] = kernelized_svm(X_train, Y_train, X_test, ...
%         Y_test, k_gaussian);
    
            
    % Now, using the output probabilities, train the regression model on
    % the remaining portion
    Y_train_reg = Y_train_notsvm;
%     X_train_reg_linear = info_linear.vals;
%     lr_model_linear = train(Y_train_reg, sparse(X_train_reg_linear), '-s 0');
    X_train_reg_cubic = info_cubic.vals;
    lr_model_cubic = train(Y_train_reg, sparse(X_train_reg_cubic), '-s 0');
    
    % Finally, test the performance of the blended model
%     [test_error_linear_svm(i), info_linear] = kernelized_svm(X_train, Y_train, X_test, ...
%         Y_test, k_linear);
%     [pred, acc_linear, est] = predict(Y_test, sparse(info_linear.vals), lr_model_linear, '-b 1');
%     test_error_linear_stack(i) = acc_linear(1)/100;
    
    
    [test_error_cubic_svm(i), info_cubic] = kernelized_svm(X_train, Y_train, X_test, ...
        Y_test, k_cubic);
    [pred, acc_cubic, est] = predict(Y_test, sparse(info_cubic.vals), lr_model_cubic, '-b 1');
    test_error_cubic_stack(i) = 1-acc_cubic(1)/100;
    y_actual(1:numel(pred), i) = Y_test;
    yhat_stack_linear(1:numel(pred), i) = pred;
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