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

        if self^.tick_timer > PHYSICS_TPS then (
            World.update(&mut self^.world);
            self^.tick_timer = 0;
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
            | :MouseMove { .position, .delta } => ()
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
        const background_color :: Vec4 = { 0.5, 0.5, 0.5, 1 };
        ugli.clear(background_color);

        with Assets.Ctx = &self^.assets;
        with Model.Renderer.Ctx = &self^.model_renderer;

        World.draw(&mut self^.world);
    ),
});

geng.run[Game](
    .title = "Geng Example",
    .vsync = true,
);
