use (import "./deps.ks").*;
use (import "./assets.ks").*;
use (import "./model.ks").*;
use (import "./util.ks").*;
use (import "./map.ks").*;

module:

const Car = newtype {
	.pos_visual :: Vec2,
	.pos :: Vec2,
	.facing :: Vec2,
	.velocity :: Vec2,
	.turn :: Angle,
    .steer :: Float32,
    .wheel_rotation :: Angle,
};

impl Car as module = (
	module:
	
	const new = (pos :: Vec2) -> Car => {
		.pos = pos,
		.pos_visual = pos,
		.facing = { 0, 0 },
		.velocity = { 0, 0},
		.turn = Angle.from_degrees(0),
        .wheel_rotation = Angle.from_degrees(0),
        .steer = 0,
	};

	const update = (self :: &mut Car, map :: &Map) => (
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
		let car_size = 1.0;
		if Map.square_intersects(map, Vec2.add(self^.pos, { self^.velocity.0, 0 }), car_size) then (
			while abs(self^.velocity.0) > 0.1 do (
				self^.velocity.0 *= 0.5;
				if (not Map.square_intersects(map, Vec2.add(self^.pos, {self^.velocity.0, 0}), car_size)) then (
					self^.pos.0 += self^.velocity.0;
				);
			);
						
			self^.velocity.0 = 0;
		);

		self^.pos.0 += self^.velocity.0;

		if Map.square_intersects(map, Vec2.add(self^.pos, { 0, self^.velocity.1 }), car_size ) then (
			while abs(self^.velocity.1) > 0.1 do (
				self^.velocity.1 *= 0.5;

				if (not Map.square_intersects(map, Vec2.add(self^.pos, {0, self^.velocity.1}), car_size)) then (
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

	const draw = (self :: &mut Car) => (        
        let assets = @current Assets.Ctx;
        self^.pos_visual = self^.pos;
		self^.pos_visual = {
			lerp(self^.pos_visual.0, self^.pos.0, PHYSICS_LERP),
			lerp(self^.pos_visual.1, self^.pos.1, PHYSICS_LERP),
		};

        let matrix = Mat4.translate({ ...(self^.pos_visual) ,0 }) |>
	        Mat4.mul_mat(
	        	Mat4.rotate_z(Vec2.arg(self^.facing))
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
	);	 
);
