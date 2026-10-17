use (import "./deps.ks").*;
use (import "./assets.ks").*;
use (import "./model.ks").*;

module:

const Cell = newtype (
	| :Building
	| :Road
	| :Empty
);

const Map = newtype {
	.width :: Int32,
	.height :: Int32,
	.cells :: ArrayList.t[Cell],
};

impl Map as module = (
	module:

	const new = (width :: Int32, height :: Int32) -> Map => {
		.width = width,
		.height = height,
		.cells = ArrayList.new(),
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
		 		:Building
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

		{
			.width = width,
			.height = ArrayList.length(&cells)/width,
			.cells = cells
		}
	);

	const update = (self :: &mut Map) => (
	);

	const draw = (self :: &mut Map) => (
		# no iteri saj
		let mut i :: Int32 = 0;
		let scale = 2.0;
		for &cell in ArrayList.iter(&self^.cells) do (

			let x = i % self^.width;
			let y = i / self^.width;

			match cell with (
				| :Building => (
				    Model.draw(&(@current Assets.Ctx)^.tv, Mat4.translate({ Int32_to_Float32(x)*scale, Int32_to_Float32(y)*scale, 0 }));
				)
				| :Road => ()
				| :Empty => ()
			);

			i += 1;
		);
	);
	
);
