use (import "./deps.ks").*;
use (import "./model.ks").*;
use (import "./assets.ks").*;

module:

const Pickup = newtype (
	| :Tv	
    | :Stopwatch
    | :Phone
    | :Radio
);

const pickup_model = (pickup :: Pickup, models :: &ItemAssets) -> &Model.t => (
    match pickup with (
        | :Tv => &models^.tv
        | :Stopwatch => &models^.stopwatch
        | :Phone => &models^.phone
        | :Radio => &models^.radio
    )
);

const all_pickups = () -> ArrayList.t[Pickup] => (
    let mut list = ArrayList.new();
    ArrayList.push_back(&mut list, :Tv);
    ArrayList.push_back(&mut list, :Stopwatch);
    ArrayList.push_back(&mut list, :Phone);
    ArrayList.push_back(&mut list, :Radio);
    list
);
