use (import "./deps.ks").*;
use (import "./model.ks").*;
use (import "./assets.ks").*;
use (import "./spatial.ks").*;
use (import "./map.ks").*;
use (import "./util.ks").*;
use (import "./car.ks").*;

module:

const World = newtype {
    .camera :: geng.Camera,
    .camera_rotation :: Angle,
    .car :: Car,
    .map :: Map,
};

impl World as module = (
	module:

	const new = () -> World => (
		let angle = Angle.from_degrees(90);
	    let map = Map.from_str("#---#\n-----\n#---#");
	    let spawn :: Vec2 = {
	    	Int32_to_Float32(map.width)/2 * map.scale,
	    	Int32_to_Float32(map.height)/2 * map.scale,
	    };
	{
        .camera = {
            .position = { 0, 0, 0 },
            .distance = 10,
            .rotation = angle,
            .attack = Angle.from_degrees(45),
            .fov = Angle.from_degrees(90),
        },
        .camera_rotation = angle,
        .car = Car.new(spawn),
        .map = map,
	}); 

	const update = (self :: &mut World) => (
        Car.update(&mut self^.car, &self^.map);
	);

	const draw = (self :: &mut World) => (
		self^.camera_rotation.radians += angular_dist(self^.camera_rotation, Vec2.arg(self^.car.facing)).radians;

		self^.camera.rotation = {
			.radians = lerp(self^.camera.rotation.radians, self^.camera_rotation.radians, 0.05)
		};
	
		let offset = Vec2.rotate({2, 0}, self^.camera.rotation);
		self^.camera.position = { ...Vec2.add(self^.car.pos, offset), 2 };

        let framebuffer_size = geng.get_window_size();
        with geng.CameraUniforms.Ctx = geng.CameraUniforms.init(self^.camera, .framebuffer_size);
        
        Map.draw(&mut self^.map);
        Car.draw(&mut self^.car);
	);	 
);
