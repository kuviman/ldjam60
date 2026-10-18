use (import "./deps.ks").*;
use (import "./model.ks").*;

module:

const Assets = newtype {
    .tv :: Model.t,
    .model_t :: Model.t,
    .building :: Model.t,
    .test_sfx :: geng.audio.Buffer,
};

impl Assets as module = (
    module:

    const Ctx = @context type (&Assets);

    const load = () -> Assets => (
        {
            .tv = Model.load("assets/tv"),
            .model_t = Model.load("assets/model_t"),
            .building = Model.load("assets/building"),
            .test_sfx = geng.audio.Buffer.load("assets/test.wav"),
        }
    );
);
