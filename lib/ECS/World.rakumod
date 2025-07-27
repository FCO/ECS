use ECS::Entity;
unit role ECS::World;

has %.components = self.^components.kv.map: -> $comp, ::Type $ { $comp => Array[Type].new }
has Set %.archetypes{Set};

method new-entity(+@tags, *%pars) {
	my $entity = ECS::Entity.new: :world(self);
	for %(|%pars, '::tags::' => @tags.Set).kv -> Str $component, $value {
		$entity{ $component } = $value
	}
}

method add-to-archetype(ECS::Entity $entity) {
	%!archetypes{ $entity.archetype } //= set();
	%!archetypes{ $entity.archetype } (|)= $entity.id
}

method remove-from-archetype(ECS::Entity $entity) {
	return unless $entity.archetype;
	%!archetypes{ $entity.archetype } //= set();
	%!archetypes{ $entity.archetype } (-)= $entity.id
}

method entity-ids-for-archetype(Set() $archetype = set()) {
	my @arch = $.^archetype-tree{$archetype}.keys;
	[(|)] $.archetypes{ @arch }.grep: *.defined;
}
