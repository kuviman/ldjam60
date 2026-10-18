use (import "./deps.ks").*;
use (import "./assets.ks").*;
use (import "./model.ks").*;
use (import "./util.ks").*;

module:

const Cell = newtype (
	| :Building { .height :: Int32 }
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
		 		:Building { .height = std.random.gen_range(.min = 1, .max = 4)}
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

		Map.new (
			width,
			ArrayList.length(&cells)/width,
			cells,
		)
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

	# in grid space
	const cell_intersects = (self :: &Map, x :: Int32, y :: Int32) -> Bool => (
		if x < 0 or y < 0 or x >= self^.width or y >= self^.height then (
	      false
	    ) else (
			let cell = ArrayList.at(
				&self^.cells,
				y * self^.width + x
			);

			match cell^ with (
				| :Building { ... } => true
				| _ => false
			)
		)
	);

	const draw = (self :: &mut Map) => (
		# no iteri saj
		let mut i :: Int32 = 0;
		for &cell in ArrayList.iter(&self^.cells) do (
			let x = i % self^.width;
			let y = i / self^.width;

			match cell with (
				| :Building { .height = height } => (
			    	for z in 0..height do (
					    Model.draw(&(@current Assets.Ctx)^.building,
					    	Mat4.translate({
						    	Int32_to_Float32(x)*self^.scale,
						    	Int32_to_Float32(y)*self^.scale,
						    	Int32_to_Float32(z)*self^.scale, # half extents
						    })
				    	);
					);
				)
				| :Road => ()
				| :Empty => ()
			);

			i += 1;
		);
	);
	
);
