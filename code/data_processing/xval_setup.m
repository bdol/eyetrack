function xval = xval_setup(N, N_folds, varargin)
% Given the number of elements in the training set N and the number of
% folds of xval required, N_folds, the function generates an array of a
% structure containing a list of indices for training and testing in each
% fold
% INPUTS: 
%       N: # of training elements
%       N_folds: # of folds of xval
%       subjectwise_split: (optional) 1 to split data that necessarily keeps all data
%           from a given subject within a fold instead of treating all of the
%           data as a single chunk
%       num_per_subj: number of frames captured for each subject
% OUTPUT:
%       xval: structure array of size N_foldsx1
%           xval(i).train_indices = indices of the ith fold to train on
%           xval(i).test_indices = indices of the ith fold to test on

if(nargin>2)&&(nargin==4)
    subjectwise_split = varargin{1};
    num_per_subj = varargin{2};
else
    subjectwise_split = 0;
end

xval = struct('train_indices', {}, 'test_indices', {});
    
if(~subjectwise_split)
    boxes = round(linspace(1,N,N_folds+1));
    arr = [1:N_folds];
    mixed_up_N = randperm(N);
    for fold = 1:N_folds-1
        a = ones(N,1);
        a(mixed_up_N(boxes(arr==fold):boxes(arr==fold +1)-1)) = 0;
        xval(fold).train_indices = find(a);
        xval(fold).test_indices = find(~a);
    end
    fold = fold + 1;
    a = ones(N,1);
    a(mixed_up_N(boxes(arr==fold):end)) = 0;
    xval(fold).train_indices = find(a);
    xval(fold).test_indices = find(~a);
else
    M = floor(N./num_per_subj);
    new_N = M*num_per_subj;     % in case we dont have num_per_subj images for each subject
    boxes = round(linspace(1,M,N_folds+1));
    arr = [1:N_folds];
    mixed_up_M = randperm(M);
    for fold = 1:N_folds-1
        a = ones(M,1);
        a(mixed_up_M(boxes(arr==fold):boxes(arr==fold +1)-1)) = 0;
        a = repmat(a,1,num_per_subj);
        b = reshape(a',new_N,1);
        xval(fold).train_indices = find(b);
        xval(fold).test_indices = find(~b);
    end
    fold = fold + 1;
    a = ones(M,1);
    a(mixed_up_M(boxes(arr==fold):end)) = 0;
    a = repmat(a,1,num_per_subj);
    b = reshape(a',new_N,1);
    xval(fold).train_indices = find(b);
    % add any remaining elements to the last fold. They will be <N_folds in number
    xval(fold).train_indices = [xval(fold).train_indices; new_N+1:N];
    xval(fold).test_indices = find(~b);
end