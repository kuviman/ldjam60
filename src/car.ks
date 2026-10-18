use (import "./deps.ks").*;
use (import "./assets.ks").*;
use (import "./model.ks").*;
use (import "./util.ks").*;
use (import "./map.ks").*;

module:

const Car = newtype {
	.prev_pos :: Vec2,
	.pos :: Vec2,
	.facing :: Vec2,
	.velocity :: Vec2,
	.prev_turn :: Angle,
	.turn :: Angle,
    .steer :: Float32,
    .wheel_rotation :: Angle,
};

impl Car as module = (
	module:
	
	const new = (pos :: Vec2) -> Car => {
		.prev_pos = pos,
		.pos = pos,
		.facing = { 0, 0 },
		.velocity = { 0, 0},
		.turn = Angle.from_degrees(0),
		.prev_turn = Angle.from_degrees(0),
        .wheel_rotation = Angle.from_degrees(0),
        .steer = 0,
	};

	const update = (self :: &mut Car, map :: &Map) => (
		self^.prev_pos = self^.pos;
		self^.prev_turn = self^.turn;
		
        let accelerate :: Float32 = b_to_f32(geng.input.Key.is_pressed(:W)) - b_to_f32(geng.input.Key.is_pressed(:S));
        let steer :: Float32 = b_to_f32(geng.input.Key.is_pressed(:A)) - b_to_f32(geng.input.Key.is_pressed(:D));
        self^.steer = steer;

        let speed :: Float32 = 0.025;
        let steer_speed :: Float32 = 0.05;

		self^.turn.radians += steer * steer_speed; 
		self^.facing.0 = math.cos(self^.turn.radians);
		self^.facing.1 = math.sin(self^.turn.radians);

		self^.velocity.0 += self^.facing.0 * (accelerate * speed); 
		self^.velocity.1 += self^.facing.1 * (accelerate * speed); 

		let friction_coeff = 0.95;
		self^.velocity = Vec2.mul(self^.velocity, friction_coeff);


		# good ol sara spalding's collision code
		if Car.collides(&self^, map, Vec2.add(self^.pos, { self^.velocity.0, 0 }) ) then (
			while abs(self^.velocity.0) > 0.1 do (
				self^.velocity.0 *= 0.5;
				if (not Car.collides(&self^, map, Vec2.add(self^.pos, {self^.velocity.0, 0}) )) then (
					self^.pos.0 += self^.velocity.0;
				);
			);
						
			self^.velocity.0 = 0;
		);

		self^.pos.0 += self^.velocity.0;

		if Car.collides(&self^, map, Vec2.add(self^.pos, { 0, self^.velocity.1 }) ) then (
			while abs(self^.velocity.1) > 0.1 do (
				self^.velocity.1 *= 0.5;

				if (not Car.collides(&self^, map, Vec2.add(self^.pos, {0, self^.velocity.1}) )) then (
					self^.pos.1 += self^.velocity.1;
				);
			);	

			self^.velocity.1 = 0;
		);

		self^.pos.1 += self^.velocity.1;

        self^.wheel_rotation = Angle.add(
            self^.wheel_rotation,
            Angle.mul(Angle.from_degrees(100), Vec2.dot(self^.velocity, self^.facing)),
        );
	);

	const collides = (self :: &Car, map :: &Map, pos :: Vec2) -> Bool => (
		let car_size :: Vec2 = {1.0, 1.0};
		Map.square_intersects(map, pos, car_size)
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
	);	 
);
