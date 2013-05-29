%% Load data
clear;
dataPath = '~/code/eyetrack_data/cropped_eyes_transformed_tps_corrected/';
[X_left Y_left X_right Y_right, S] = ...
    load_cropped_eyes_intensity(dataPath);

assert(all(all(Y_left==Y_right)));
Y = Y_left(:, 1);
S_ind = Y_left(:, 2);

fprintf('Done!\n');

%%
X = [X_left X_right];
Y2Dpos = get_2D_data_positions(Y);
Ypos_A = class_to_pos(Y, 'A');
Ypos_B = class_to_pos(Y, 'B');

%% Set up cross validation
K = numel(unique(Y));

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

%% Run multiple linear regression on both axes
% Error of using both models
train_error = zeros(N_folds, 1);
test_error = zeros(N_folds, 1);
% Error of each model
train_error_A = zeros(N_folds, 1);
test_error_A = zeros(N_folds, 1);
train_error_B = zeros(N_folds, 1);
test_error_B = zeros(N_folds, 1);

pos_hat = [];
Y_actual = [];
B_coeff_A = {};

% Error from averaging subject image positions
avg_train_error = zeros(N_folds, 1);
avg_test_error = zeros(N_folds, 1);

for i=1:N_folds
    test_idx = logical(test_fold_idx(:, i));
    
    X_train = X(~test_idx, :);
    [coeff, ~, latent] = princomp(X_train, 'econ');
    % Get alpha% of the energy
    a = 0.9;
    latent_c = cumsum(latent)/sum(latent);
    num_comp = find(latent_c<a, 1, 'last');
    pc = coeff(:, 1:num_comp);
    X_train_red = X_train*pc;
    
    X_test = X(test_idx, :);
    X_test_red = X_test*pc;
    % A axis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Y_train_A = Ypos_A(~test_idx);
    Y_test_A = Ypos_A(test_idx);
    
    % Make sure we don't have any invalid distances
    assert(isempty(find(Y_train==-1, 1)));
    assert(isempty(find(Y_test==-1, 1)));
    
    B_A = regress(Y_train_A, X_train_red);
    B_coeff_A{i} = B_A;
    
    Yhat_train_A = X_train_red*B_A;
    Yhat_test_A = X_test_red*B_A;
    
    train_error_A(i) = sum(sqrt((Yhat_train_A-Y_train_A).^2))/size(X_train, 1);
    test_error_A(i) = sum(sqrt((Yhat_test_A-Y_test_A).^2))/size(X_test, 1);
    % A axis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % B axis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Y_train_B = Ypos_B(~test_idx);
    Y_test_B = Ypos_B(test_idx);
    
    % Make sure we don't have any invalid distances
    assert(isempty(find(Y_train==-1, 1)));
    assert(isempty(find(Y_test==-1, 1)));
    
    B_B = regress(Y_train_B, X_train_red);
    B_coeff_B{i} = B_B;
    
    Yhat_train_B = X_train_red*B_B;
    Yhat_test_B = X_test_red*B_B;
    
    train_error_B(i) = sum(sqrt((Yhat_train_B-Y_train_B).^2))/size(X_train, 1);
    test_error_B(i) = sum(sqrt((Yhat_test_B-Y_test_B).^2))/size(X_test, 1);
    % B axis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    P_train = pred_to_pos(Yhat_train_A, Yhat_train_B, Y_train_A, Y2Dpos(~test_idx, :));
    P_test = pred_to_pos(Yhat_test_A, Yhat_test_B);
    
    Y2Dpos_train = Y2Dpos(~test_idx, :);
    Y2Dpos_test = Y2Dpos(test_idx, :);
    
%     train_error(i) = sum(sqrt(sum((P_train-Y2Dpos_train).^2, 2)))/size(X_train, 1);
%     test_error(i) = sum(sqrt(sum(P_test-Y2Dpos_test).^2, 2))/size(X_test, 1);
    
    fprintf('Fold %d.\n\tTrain error (RMSE in.): %f\n\tTest error (RMSE in.): %f\n\n', ...
                i, train_error(i), test_error(i));
            

    % Try subject averaging
    train_subjs = unique(S_ind(~test_idx));
    test_subjs = unique(S_ind(test_idx));
    P_train_avg = zeros(size(P_train));
    P_test_avg = zeros(size(P_test));
    for j=1:numel(train_subjs)
        for k=1:K
            subj_idx = (S_ind(~test_idx)==train_subjs(j)) & Y(~test_idx)==k;
            P_subj = P_train(subj_idx, :);
            P_train_avg(subj_idx, :) = repmat(mean(P_subj), size(P_subj, 1), 1);
        end
    end
    keyboard;
    for j=1:numel(test_subjs)
        for k=1:K
            subj_idx = (S_ind(test_idx)==train_subjs(j)) & Y(test_idx)==k;
            P_subj = P_test(subj_idx, :);
            P_test_avg(subj_idx, :) = repmat(mean(P_subj), size(P_subj, 1), 1);
        end
    end
    
    keyboard;
end

%%
close all;
plot(6.5, 5, 'bx'); hold on;
plot(13, 11, 'bx'); hold on;
plot(20.5, 16, 'bx'); hold on;
plot(27, 22, 'bx'); hold on;
plot(33, 27, 'bx'); hold on;

axis([0 40 0 32])
