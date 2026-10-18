use (import "./deps.ks").*;
use (import "./assets.ks").*;
use (import "./world.ks").*;
use (import "./model.ks").*;
use (import "./util.ks").*;

const Game = newtype {
    .model_renderer :: Model.Renderer,
    .assets :: Assets,
    .mouse_captured :: Bool,
    .world :: World,
    .tick_timer :: Float32,
};

@eval (impl Game as geng.App = {
    .init = () -> Game => {
        .model_renderer = Model.Renderer.init(),
        .assets = Assets.load(),
        .mouse_captured = false,
        .world = World.new(),
        .tick_timer = 0,
    },
    .update = (self :: &mut Game, delta_time :: Float32) => (
        self^.tick_timer += delta_time;

        while self^.tick_timer > PHYSICS_TPS do (
            World.update(&mut self^.world);
            self^.tick_timer -= PHYSICS_TPS;
        );
    ),
    .handle_event = (self :: &mut Game, event :: geng.Event) => (
        match event with (
            | :KeyPress :Space => (
                let options :: geng.audio.PlayOptions = {
                    .@"loop" = false,
                    .volume = 1,
                };
                geng.audio.play_with(&self^.assets.honk, options);
            )
            | :MouseMove { .position, .delta } => (
                let camera = &mut self^.world.camera;
                if self^.mouse_captured then (
                    let { window_width, window_height } = geng.get_window_size();
                    camera^.rotation = Angle.sub(
                        camera^.rotation,
                        Angle.mul(camera^.fov, delta.0 / window_width),
                    );
                    camera^.attack = Angle.sub(
                        camera^.attack,
                        Angle.mul(camera^.fov, delta.1 / window_width),
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
        const background_color :: Vec4 = { 0.8, 0.8, 1.0, 1 };
        ugli.clear(background_color);

        with Assets.Ctx = &self^.assets;
        with Model.Renderer.Ctx = &self^.model_renderer;

        let alpha = self^.tick_timer / PHYSICS_TPS;
        World.draw(&mut self^.world, .update_camera = not self^.mouse_captured, alpha);
    ),
});

geng.run[Game](
    .title = "Geng Example",
    .vsync = true,
);
