use (import "./deps.ks").*;
use (import "./model.ks").*;
use (import "./assets.ks").*;
use (import "./spatial.ks").*;

module:

const World = newtype {
    .camera :: geng.Camera,
    .car :: Car,
};

impl World as module = (
	module:


	const new = () -> World => {
        .camera = {
            .position = { 0, 0, 0 },
            .distance = 10,
            .rotation = Angle.from_degrees(0),
            .attack = Angle.from_degrees(45),
            .fov = Angle.from_degrees(90),
        },
        .car = Car.new(),
	}; 

	const update = (self :: &mut World) => (
        let dir :: Vec2 = {
        	b_to_f32(geng.input.Key.is_pressed(:A)) - b_to_f32(geng.input.Key.is_pressed(:D)),
        	b_to_f32(geng.input.Key.is_pressed(:W)) - b_to_f32(geng.input.Key.is_pressed(:S)),
        };

        self^.car.facing = dir;
	);	 

	const draw = (self :: &mut World) => (
        let framebuffer_size = geng.get_window_size();
        with geng.CameraUniforms.Ctx = geng.CameraUniforms.init(self^.camera, .framebuffer_size);
        
        Car.draw(&mut self^.car);
	);	 
);

const b_to_f32 = (b :: Bool) -> Float32 => (
	if b then 1 else 0
);

const Car = newtype {
	.pos :: Vec2,
	.facing :: Vec2,
};

impl Car as module = (
	module:
	
	const new = () -> Car => {
		.pos = { 0, 0 },
		.facing = { 0, 0 },
	};
	const update = (self :: &mut Car) => ();	 
	const draw = (self :: &mut Car) => (        
        Model.draw(&(@current Assets.Ctx)^.model_t, Mat4.rotate_z(Vec2.arg(self^.facing)) |> Mat4.mul_mat(Mat4.translate({ ...(self^.pos) ,0 })));
	);	 
);
