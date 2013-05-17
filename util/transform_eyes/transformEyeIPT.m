function T = transformEyeIPT(w, h, centroid, imorig, t)

imh = size(imorig, 1);
imw = size(imorig, 2);

T = zeros(h, w, 3);
[X Y] = meshgrid(linspace(-w/2+1, w/2, w), linspace(-h/2+1, h/2, h));
X = X(:);
Y = Y(:);
[u v] = tforminv(t, X, Y);

for i=1:numel(X)
    pim = zeros(2, 1);
    pim(1) = floor(u(i)+centroid(1));
    pim(2) = floor(v(i)+centroid(2));
    
    if (pim(1)>1 && pim(1)<imw && pim(2)>1 && pim(2)<imh)
        T(Y(i)+h/2, X(i)+w/2, :) = imorig(pim(2), pim(1), :);
    end
end

end