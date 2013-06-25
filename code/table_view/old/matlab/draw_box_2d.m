function draw_box_2d(B, color)

p1 = B(1, :);
p2 = B(2, :);
p3 = B(3, :);
p4 = B(4, :);
p5 = B(5, :);
p6 = B(6, :);
p7 = B(7, :);
p8 = B(8, :);

% Bottom square
plot([p1(1) p2(1)],[p1(2) p2(2)], color); hold on;
plot([p2(1) p3(1)],[p2(2) p3(2)], color); hold on;
plot([p3(1) p4(1)],[p3(2) p4(2)], color); hold on;
plot([p4(1) p1(1)],[p4(2) p1(2)], color); hold on;
% Sides
plot([p1(1) p5(1)],[p1(2) p5(2)], color); hold on;
plot([p2(1) p6(1)],[p2(2) p6(2)], color); hold on;
plot([p3(1) p7(1)],[p3(2) p7(2)], color); hold on;
plot([p4(1) p8(1)],[p4(2) p8(2)], color); hold on;
% Top square
plot([p6(1) p5(1)],[p6(2) p5(2)], color); hold on;
plot([p7(1) p6(1)],[p7(2) p6(2)], color); hold on;
plot([p8(1) p7(1)],[p8(2) p7(2)], color); hold on;
plot([p5(1) p8(1)],[p5(2) p8(2)], color); hold on;

end