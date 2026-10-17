use (import "./deps.ks").*;

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

		 	ArrayList.push_back(&mut cells, cell);
		);

		{
			.width = width,
			.height = ArrayList.length(&cells)/width,
			.cells = cells
		}
	);
);
