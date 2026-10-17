use (import "./deps.ks").*;
use (import "./model.ks").*;
use (import "./assets.ks").*;
use (import "./spatial.ks").*;

module:

const TICK_LERP = 1/60;

const Car = newtype {
	.pos_visual :: Vec2,
	.pos :: Vec2,
	.facing :: Vec2,
	.velocity :: Vec2,
	.turn :: Angle,
};

impl Car as module = (
	module:
	
	const new = () -> Car => {
		.pos = { 0, 0 },
		.pos_visual = { 0, 0 },
		.facing = { 0, 0 },
		.velocity = { 0, 0},
		.turn = Angle.from_degrees(0),
	};

	const update = (self :: &mut Car) => (
        let accelerate :: Float32 = b_to_f32(geng.input.Key.is_pressed(:W)) - b_to_f32(geng.input.Key.is_pressed(:S));
        let steer :: Float32 = b_to_f32(geng.input.Key.is_pressed(:A)) - b_to_f32(geng.input.Key.is_pressed(:D));

        let speed :: Float32 = 1.0;
        let steer_speed :: Float32 = 0.05;

		self^.turn.radians += steer * steer_speed; 
		self^.facing.0 = math.cos(self^.turn.radians);
		self^.facing.1 = math.sin(self^.turn.radians);

		self^.velocity.0 += self^.facing.0 * (accelerate * speed); 
		self^.velocity.1 += self^.facing.1 * (accelerate * speed); 

		self^.velocity = Vec2.mul(self^.velocity, 0.25);
		# self^.turn.radians *= 0.8;

		self^.pos = Vec2.add(self^.pos, self^.velocity);
	);

	const draw = (self :: &mut Car) => (        
        Model.draw(&(@current Assets.Ctx)^.tv, Mat4.translate({ 0, 0, 0 }));

        self^.pos_visual = self^.pos;
		# self^.pos_visual = {
		# 	lerp(self^.pos_visual.0, self^.pos.0, TICK_LERP),
		# 	lerp(self^.pos_visual.1, self^.pos.1, TICK_LERP),
		# };

        Model.draw(&(@current Assets.Ctx)^.model_t,
        	Mat4.translate({ ...(self^.pos_visual) ,0 }) |>
	        Mat4.mul_mat(
	        	Mat4.rotate_z(Vec2.arg(self^.facing))
	        )
        );
	);	 
);

const World = newtype {
    .camera :: geng.Camera,
    .camera_rotation :: Angle,
    .car :: Car,
};

impl World as module = (
	module:

	const new = () -> World => (
	let angle = Angle.from_degrees(90);
	{
        .camera = {
            .position = { 0, 0, 0 },
            .distance = 10,
            .rotation = angle,
            .attack = Angle.from_degrees(45),
            .fov = Angle.from_degrees(90),
        },
        .camera_rotation = angle,
        .car = Car.new(),
	}); 

	const update = (self :: &mut World) => (
        Car.update(&mut self^.car);
	);

	const draw = (self :: &mut World) => (
		self^.camera_rotation.radians += angular_dist(self^.camera_rotation, Vec2.arg(self^.car.facing)).radians;

		self^.camera.rotation = {
			.radians = lerp(self^.camera.rotation.radians, self^.camera_rotation.radians, 0.1)
		};
	
		let offset = Vec2.rotate({2, 0}, self^.camera.rotation);
		self^.camera.position = { ...Vec2.add(self^.car.pos, offset), 2 };

        let framebuffer_size = geng.get_window_size();
        with geng.CameraUniforms.Ctx = geng.CameraUniforms.init(self^.camera, .framebuffer_size);
        
        Car.draw(&mut self^.car);
	);	 
);

const b_to_f32 = (b :: Bool) -> Float32 => (
	if b then 1 else 0
);


const lerp = (val :: Float32, target :: Float32, scalar :: Float32) -> Float32 => (
	val + (target - val) * scalar	
);

const angular_dist = (a :: Angle, b :: Angle) -> Angle => (
    let mut d :: Float32 = fmod((b.radians - a.radians), (2 * PI));

    if d > PI then (
        d = d - 2 * PI
	) else if d < -PI then (
        d = d + 2 * PI
	);
		
    { .radians = d }
);

const abs = (x :: Float32) -> Float32 => (
    @native "#include <math.h>";
    @native "fabs(\(x))"
);

const fmod = (a :: Float32, b :: Float32) -> Float32 => (
    @native "#include <math.h>";
    @native "fmod(\(a),\(b))"
);
