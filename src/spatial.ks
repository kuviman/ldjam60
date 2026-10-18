use (import "./deps.ks").*;

# why did i agree to this

module:

const Ray = newtype {
	.origin :: Vec3,
	.position :: Vec3,
};

impl Ray as module = (
	module:

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

const Cuboid = newtype {
	.half_size :: Vec3,
};

impl Cuboid as module = (
	module:

	const new = (size :: Vec3) -> Cuboid => { .half_size = size };

	const overlaps = (
		pos_a :: Vec3,
		cuboid_a :: Cuboid,
		pos_b :: Vec3,
		cuboid_b :: Cuboid,
	) -> Bool => (
		    abs(pos_a.0 - pos_b.0) <= cuboid_a.half_size.0 + cuboid_b.half_size.0
		and abs(pos_a.1 - pos_b.1) <= cuboid_a.half_size.1 + cuboid_b.half_size.1
		and abs(pos_a.2 - pos_b.2) <= cuboid_a.half_size.2 + cuboid_b.half_size.2	
	);

	const contains = (
		pos :: Vec3,
		cuboid :: Cuboid,
		point :: Vec3,
	) -> Bool => (
		    abs(point.0 - pos.0) <= cuboid.half_size.0
		and abs(point.1 - pos.1) <= cuboid.half_size.1
		and abs(point.2 - pos.2) <= cuboid.half_size.2
	);
);

const Rect = newtype {
	.half_size :: Vec2,
};

impl Rect as module = (
	module:

	const new = (size :: Vec2) -> Rect => { .half_size = size };

	const overlaps = (
		pos_a :: Vec2,
		rect_a :: Rect,
		pos_b :: Vec2,
		rect_b :: Rect,
	) -> Bool => (
		    abs(pos_a.0 - pos_b.0) <= rect_a.half_size.0 + rect_b.half_size.0
		and abs(pos_a.1 - pos_b.1) <= rect_a.half_size.1 + rect_b.half_size.1
	);

	const contains = (
		pos :: Vec2,
		rect :: Rect,
		point :: Vec2,
	) -> Bool => (
		    abs(point.0 - pos.0) <= rect.half_size.0
		and abs(point.1 - pos.1) <= rect.half_size.1
	);
);
