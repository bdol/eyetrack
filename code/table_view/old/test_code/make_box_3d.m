function B = make_box_3d(h)

[xmin ymin zmin xmax ymax zmax] = deal(h(1), h(2), h(3), h(4), h(5), h(6));
B = zeros(8, 3);
B(1, :) = [xmin ymin zmin];
B(2, :) = [xmax ymin zmin];
B(3, :) = [xmax ymax zmin];
B(4, :) = [xmin ymax zmin];
B(5, :) = [xmin ymin zmax];
B(6, :) = [xmax ymin zmax];
B(7, :) = [xmax ymax zmax];
B(8, :) = [xmin ymax zmax];