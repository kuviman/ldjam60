use (import "./deps.ks").*;
use (import "./model.ks").*;
use (import "./spatial.ks").*;

const Assets = newtype {
    .tv :: Model.t,
    .model_t :: Model.t,
    .test_sfx :: geng.audio.Buffer,
};

impl Assets as module = (
    module:

    const load = () -> Assets => (
        {
            .tv = Model.load("assets/tv"),
            .model_t = Model.load("assets/model_t"),
            .test_sfx = geng.audio.Buffer.load("assets/test.wav"),
        }
    );
);

const Game = newtype {
    .assets :: Assets,
    .camera :: geng.Camera,
    .model_renderer :: Model.Renderer,
    .mouse_captured :: Bool,
    .position :: Vec2,
};

@eval (impl Game as geng.App = {
    .init = () -> Game => {
        .camera = {
            .position = { 0, 0, 0 },
            .distance = 10,
            .rotation = Angle.from_degrees(0),
            .attack = Angle.from_degrees(45),
            .fov = Angle.from_degrees(90),
        },
        .model_renderer = Model.Renderer.init(),
        .assets = Assets.load(),
        .mouse_captured = false,
        .position = { 0, 0 },
    },
    .update = (self :: &mut Game, delta_time :: Float32) => (
        let wasd :: Vec2 = (
            let mut wasd = { 0, 0 };
            if geng.input.Key.is_pressed(:W) then (
                wasd.0 += 1;
            );
            if geng.input.Key.is_pressed(:A) then (
                wasd.1 += 1;
            );
            if geng.input.Key.is_pressed(:S) then (
                wasd.0 -= 1;
            );
            if geng.input.Key.is_pressed(:D) then (
                wasd.1 -= 1;
            );
            wasd
        );
        self^.position = Vec2.add(
            self^.position,
            Vec2.mul(Vec2.rotate(wasd, self^.camera.rotation), delta_time),
        );
    ),
    .handle_event = (self :: &mut Game, event :: geng.Event) => (
        match event with (
            | :KeyPress :Space => (
                let options :: geng.audio.PlayOptions = {
                    .@"loop" = false,
                    .volume = 1,
                };
                geng.audio.play_with(&self^.assets.test_sfx, options);
            )
            | :MouseMove { .position, .delta } => (
                if self^.mouse_captured then (
                    let { window_width, window_height } = geng.get_window_size();
                    self^.camera.rotation = Angle.sub(
                        self^.camera.rotation,
                        Angle.mul(self^.camera.fov, delta.0 / window_width),
                    );
                    self^.camera.attack = Angle.sub(
                        self^.camera.attack,
                        Angle.mul(self^.camera.fov, delta.1 / window_width),
                    );
                );
            )
            | :PointerPress _ => (
                self^.mouse_captured = true;
                SDL.SetWindowRelativeMouseMode((@current geng.Context).window, true);
            )
            | :PointerRelease _ => (
                self^.mouse_captured = false;
                SDL.SetWindowRelativeMouseMode((@current geng.Context).window, false);
            )
            | _ => ()
        );
    ),
    .draw = (self :: &mut Game) => (
        let framebuffer_size = geng.get_window_size();
        with Model.Renderer.Ctx = &self^.model_renderer;
        with geng.CameraUniforms.Ctx = geng.CameraUniforms.init(self^.camera, .framebuffer_size);

        const background_color :: Vec4 = { 0.5, 0.5, 0.5, 1 };
        ugli.clear(background_color);

        Model.draw(&self^.assets.tv, Mat4.translate({ ...Vec2.add(self^.position, { 4, 0 }), 0 }));
        Model.draw(&self^.assets.model_t, Mat4.translate({ ...self^.position, 0 }));
    ),
});

geng.run[Game](
    .title = "Geng Example",
    .vsync = true,
);
