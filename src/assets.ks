use (import "./deps.ks").*;
use (import "./model.ks").*;

module:

const ItemAssets = newtype {
    .tv :: Model.t,
    .stopwatch :: Model.t,
    .phone :: Model.t,
    .radio :: Model.t,
};

const load_item_assets = (path :: &str) -> ItemAssets => {
    .tv = Model.load(&format!("\(path)/tv") |> as_str),
    .stopwatch = Model.load(&format!("\(path)/stopwatch") |> as_str),
    .phone = Model.load(&format!("\(path)/phone") |> as_str),
    .radio = Model.load(&format!("\(path)/radio") |> as_str),
};

const Assets = newtype {
    .hand :: Model.t,
    .pickups :: ItemAssets,
    .upgrades :: ItemAssets,
    .board :: ItemAssets,
    .items :: ItemAssets,
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
    .bonk :: geng.audio.Buffer,
    .earth_angel :: geng.audio.Buffer,
    .drifting :: geng.audio.Buffer,
    .vroom :: geng.audio.Buffer,
};

impl Assets as module = (
    module:

    const Ctx = @context type (&Assets);

    const load = () -> Assets => (
        {
            .hand = Model.load("assets/hand"),
            .pickups = load_item_assets("assets/pickups"),
            .items = load_item_assets("assets/items"),
            .upgrades = load_item_assets("assets/upgrades"),
            .board = load_item_assets("assets/board"),
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
            .bonk = geng.audio.Buffer.load("assets/bonk.mp3"),
            .earth_angel = geng.audio.Buffer.load("assets/earth-angel.wav"),
            .drifting = geng.audio.Buffer.load("assets/drifting.wav"),
            .vroom = geng.audio.Buffer.load("assets/vroom.wav"),
        }
    );
);
