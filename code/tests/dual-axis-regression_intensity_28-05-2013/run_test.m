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
% Axis A goes from top left to bottom right, and includes the numbers 1, 6,
% 5, 8, 3
axisAidx = Y(:, 1)==1 | ...
           Y(:, 1)==6 | ...
           Y(:, 1)==5 | ...
           Y(:, 1)==8 | ...
           Y(:, 1)==3;

% Axis B goes from top right to bottom left, and includes the numbers 2, 7,
% 5, 9, 4
axisBidx = Y(:, 1)==2 | ...
           Y(:, 1)==7 | ...
           Y(:, 1)==5 | ...
           Y(:, 1)==9 | ...
           Y(:, 1)==4;

X = [X_left X_right];

X_A = X(axisAidx, :);
Y_A = Y(axisAidx);

S_ind_A = S_ind(axisAidx);

X_B = X(axisBidx, :);
Y_B = Y(axisBidx);
S_ind_B = S_ind(axisBidx);

Y_P = class_to_pos_A(Y);

%% Set up cross validation for A axis
K_A = numel(unique(Y_A));

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

%% Run multiple linear regression on A axis
train_error = zeros(N_folds, 1);
test_error = zeros(N_folds, 1);
pos_hat = [];
Y_actual = [];
B_coeff = {};

for i=1:N_folds
    test_idx = logical(test_fold_idx(:, i));
    
    X_train = X((~test_idx & axisAidx), :);
    [coeff, ~, latent] = princomp(X_train, 'econ');
    % Get alpha% of the energy
    a = 0.9;
    latent_c = cumsum(latent)/sum(latent);
    num_comp = max(find(latent_c<a));
    pc = coeff(:, 1:num_comp);
    X_train_red = X_train*pc;
    Y_train = Y_P((~test_idx & axisAidx));
    
    X_test = X((test_idx & axisAidx), :);
    X_test_red = X_test*pc;
    Y_test = Y_P((test_idx & axisAidx));
    
    % Make sure we don't have any invalid distances
    assert(isempty(find(Y_train==-1, 1)));
    assert(isempty(find(Y_test==-1, 1)));
    
    B = regress(Y_train, X_train_red);
    B_coeff{i} = B;
    
    Yhat_train = X_train_red*B;
    train_error(i) = sum(sqrt((Yhat_train-Y_train).^2))/size(X_train, 1);
    
    Yhat_test = X_test_red*B;
    test_error(i) = sum(sqrt((Yhat_test-Y_test).^2))/size(X_test, 1);
    
    fprintf('Fold %d.\n\tTrain error (RMSE in.): %f\n\tTest error (RMSE in.): %f\n\n', ...
                i, train_error(i), test_error(i));
            
    pos_hat = [pos_hat; Yhat_test];
    Y_actual = [Y_actual; Y(test_idx & axisAidx)];
end

%%
close all;
plot(6.5, 5, 'bx'); hold on;
plot(13, 11, 'bx'); hold on;
plot(20.5, 16, 'bx'); hold on;
plot(27, 22, 'bx'); hold on;
plot(33, 27, 'bx'); hold on;

axis([0 40 0 32])
