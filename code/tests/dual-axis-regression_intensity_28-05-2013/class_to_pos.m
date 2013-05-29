function P = class_to_pos(Y, axis)
% Returns the linear position of a class on axis passed with the 'axis'
% parameter (can either be 'A' or 'B')


P = zeros(size(Y, 1), 1);
for i=1:size(Y, 1)
    P(i) = get_dist(Y(i), axis);
end

end


function d = get_dist(y, axis)

if strcmp(axis, 'A')
    if y==1
        d = -sqrt(sum(([6.5 5] - [20.5 16]).^2));
    elseif y==6
        d = -sqrt(sum(([13 11]-[20.5 16]).^2));
    elseif y==5
        d = 0;
    elseif y==8
        d = sqrt(sum(([27 22]-[20.5 16]).^2));
    elseif y==3
        d = sqrt(sum(([33 27]-[20.5 16]).^2));
    else % Project to the middle position
        d = 0;
    end
elseif strcmp(axis, 'B')
    if y==2
        d = -sqrt(sum(([33 5]-[20.5 16]).^2));
    elseif y==7
        d = -sqrt(sum(([27 11]-[20.5 16]).^2));
    elseif y==5
        d = 0;
    elseif y==9
        d = sqrt(sum(([13 22]-[20.5 16]).^2));
    elseif y==4
        d = sqrt(sum(([6.5 27]-[20.5 16]).^2));
    else % Project to the middle position
        d = 0;
    end
end

end