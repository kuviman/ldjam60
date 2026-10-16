use (import "./deps.ks").*;

# why did i agree to this

module:

const Ray = newtype {
	.origin :: Vec3,
	.position :: Vec3,
};

impl Ray as module = (
	const extend = (ray :: &mut Ray, len :: Float32) => with_return (	
		let pos :: Vec3 = ray^.position;
		let len :: Float32 = Vec3.length(pos);
		
		if len == 0 then (
			return;
		);

		let dir :: Vec3 = Vec3.normalize(pos);
		ray^.position = Vec3.add(pos, Vec3.mul(dir, len));
	);
);
