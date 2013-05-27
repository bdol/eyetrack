%% Load data
clear;
dataPath = '~/code/eyetrack_data/cropped_eyes_transformed_tps_corrected/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_intensity(dataPath);

ignore_idx = bsxfun(@or, bsxfun(@or, Y_left(:, 1)==6, Y_left(:, 1)==7), bsxfun(@or, Y_left(:, 1)==8, Y_left(:, 1)==9));
X_left(ignore_idx, :) = [];
X_right(ignore_idx, :) = [];
Y_left(ignore_idx, :) = [];
Y_right(ignore_idx, :) = [];
S(ignore_idx) = [];

X_left = bsxfun(@rdivide, X_left, max(X_left, [], 2));
X_right = bsxfun(@rdivide, X_right, max(X_right, [], 2));

%% Set up cross validation
K = numel(unique(Y_left(:, 1)));
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

P_est_linear = {};
P_est_quad = {};
P_est_cubic = {};
Y_actual = {};

linear_vals = {};
quad_vals = {};
cubic_vals = {};

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

    fprintf('Done fold %d.\nTrain Errors:\nLinear:\t%f\nQuad:\t%f\nCubic:\t%f\nTest Errors:\nLinear:\t%f\nQuad:\t%f\nCubic:\t%f\n\n', ...
        i, train_error_linear(i), train_error_quadratic(i), train_error_cubic(i), test_error_linear(i), test_error_quadratic(i), test_error_cubic(i))
    
    P_est_linear{i} = prob_to_point(info_linear.vals);
    P_est_quad{i} = prob_to_point(info_quad.vals);
    P_est_cubic{i} = prob_to_point(info_cubic.vals);
    Y_actual{i} = Y_test;
    
    linear_vals{i} = info_linear.vals;
    quad_vals{i} = info_quad.vals;
    cubic_vals{i} = info_cubic.vals;
end

%%
Y_subjs = {};
% Assign subject numbers to the predictions
for i=1:N_folds
    test_idx = logical(test_fold_idx(:, i));
    subjs = Y_left(test_idx, 2);
    Y_subjs{i} = subjs;
end

%% Get euclidean error for different methods
E_all = [];
E_top = [];
for i=1:N_folds
   E_all = [E_all; get_euclid_error(linear_vals{i}, Y_actual{i})]; 
   E_top = [E_top; get_euclid_error(linear_vals{i}, Y_actual{i}, 5)]; 
end

fprintf('Mean all: %f Std all: %f\n', mean(E_all), std(E_all));
fprintf('Mean top 2: %f Std top 2: %f\n', mean(E_top), std(E_top));

%% Plot the points, with full probabilities
close all;
% Plot 1-4
figure;
colors = {'yx', 'mx', 'cx', 'rx', 'bx', 'bo', 'ko', 'yo', 'mo'}; 
for i=1:N_folds;
    P_est = P_est_linear{i};
    Y = Y_actual{i};
    for j=1:size(P_est, 1)
        if Y(j)<=5
            plot(P_est(j, 1), 32-P_est(j, 2), colors{Y(j)}); hold on;
        end
    end
end
P = get_positions();
for i=1:4
    text(P(i, 1), 32-P(i, 2), num2str(i), 'FontSize', 14);
end

axis([0 40 0 32]);

keyboard;

% Plot 6-9
figure;
colors = {'yx', 'mx', 'cx', 'rx', 'y*', 'bo', 'ro', 'yo', 'mo'}; 
for i=1:N_folds;
    P_est = P_est_linear{i};
    Y = Y_actual{i};
    for j=1:size(P_est, 1)
        if Y(j)>=6
            plot(P_est(j, 1), 32-P_est(j, 2), colors{Y(j)}); hold on;
        end
    end
end
P = get_positions();
for i=6:9
    text(P(i, 1), 32-P(i, 2), num2str(i), 'FontSize', 20);
end

axis([0 40 0 32]);

% Plot 5
figure;
colors = {'yx', 'mx', 'cx', 'rx', 'y*', 'bo', 'ro', 'yo', 'mo'}; 
for i=1:N_folds;
    P_est = P_est_linear{i};
    Y = Y_actual{i};
    for j=1:size(P_est, 1)
        if Y(j)==5
            plot(P_est(j, 1), 32-P_est(j, 2), colors{Y(j)}); hold on;
        end
    end
end
P = get_positions();
for i=5
    text(P(i, 1), 32-P(i, 2), num2str(i), 'FontSize', 20);
end

axis([0 40 0 32]);

%% Plot the points, with top two probabilities
close all;
% Plot 1-4
figure;
colors = {'yx', 'mx', 'cx', 'rx', 'y*', 'bo', 'ko', 'yo', 'mo'}; 
for i=1:N_folds;
    vals = linear_vals{i};
    P_est = prob_to_point(vals, 2);
    Y = Y_actual{i};
    for j=1:size(P_est, 1)
        if Y(j)<=4
            plot(P_est(j, 1), 32-P_est(j, 2), colors{Y(j)}); hold on;
        end
    end
end

P = get_positions();
for i=1:4
    text(P(i, 1), 32-P(i, 2), num2str(i), 'FontSize', 14); hold on;
end

axis([0 40 0 32]);

% Plot 6-9
figure;
colors = {'yx', 'mx', 'cx', 'rx', 'y*', 'bo', 'ro', 'yo', 'mo'}; 
for i=1:N_folds;
    vals = linear_vals{i};
    P_est = prob_to_point(vals, 2);
    Y = Y_actual{i};
    for j=1:size(P_est, 1)
        if Y(j)>=6
            plot(P_est(j, 1), 32-P_est(j, 2), colors{Y(j)}); hold on;
        end
    end
end
P = get_positions();
for i=6:9
    text(P(i, 1), 32-P(i, 2), num2str(i), 'FontSize', 20);
end

axis([0 40 0 32]);

% Plot 5
figure;
colors = {'yx', 'mx', 'cx', 'rx', 'y*', 'bo', 'ro', 'yo', 'mo'}; 
for i=1:N_folds;
    vals = linear_vals{i};
    P_est = prob_to_point(vals, 2);
    Y = Y_actual{i};
    for j=1:size(P_est, 1)
        if Y(j)==5
            plot(P_est(j, 1), 32-P_est(j, 2), colors{Y(j)}); hold on;
        end
    end
end
P = get_positions();
for i=5
    text(P(i, 1), 32-P(i, 2), num2str(i), 'FontSize', 20);
end

axis([0 40 0 32]);