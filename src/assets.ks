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
    .finish :: Model.t,
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
    .audio :: fmod.system.System,
};

impl Assets as module = (
    module:

    const Ctx = @context type (&Assets);

    const load = () -> Assets => (
        let audio = fmod.init({
            .max_channels = 512,
            .handedness = :Right,
            .up = { 0, 1, 0 },
            .forward = { 0, 0, -1 },
        });

        fmod.bank.load(audio, "assets/banks/Master.bank");
        fmod.bank.load(audio, "assets/banks/Master.strings.bank");

        {
            .hand = Model.load("assets/hand"),
            .finish = Model.load("assets/finish"),
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
            .audio,
        }
    );
);
