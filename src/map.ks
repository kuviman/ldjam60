use (import "./deps.ks").*;
use (import "./assets.ks").*;
use (import "./model.ks").*;
use (import "./util.ks").*;

const DIRECTIONS :: ArrayList.t[type { Int32, Int32 }] = (
    let mut dirs = ArrayList.new();
    &mut dirs |> ArrayList.push_back({ -1 :: Int32, 0 :: Int32 });
    &mut dirs |> ArrayList.push_back({ 1, 0 });
    &mut dirs |> ArrayList.push_back({ 0, -1 });
    &mut dirs |> ArrayList.push_back({ 0, 1 });
    dirs
);

module:

const Cell = newtype (
	| :Building { .height :: Int32, .direction :: Angle }
    | :Trees
	| :Road
	| :Empty
);

const Map = newtype {
	.width :: Int32,
	.height :: Int32,
	.scale :: Float32,
	.cells :: ArrayList.t[Cell],
};

impl Map as module = (
	module:

	const new = (width :: Int32, height :: Int32, cells :: ArrayList.t[Cell]) -> Map => {
		.width = width,
		.height = height,
		.scale = 10.0,
		.cells = cells,
	};

	# returns world space size
	const size = (self :: &Map) -> Vec2 => (
		{
			Int32_to_Float32(self^.width) * self^.scale,
			Int32_to_Float32(self^.height) * self^.scale,
		}
	);

	const from_str = (s :: &str) -> Map => (
		let mut cells :: ArrayList.t[Cell] = ArrayList.new();
		let mut width :: Int32 = 0;

		for {i :: Int32, c :: Char} in String.iteri(s) do (

			# first newline pos is width
			if width == 0 and c == '\n' then (
				width = i;
			);

			# idk if match works on char		
			let cell = if c == '#' then (
                if std.random.gen_range[Int32](.min = 1, .max = 100) < 10 then (
                    :Trees
                ) else (
                    :Building {
                        .height = std.random.gen_range(.min = 1, .max = 4),
                        .direction = Angle.from_degrees(0),
                    }
                )
		 	) else if c == '-' then (
		 		:Road
		 	) else (
		 		:Empty
		 	);

		 	if c != '\n' then (
			 	ArrayList.push_back(&mut cells, cell);
			);
		);

		if width == 0 then (
			width = ArrayList.length(&cells);
		);
        let height = ArrayList.length(&cells)/width;
		let mut map = Map.new (
			width,
			height,
			cells,
		);

        for x in 0..width do (
            for y in 0..height do (
                match get_cell_mut(&mut map, x, y) with (
                    | :Some cell => (
                        if cell^ is :Building ref mut building then (
                            let mut road_near = false;
                            for &dir in ArrayList.iter(&DIRECTIONS) do (
                                if get_cell(&map, x + dir.0, y + dir.1) is :Road then (
                                    building^.direction = Vec2.arg({
                                        Int32_to_Float32(dir.0),
                                        Int32_to_Float32(dir.1),
                                    });
                                    road_near = true;
                                    break;
                                );
                            );
                            if not road_near then (
                                cell^ = :Trees;
                            );
                        );
                    )
                    | _ => ()
                );
            );
        );

        map
	);

	const update = (self :: &mut Map) => (
	);

	# in world space
	const square_intersects = (self :: &Map, pos :: Vec2, size :: Float32) -> Bool => (
		# car is smaller than buildings
		# we can get away with testing 4 corners against the grid
		# so should be fast
		
		let x0 = to_cell(self, pos.0 - size);
		let x1 = to_cell(self, pos.0 + size);
		let y0 = to_cell(self, pos.1 - size);
		let y1 = to_cell(self, pos.1 + size);

		   cell_intersects(self, x0, y0)
		or cell_intersects(self, x1, y0)
		or cell_intersects(self, x1, y1)
		or cell_intersects(self, x0, y1)
	);

	const to_cell = (self :: &Map, v :: Float32) -> Int32 => (
		Float32_to_Int32(floor(v / self^.scale + 0.5))
	);

    const get_cell_mut = (self :: &mut Map, x :: Int32, y :: Int32) -> Option.t[type (&mut Cell)] => (
		if x < 0 or y < 0 or x >= self^.width or y >= self^.height then (
	        :None
	    ) else (
			:Some ArrayList.at_mut(
				&mut self^.cells,
				y * self^.width + x
			)
        )
    );
    const get_cell = (self :: &Map, x :: Int32, y :: Int32) -> Cell => (
		if x < 0 or y < 0 or x >= self^.width or y >= self^.height then (
	      :Empty
	    ) else (
			let cell = ArrayList.at(
				&self^.cells,
				y * self^.width + x
			);
            cell^
        )
    );

	# in grid space
	const cell_intersects = (self :: &Map, x :: Int32, y :: Int32) -> Bool => (
        match get_cell(self, x, y) with (
            | :Building { ... } => true
            | :Trees => true
            | _ => false
        )
	);

	const draw = (self :: &mut Map) => (
		# no iteri saj
		let mut i :: Int32 = 0;
		for &cell in ArrayList.iter(&self^.cells) do (
			let x = i % self^.width;
			let y = i / self^.width;

            let matrix = Mat4.translate({
                Int32_to_Float32(x)*self^.scale,
                Int32_to_Float32(y)*self^.scale,
                0,
            });

			match cell with (
				| :Building { .height, .direction } => (
                    let height = 1;
			    	for z in 0..height do (
					    Model.draw(&(@current Assets.Ctx)^.building,
					    	matrix
                                |> Mat4.mul_mat(Mat4.rotate_z(direction))
				    	);
					);
				)
				| :Trees => (
                    Model.draw(&(@current Assets.Ctx)^.trees,
                        matrix
                    );
                )
				| :Road => (
                    Model.draw(&(@current Assets.Ctx)^.road.connected,
                        matrix
                    );
                )
				| :Empty => ()
			);

			i += 1;
		);
	);
	
);
