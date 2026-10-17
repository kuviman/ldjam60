use (import "./deps.ks").*;
use (import "./assets.ks").*;
use (import "./model.ks").*;

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
		.scale = 4.0,
		.cells = cells,
	};

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

	const car_collides = (self :: &mut Map) => (
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
					    Model.draw(&(@current Assets.Ctx)^.tv,
					    	Mat4.translate({
						    	Int32_to_Float32(x)*self^.scale,
						    	Int32_to_Float32(y)*self^.scale,
						    	Int32_to_Float32(z)*self^.scale,
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
