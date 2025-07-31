use ECS::World;
use ECS::Entity;
unit class Metamodel::ECS::WorldHOW is Metamodel::ClassHOW;

has Mu:U     %!components;
has SetHash  $!entities;
has Callable %!systems;
has Set      %!archetype-tree{Set};

method new_type(|) {
	my $type = callsame;
	$type.^add_role: ECS::World;
	$type
}

method compose(Mu $type) {
	$type.^add-component: "::tags::", Set;
	my @archs = %!components.keys.combinations.map: *.Set;
	%!archetype-tree = @archs.map: -> %key {
		%key => @archs.grep({ %key (<=) .Set }).Set
	}
	nextsame
}

method archetype-tree(Mu) { %!archetype-tree }

method components(Mu) { %!components.Map }

method add-component(Mu, Str $name, ::Type Any:U) {
	die "Component '{ $name }' already defined." if %!components{$name}:exists;
	%!components{$name} = Type;
}

method entities(Mu) { $!entities.Set }

method add-entity(Mu $type, Str $name, @default-tags?, %default-components?) {
	die "Entity '{ $name }' already defined." if $!entities{$name}:exists;
	$!entities{$name} = True;

	$type.^add_method: "new-{ $name }", my method (+@tags, *%pars) {
		my (:@to-add, :@to-remove) := @tags.classify: { .starts-with("!") ?? "to-remove" !! "to-add" };
		my @final-tags = ((@default-tags (|) @to-add) (-) @to-remove.map: *.substr: 1).keys;
		my %components = %default-components.pairs.duckmap: -> (:$key, :value(&block)) { $key => block }

		$.new-entity: $name, |@final-tags, |%components, |%pars
	}
}

method systems(Mu) { %!systems.keys.Set }

method add-system(Mu $type, Str $name, &block) {
	%!systems{$name} = &block;
	my &system = method (|c) {
		my ECS::World $*ECS-WORLD = self;
		block |c
	}
	$type.^add_method: $name, &system
}

method add-system-group(Mu $type, Str $name, +@systems where { $.systems($type){ @systems.all } }) {
	$type.^add_method: $name, my method (|c) {
		for @systems -> Str $system {
			self."$system"(|c)
		}
	}
}
