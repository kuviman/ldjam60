use (import "./deps.ks").*;
use (import "./model.ks").*;

module:

const Assets = newtype {
    .tv :: Model.t,
    .model_t :: {
        .body :: Model.t,
        .wheel :: Model.t,
    },
    .building :: Model.t,
    .garage :: Model.t,
    .trees :: Model.t,
    .road :: {
        .connected :: Model.t,
        .disconnected :: Model.t,
    },
    .honk :: geng.audio.Buffer,
    .earth_angel :: geng.audio.Buffer,
};

impl Assets as module = (
    module:

    const Ctx = @context type (&Assets);

    const load = () -> Assets => (
        {
            .tv = Model.load("assets/tv"),
            .model_t = {
                .body = Model.load("assets/model_t"),
                .wheel = Model.load("assets/model_t/wheel"),
            },
            .building = Model.load("assets/building"),
            .garage = Model.load("assets/garage"),
            .trees = Model.load("assets/trees"),
            .road = {
                .connected = Model.load("assets/road/connected"),
                .disconnected = Model.load("assets/road/disconnected"),
            },
            .honk = geng.audio.Buffer.load("assets/honk.mp3"),
            .earth_angel = geng.audio.Buffer.load("assets/earth-angel.wav"),
        }
    );
);
