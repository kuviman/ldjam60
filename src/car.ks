use (import "./deps.ks").*;
use (import "./assets.ks").*;
use (import "./model.ks").*;
use (import "./util.ks").*;
use (import "./map.ks").*;
use (import "./pickup.ks").*;

module:

const Car = newtype {
	.size :: Vec2,
	.prev_pos :: Vec2,
	.pos :: Vec2,
	.facing :: Vec2,
	.velocity :: Vec2,
	.prev_turn :: Angle,
	.turn :: Angle,
    .steer :: Float32,
    .wheel_rotation :: Angle,
    .pickup :: Option.t[Pickup],
    .pickups :: ArrayList.t[Pickup],
    .stun_timer :: Float32,
    .victory :: Bool,
};

impl Car as module = (
	module:
	
	const new = (pos :: Vec2) -> Car => {
		.prev_pos = pos,
		.pos = pos,
		.facing = { 0, 0 },
		.velocity = { 0, 0 },
		.size = { 1, 1 },
		.turn = Angle.from_degrees(90),
		.prev_turn = Angle.from_degrees(90),
        .wheel_rotation = Angle.from_degrees(0),
        .steer = 0,
        .pickup = :None,
        .pickups = ArrayList.new(),
        .stun_timer = 0,
        .victory = false,
	};

	const update = (self :: &mut Car, map :: &mut Map, delta_time :: Float32) => (
		self^.stun_timer = max(0, self^.stun_timer - delta_time);


		let mut stopwatch_multiplier = 1;
		let mut phone_multiplier = 1;
		let mut radio_bonus = 0;
		let mut bounce = 0;

		for pickup in ArrayList.iter(&self^.pickups) do (
			match pickup with (
				| &(:Stopwatch) => (
					stopwatch_multiplier = 1.25;
				)
				| &(:Phone) => (
					phone_multiplier = 1.25;
				)
				| &(:Radio) => (
					radio_bonus = 0.01;
				)
				| &(:Tv) => (
					bounce = 0.25;
				)
				| _ => ()
			);
		);
		
		self^.prev_pos = self^.pos;
		self^.prev_turn = self^.turn;
		
		let len = Vec2.length(self^.velocity);

        let mut accelerate :: Float32 =
        (
        	if self^.stun_timer == 0 then (
		        b_to_f32(geng.input.Key.is_pressed(:W)) - b_to_f32(geng.input.Key.is_pressed(:S))	
	        ) else (
	        	0
	        )
        );

        if accelerate < 0 then (
    		accelerate = -0.5;
	    );

        let steer :: Float32 =
        (
        	if self^.stun_timer == 0 then (
	        	b_to_f32(geng.input.Key.is_pressed(:A)) - b_to_f32(geng.input.Key.is_pressed(:D))
	        ) else (
	        	0
	        )
		);
        
        self^.steer = steer;

        let speed :: Float32 = 0.025 * stopwatch_multiplier;
        let steer_speed :: Float32 = 0.15 * phone_multiplier;

		self^.turn.radians += steer * steer_speed * (Vec2.dot(self^.velocity, self^.facing)); 
		self^.facing.0 = math.cos(self^.turn.radians);
		self^.facing.1 = math.sin(self^.turn.radians);

		self^.velocity.0 += self^.facing.0 * (accelerate * speed); 
		self^.velocity.1 += self^.facing.1 * (accelerate * speed); 

		let friction = 0.05 - radio_bonus;
		self^.velocity = Vec2.sub(self^.velocity, Vec2.mul(self^.velocity, friction));

		let vel_dir = Vec2.normalize_or_zero(self^.velocity);

		# good ol sara spalding's collision code
		if Car.collides(&self^, &map^, Vec2.add(self^.pos, { self^.velocity.0, 0 }) ) then (
			let mut bonk = false;
			if abs(self^.velocity.0) > 0.15 then (
				if self^.stun_timer == 0 then (
					self^.stun_timer > 0; 			
				);

		        let options :: geng.audio.PlayOptions = {
		            .@"loop" = false,
		            .volume = 0.75,
		        };
		        geng.audio.play_with(&(@current Assets.Ctx)^.bonk, options);
		        bonk = true;
			);

			while abs(self^.velocity.0) > 0.4 do (
				self^.velocity.0 *= 0.5;
				if (not Car.collides(&self^, &map^, Vec2.add(self^.pos, {self^.velocity.0, 0}) )) then (
					self^.pos.0 += self^.velocity.0;
				);
			);
						
			if bonk then (
				self^.velocity.0 = -bounce*vel_dir.0;
				self^.velocity.1 = bounce*vel_dir.1;
			) else (
				self^.velocity.0 = 0;
			);
		);

		self^.pos.0 += self^.velocity.0;

		if Car.collides(&self^, &map^, Vec2.add(self^.pos, { 0, self^.velocity.1 }) ) then (
			let mut bonk = false;
			if abs(self^.velocity.1) > 0.15 then (
				if self^.stun_timer == 0 then (
					self^.stun_timer > 0; 			
				);

		        let options :: geng.audio.PlayOptions = {
		            .@"loop" = false,
		            .volume = 0.75,
		        };
		        geng.audio.play_with(&(@current Assets.Ctx)^.bonk, options);

		        bonk = true;
			);

			while abs(self^.velocity.1) > 0.1 do (
				self^.velocity.1 *= 0.5;

				if (not Car.collides(&self^, &map^, Vec2.add(self^.pos, {0, self^.velocity.1}) )) then (
					self^.pos.1 += self^.velocity.1;
				);
			);	

			if bonk then (
				self^.velocity.0 = bounce*vel_dir.0;
				self^.velocity.1 = -bounce*vel_dir.1;
			) else (
				self^.velocity.1 = 0;
			);
		);

		self^.pos.1 += self^.velocity.1;

        self^.wheel_rotation = Angle.add(
            self^.wheel_rotation,
            Angle.mul(Angle.from_degrees(100), Vec2.dot(self^.velocity, self^.facing)),
        );


        # pickups
		if Option.is_none(&self^.pickup) then (

			let x0 = Map.to_cell(&map^, self^.pos.0);
			let y0 = Map.to_cell(&map^, self^.pos.1) - 1;

			let x1 = Map.to_cell(&map^, self^.pos.0) + 1;
			let y1 = Map.to_cell(&map^, self^.pos.1);

			let x2 = Map.to_cell(&map^, self^.pos.0);
			let y2 = Map.to_cell(&map^, self^.pos.1) + 1;

			let x3 = Map.to_cell(&map^, self^.pos.0) - 1;
			let y3 = Map.to_cell(&map^, self^.pos.1);

			let mut result = grab_pickup(self, map, x0, y0);
			if Option.is_none(&result) then (
				result = grab_pickup(self, map, x1, y1);
			);
			if Option.is_none(&result) then (
				result = grab_pickup(self, map, x2, y2)
			);
			if Option.is_none(&result) then (
				result = grab_pickup(self, map, x3, y3)
			);

			self^.pickup = result;
		);


        if self^.pickup is :Some ref mut pickup then (
			let x = Map.to_cell(&map^, self^.pos.0);
			let y = Map.to_cell(&map^, self^.pos.1);

			if Map.is_garage(Map.get_cell(&map^, x, y)) then (
				ArrayList.push_back(&mut self^.pickups, pickup^);
				self^.pickup = :None;
			);
		);

		# WIN
		if ArrayList.length(&self^.pickups) == 4 then (
			let x = Map.to_cell(&map^, self^.pos.0);
			let y = Map.to_cell(&map^, self^.pos.1);

			if Map.is_finish(Map.get_cell(&map^, x, y)) then (
				self^.victory = true;

				dbg.print("you won");
			);
		);
	);

	const grab_pickup = (self :: &mut Car, map :: &mut Map, x :: Int32, y :: Int32) -> Option.t[Pickup] => with_return (
		match Map.get_cell_mut(map, x, y) with (
			| :Some cell => (
                if cell^ is :Building ref mut building then (
					if Option.is_some(&building^.pickup) then (
						# checked in grid space
			            let mut pickup_pos :: Vec2 = Vec2.rotate({
			                4/map^.scale,
			                -1/map^.scale,
			            }, building^.direction);
									
			            pickup_pos.0 += Int32_to_Float32(x);
			            pickup_pos.1 += Int32_to_Float32(y);

				    	let pickup_range :: Float32 = 0.4;

				    	let dist = Vec2.length(Vec2.sub({pickup_pos.0, pickup_pos.1}, Vec2.div(self^.pos, map^.scale)));

				    	if dist < pickup_range then (
				    		let pickup = building^.pickup;
				    		building^.pickup = :None;

				    		return pickup;
					    );
					);
                );
			)
			| _ => ()
		);

		:None
	);

	const collides = (self :: &Car, map :: &Map, pos :: Vec2) -> Bool => (
		Map.square_intersects(map, pos, self^.size)
	);

    const visual_pos = (self :: &Car, alpha :: Float32) -> Vec2 => {
        lerp(self^.prev_pos.0, self^.pos.0, alpha),
        lerp(self^.prev_pos.1, self^.pos.1, alpha),
    };

    const visual_turn = (self :: &Car, alpha :: Float32) -> Angle => {
            .radians = self^.prev_turn.radians + angular_dist(self^.prev_turn, self^.turn).radians * alpha,
    };

	const draw = (self :: &mut Car, alpha :: Float32) => (        
        let assets = @current Assets.Ctx;

		let matrix = Mat4.translate({ ...visual_pos(&self^, alpha), 0 }) |>
                     Mat4.mul_mat(Mat4.rotate_z(visual_turn(&self^, alpha)));

        if self^.pickup is :Some pickup then (
            Model.draw(&assets^.hand, matrix);
            Model.draw(pickup_model(pickup, &assets^.pickups), matrix);
        );

        Model.draw(&assets^.model_t.body, matrix);

        const WHEEL_DX_BACK :: Float32 = -0.608026;
        const WHEEL_DX_FRONT :: Float32 = 0.59219;
        const WHEEL_DY :: Float32 = 0.450215;
        const WHEEL_DZ :: Float32 = 0.229177;

        let draw_wheel = (dx, dy, steer) => (
            Model.draw(&assets^.model_t.wheel,
                matrix
                    |> Mat4.mul_mat(Mat4.translate({ dx, dy, WHEEL_DZ }))
                    |> Mat4.mul_mat(Mat4.rotate_z(Angle.from_degrees(steer * 45)))
                    |> Mat4.mul_mat(Mat4.rotate_y(self^.wheel_rotation))
            );
        );

        draw_wheel(WHEEL_DX_BACK, +WHEEL_DY, 0);
        draw_wheel(WHEEL_DX_BACK, -WHEEL_DY, 0);
        draw_wheel(WHEEL_DX_FRONT, +WHEEL_DY, self^.steer);
        draw_wheel(WHEEL_DX_FRONT, -WHEEL_DY, self^.steer);

        for &pickup in &self^.pickups |> ArrayList.iter do (
            Model.draw(pickup_model(pickup, &assets^.upgrades), matrix);
        );
	);	 
);
