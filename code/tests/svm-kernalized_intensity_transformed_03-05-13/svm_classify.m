function [test_err yhat] = svm_classify(X, Y, labels)
    addpath libsvm;
    addpath kernels;
    
    errs = zeros(length(Y), 1);
    
    k_linear = @(x, x2)kernel_poly(x, x2, 1);
    k_quadratic = @(x, x2)kernel_poly(x, x2, 2);
    k_cubic = @(x, x2)kernel_poly(x, x2, 3);
    k_gaussian = @(x, x2)kernel_gaussian(x, x2, 100);
        
    test_err = zeros(length(Y), 1);
    yhat = zeros(length(Y), 1);

    % Leave one out cross-validation
    parfor k=1:length(Y)
       fprintf('Classifying %s\n', labels(k).file_location);
       Xtest = X(k, :);
       Ytest = Y(k, :);
       
       % Remove songs from the same album to avoid album effect
       % Also removes test example
       album = Y(k, 2);
       Xtrain = X;
       Xtrain(Y(:, 2)==album, :) = [];
       Ytrain = Y;
       Ytrain(Y(:, 2)==album, :) = [];
       
       [test_err(k) info] = kernelized_svm(Xtrain, Ytrain(:, 1), Xtest, ...
                                Ytest(:, 1), k_linear);
       yhat(k) = info.yhat;
    end