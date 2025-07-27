unit class ECS::Entity;

my atomicint $next-id = 0;
has UInt $.id = $next-id⚛++;
has      $.world is required;
has Set  $.archetype;

method AT-KEY(
	Str $component where {
		$!world.^components{$_}:exists || die "Component $component does not exist."
	}
) {
	$!world.components{$component}[$!id]
}

method ASSIGN-KEY(
	Str $component where {
		$!world.^components{$_}:exists || die "Component $component does not exist."
	},
	\value
) {
	$!world.remove-from-archetype: self;
	$!archetype (|)= $component;
	$!world.add-to-archetype: self;
	$!world.components{$component}[$!id] = value
}

method DELETE-KEY(
	Str $component where {
		$!world.^components{$_}:exists || die "Component $component does not exist."
	}
) {
	$!world.remove-from-archetype: self;
	$!archetype = $!archetype (-) $component;
	$!world.add-to-archetype: self;
	$!world.components{$component}[$!id]:delete
}

method add-tag(+@tags) {
	$.ASSIGN-KEY: <::tags::>, ($.AT-KEY(<::tags::>) // set()) (|) @tags
}

method del-tag(+@tags) {
	$.ASSIGN-KEY: <::tags::>, ($.AT-KEY(<::tags::>) // set()) (-) @tags
}
