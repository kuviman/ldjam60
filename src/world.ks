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

		# DO NOT QUESTION MY LEVEL EDITOR
		let mut sb = std.StringBuilder.new();
		&mut sb |> std.StringBuilder.add_str("########\n");
		&mut sb |> std.StringBuilder.add_str("#------#\n");
		&mut sb |> std.StringBuilder.add_str("#-####-#\n");
		&mut sb |> std.StringBuilder.add_str("#----#-#\n");
		&mut sb |> std.StringBuilder.add_str("#-g--#-#\n");
		&mut sb |> std.StringBuilder.add_str("#---##-#\n");
		&mut sb |> std.StringBuilder.add_str("#------#\n");
		&mut sb |> std.StringBuilder.add_str("########\n");
		
	    let map = Map.from_str(String.as_str(&std.StringBuilder.into_string(sb)));
	    let spawn :: Vec2 = {
	    	Int32_to_Float32(map.width)/2 * map.scale,
	    	Int32_to_Float32(map.height)/2 * map.scale,
	    };
	{
        .camera = {
            .position = { 0, 0, 0 },
            .distance = 5,
            .rotation = angle,
            .attack = Angle.from_degrees(10),
            .fov = Angle.from_degrees(90),
        },
        .camera_rotation = angle,
        .car = Car.new(spawn),
        .map = map,
	}); 

	const update = (self :: &mut World) => (
        Car.update(&mut self^.car, &self^.map);
	);

	const draw = (self :: &mut World, .update_camera :: Bool, alpha :: Float32) => (
        if update_camera then (
            self^.camera_rotation.radians += angular_dist(self^.camera_rotation, Vec2.arg(self^.car.facing)).radians;
            self^.camera.rotation = {
                .radians = lerp(self^.camera.rotation.radians, self^.camera_rotation.radians, 0.05)
            };
        ) else (
            # =)
            self^.camera_rotation = self^.camera.rotation;
        );
	
		self^.camera.position = { ...Car.visual_pos(&self^.car, alpha), 1.5 };

        let framebuffer_size = geng.get_window_size();
        with geng.CameraUniforms.Ctx = geng.CameraUniforms.init(self^.camera, .framebuffer_size);
        
        Map.draw(&mut self^.map);
        Car.draw(&mut self^.car, alpha);
	);	 
);
