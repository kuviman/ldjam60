use (import "./deps.ks").*;
use (import "./assets.ks").*;
use (import "./model.ks").*;
use (import "./util.ks").*;
use (import "./pickup.ks").*;

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
	| :Building {
		.height :: Int32,
		.direction :: Angle,
		.road_near :: Bool,
		.pickup :: Option.t[Pickup]
	}
	| :Garage
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
                        .road_near = false,
                        .pickup = :None,
                    }
                )
		 	) else if c == '-' then (
		 		:Road
		 	) else if c == 'g' then (
		 		:Garage
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
                            for &dir in ArrayList.iter(&DIRECTIONS) do (
                                if get_cell(&map, x + dir.0, y + dir.1) is :Road then (
                                    building^.direction = Vec2.arg({
                                        Int32_to_Float32(dir.0),
                                        Int32_to_Float32(dir.1),
                                    });
                                    
                                    building^.road_near = true;
                                    break;
                                );
                            );

                            if not building^.road_near then (
                                cell^ = :Trees;
                            );
                        );
                    )
                    | _ => ()
                );
            );
        );

		let mut pickups = all_pickups();

		while ( ArrayList.length(&pickups) > 0 ) do (
			let x :: Int32 = std.random.gen_range[Int32](.min = 0, .max = width-1);
			let y :: Int32 = std.random.gen_range[Int32](.min = 0, .max = height-1);

			match get_cell_mut(&mut map, x, y) with (
				| :Some cell => (
                    if cell^ is :Building ref mut building then (
						if building^.road_near and Option.is_none(&building^.pickup) then (
							building^.pickup = :Some ArrayList.pop_back(&mut pickups);
						);
                    );
				)
				| _ => ()
			)
		
		);	

        map
	);

	const update = (self :: &mut Map) => (
	);

	# in world space
	const square_intersects = (self :: &Map, pos :: Vec2, size :: Vec2) -> Bool => (
		# car is smaller than buildings
		# we can get away with testing 4 corners against the grid
		# so should be fast
		
		let x0 = to_cell(self, pos.0 - size.0);
		let x1 = to_cell(self, pos.0 + size.0);
		let y0 = to_cell(self, pos.1 - size.1);
		let y1 = to_cell(self, pos.1 + size.1);

		let cx0 = get_cell(self, x0, y0);
		let cx1 = get_cell(self, x1, y0);
		let cy0 = get_cell(self, x1, y1);
		let cy1 = get_cell(self, x0, y1);

		# collides with solid tiles
		   is_solid(cx0)
		or is_solid(cx1)
		or is_solid(cy0)
		or is_solid(cy1)
		or garage_intersects(self, cx0, x0, y0, pos, size) 
		or garage_intersects(self, cx1, x1, y0, pos, size) 
		or garage_intersects(self, cy0, x1, y1, pos, size) 
		or garage_intersects(self, cy1, x0, y1, pos, size)
	);
	
	const garage_intersects = (
		self   :: &Map,
		cell   :: Cell,
		x      :: Int32,
		y      :: Int32,
		pos    :: Vec2,
		size   :: Vec2,
	) -> Bool => (
		if Map.is_garage(cell) then (
			let unit :: Float32 = self^.scale;
			let t :: Float32 = 1/20 * unit;

			   # back wall
				Map.rect_intersects(
			   		{
				   		Int32_to_Float32(x)*unit,
				   		Int32_to_Float32(y)*unit + unit/2 - t
			   		},
			   		{
			   			unit/2,
			   			t,
				   	},
				   	pos,
				   	size
				)

			 	# right wall
			or  Map.rect_intersects(
			   		{
				   		Int32_to_Float32(x)*unit + unit/2 - t,
				   		Int32_to_Float32(y)*unit - t*2,
			   		},
			   		{
			   			t,
			   			unit/2 - t * 2,
				   	},
				   	pos, size
				)

				# left wall
			or  Map.rect_intersects(
			   		{
				   		Int32_to_Float32(x)*unit - unit/2 + t,
				   		Int32_to_Float32(y)*unit - t*2,
			   		},
			   		{
			   			t,
			   			unit/2 - t * 2,
				   	},
				   	pos, size
				)
		) else (
			false
		)
	);

	const rect_intersects = (
		pos_a  :: Vec2,
		size_a :: Vec2,
		pos_b  :: Vec2,
		size_b :: Vec2 
	) -> Bool => (
		    abs(pos_a.0 - pos_b.0) <= size_a.0 + size_b.0
		and abs(pos_a.1 - pos_b.1) <= size_a.1 + size_b.1
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
	const is_solid = (cell :: Cell) -> Bool => (
        match cell with (
            | :Building { ... } => true
            | :Trees => true
            | _ => false
        )
	);

	const is_garage = (cell :: Cell) -> Bool => (
        match cell with (
            | :Garage => true
            | _ => false
        )
	);

	const draw = (self :: &mut Map, pickups :: &ArrayList.t[Pickup]) => (
        let assets = @current Assets.Ctx;
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
				| :Building { .height, .direction, .pickup, ... } => (
                    let height = 1;
			    	for z in 0..height do (
					    Model.draw(&assets^.building,
					    	matrix
                                |> Mat4.mul_mat(Mat4.rotate_z(direction))
				    	);
					);

                    if pickup is :Some pickup then (
                        Model.draw(pickup_model(pickup, &assets^.items),
                            matrix
                            |> Mat4.mul_mat(Mat4.rotate_z(direction))
                            |> Mat4.mul_mat(Mat4.translate({4, -1, 0.3}))
                        );
                    );
				)
				| :Garage => (
                    Model.draw(&assets^.garage,
                        matrix
                    );
                    for &pickup in pickups |> ArrayList.iter do (
                        Model.draw(pickup_model(pickup, &assets^.board), matrix);
                    );
                )
				| :Trees => (
                    Model.draw(&assets^.trees,
                        matrix
                    );
                )
				| :Road => (
                    for &dir in ArrayList.iter(&DIRECTIONS) do (
                        let model = match get_cell(&self^, x + dir.0, y + dir.1) with (
                            | :Road => &assets^.road.connected
                            | _ => &assets^.road.disconnected
                        );
                        let rotation = Vec2.arg({
                            Int32_to_Float32(dir.0),
                            Int32_to_Float32(dir.1),
                        });
                        Model.draw(model,
                            matrix
                                |> Mat4.mul_mat(Mat4.rotate_z(rotation))
                        );
                    );
                )
				| :Empty => ()
			);

			i += 1;
		);
	);
	
);
