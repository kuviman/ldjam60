use (import "./deps.ks").*;

module:

# ANNOYING BUG PLS FIX (siiix seeeveeen)
const PHYSICS_TPS :: Float32 =  0.0166666666667; #1.0/60.0;
const PHYSICS_LERP :: Float32 = 0.2;

const b_to_f32 = (b :: Bool) -> Float32 => (
	if b then 1 else 0
);

const lerp = (val :: Float32, target :: Float32, scalar :: Float32) -> Float32 => (
	val + (target - val) * scalar	
);

const angular_dist = (a :: Angle, b :: Angle) -> Angle => (
    let mut d :: Float32 = fmod((b.radians - a.radians), (2 * PI));

    if d > PI then (
        d = d - 2 * PI
	) else if d < -PI then (
        d = d + 2 * PI
	);
		
    { .radians = d }
);

const abs = (x :: Float32) -> Float32 => (
    @native "#include <math.h>";
    @native "fabs(\(x))"
);

const fmod = (a :: Float32, b :: Float32) -> Float32 => (
    @native "#include <math.h>";
    @native "fmod(\(a),\(b))"
);
