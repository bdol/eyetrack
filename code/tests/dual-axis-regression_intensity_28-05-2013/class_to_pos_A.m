function P = class_to_pos_A(Y)
% Returns the linear position of a class on the A axis.
% Computes the distance from the top-left position, #1.

P = zeros(size(Y, 1), 1);
for i=1:size(Y, 1)
    P(i) = get_dist(Y(i));
end

end


function d = get_dist(y)

if y==1
    d = 0;
elseif y==6
    d = sqrt(sum(([13 11]-[6.5 5]).^2));
elseif y==5
    d = sqrt(sum(([20.5 16]-[6.5 5]).^2));
elseif y==8
    d = sqrt(sum(([27 22]-[6.5 5]).^2));
elseif y==3
    d = sqrt(sum(([33 27]-[6.5 5]).^2));
else
    d = -1;
end

end