function Ypos = get_2D_data_positions(Y)

P = get_positions();
Ypos = zeros(size(Y, 1), 2);
for i=1:size(Y, 1)
    Ypos(i, :) = P(Y(i), :);
end