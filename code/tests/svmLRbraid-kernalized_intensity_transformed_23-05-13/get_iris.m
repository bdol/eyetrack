function I_iris = get_iris(I, C)

D = zeros(size(I));
for i=1:3
   I_color = I(:, :, i);
   D(:, :, i) = (I_color-C(i)).^2;
end

I_iris = sum(D, 3);

end