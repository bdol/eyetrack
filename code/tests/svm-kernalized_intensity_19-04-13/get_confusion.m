function C = get_confusion(y, yhat, K)


C = zeros(K, K);
for i=1:numel(y)
    C(y(i), yhat(i)) = C(y(i), yhat(i))+1;
end

C = bsxfun(@rdivide, C, sum(C, 2));