function C = get_iris_color(I, h, w, s)

I_center = I(h/2-s/2+1:h/2+s/2, w/2-s/2+1:w/2+s/2, :);
avgColor = mean(mean(I_center));
C = zeros(3, 1);
C(1) = avgColor(1);
C(2) = avgColor(2);
C(3) = avgColor(3);

end