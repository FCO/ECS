use Metamodel::ECS::WorldHOW;
use ECS::Entity;

sub world(&block) is export {
	my $world = Metamodel::ECS::WorldHOW.new_type: :name<World>;
	my $*ECS-WORLD := $world;
	block;
	$world.^add_parent: Any;
	$world.^compose;
	$world.new
}

sub to-kebab(Str() $_) {
	lc S:g/(\w)<?before <[A..Z]>>/$0-/
}

multi component(Str $name, ::Type Any) is export {
	$*ECS-WORLD.^add-component: $name, Type
}

multi component(::Type Any) is export {
	component Type.^shortname.&to-kebab, Type
}

multi component(*%pars where *.elems == 1) is export {
	component %pars.keys.head, %pars.values.head
}

sub entity(Str $entity) is export {
	$*ECS-WORLD.^add-entity: $entity
}

sub query(&block, |c) is export {
	my $world    = $*ECS-WORLD;
	my @params   = &block.signature.params;
	my @names    = @params.grep({ .named && not .optional }).map: *.named_names.head;
	my @tags     = @params.grep({ .positional && .constraint_list }).map: *.constraint_list.head;
	my $count    = &block.count;
	my @comps    = |@names, |("::tags::" if $count);
	my $arch     = set(@comps);
	my @ids      = $world.entity-ids-for-archetype($arch).keys;
	for @ids -> UInt $index {
		my %comps := @comps.map({ next if $_ eq '::tags::'; .Str => $world.components{.Str}[$index] }).Map;
		my %tags  := $world.components<::tags::>[$index];
		next unless @tags (<=) %tags;
		next unless \(|@tags, |%comps) ~~ &block.signature;
		my Capture $*ECS-SUBSIG    = c;
		my UInt    $*ECS-ENTITY-ID = $index;
		block |@tags, |%comps
	}
}

multi system(&block where *.?name, |c) is export {
	system &block.name, &block
}

multi system(Str $name, &block, :when(:&condition)) is export {
	if &condition {
		return $*ECS-WORLD.^add-system: $name, sub (|c) { block |c if condition }
	}
	$*ECS-WORLD.^add-system: $name, sub (|c) { query &block, |c }
}

multi system-group(Str $name, +@systems where { $*ECS-WORLD.^systems{@systems.all} }) is export {
	$*ECS-WORLD.^add-system-group: $name, @systems
}

sub using-params(&block) is export {
	block |$*ECS-SUBSIG
}

sub term:<current-entity> is export {
	ECS::Entity.new: id => $*ECS-ENTITY-ID, world => $*ECS-WORLD
}

sub term:<world-self> is export {
	$*ECS-WORLD
}

=begin pod

=head1 NAME

ECS — a declarative Entity‑Component‑System micro‑framework in Raku

=head1 SYNOPSIS

=begin code :lang<raku>

use ECS;

constant $screen-width  = 1024;
constant $screen-height = 450;
constant $radius        = 10e0;

init-window($screen-width, $screen-height, "Bouncing Ball");
END close-window;
set-target-fps(60);

my $world = world {
    component position => Vector2;
    component velocity => Vector2;
    entity "ball";

    system "move", -> :$position!, :$velocity! {
        using-params -> Num $delta {
            $position.x += $velocity.x * $delta;
            $position.y += $velocity.y * $delta;
        }
    }

    system "bounce-floor", -> :$position! where { .y >= $screen-height - $radius }, :$velocity! where *.y > 1 {
        $position.y = $screen-height - $radius;
        $velocity.y *= -.99;
        $velocity.x *= .9;
    }

    system "bounce-ceiling", -> :$position! where { .y <= $radius }, :$velocity! where *.y < -1 {
        $position.y = $radius;
        $velocity.y *= -.99;
        $velocity.x *= .9;
    }

    system "bounce-h", -> :$position! where { .x < $radius || .x > $screen-width - $radius }, :$velocity! {
        $velocity.x *= -.99;
    }

    system "gravity", -> :$velocity! {
        using-params -> Num $delta {
            $velocity.y += 100 * $delta;
        }
    }

    system-group "physics", <move bounce-floor bounce-ceiling bounce-h gravity>;

    system "draw", -> :$position! {
        draw-circle-v $position, $radius, init-red;
    }
};

$world.new-ball:
    :position(Vector2.init: $screen-width/2e0, $screen-height/2e0),
    :velocity(Vector2.init: 300e0, 240e0),
;

until window-should-close {
    $world.physics: get-frame-time;
    begin-drawing;
    clear-background init-skyblue;
    $world.draw;
    draw-fps 10, 10;
    end-drawing;
}

=end code

=head1 DESCRIPTION

ECS is a minimalist, declarative ECS engine for Raku that uses a `world { … }` DSL to define components, systems, and system groups. It uses strong introspection to allow systems to match entities by **tags**, **components**, and **where** filters in their signatures, without boilerplate.

ECS is inspired by the standard architectural pattern where **entities** are identifiers carrying sets of components (pure data) and **systems** operate globally on entities with required component combinations.

This framework enables:

=item Definition of components with `component ComponentType` or `component component-name => ComponentType`; component-name is inferred via kebab-case conversion if not explicit.

=item Creation of entities with tags and per-entity components via:  
  `entity "ball"; ... $world.new-ball("alive", :position(...), :velocity(...));`

=item Declaration of systems with signatures indicating matching tags, components, and optional `where` filters.

=item Injection of call-time parameters (like delta time, input events) inside the system body using `using-params -> ... { ... }`.

=item Grouping of systems into phases (e.g. “physics”, “render”) via `system-group`, which can be invoked with parameters.

=item Access to the current iterated entity inside systems/queries via `current-entity`, allowing dynamic entity creation.

=item Access to the world context inside systems via `world-self`, allowing dynamic entity creation.

=head2 Example Explained

In the C<Bouncing Ball> example:

=item A C<ball> entity is defined with C<position> and C<velocity> components (C<Vector2>).

=item The B<move> system updates the ball’s position based on its velocity and delta time.

=item The B<gravity> system applies a downward acceleration to velocity.

=item B<bounce-floor>, B<bounce-ceiling>, and B<bounce-h> systems enforce collision boundaries and damp velocity and bounce.

=item The systems are grouped into a C<physics> phase using C<system-group>, so that C<$world.physics: get-frame-time;> runs move → gravity → bounce.

=item The B<draw> system is independent and renders all balls each frame.

This example demonstrates:

- Separation of concerns: physics logic is decoupled from rendering.
- Declarative entity matching: systems only affect entities satisfying signature and C<where> clauses.
- Dynamic creation: new balls could be spawned from input systems via C<world-self>.

=head1 FEATURES

=item Signature-based system dispatch using tags and component introspection

=item Value filters with C<where> clauses

=item Conditional systems with C<:condition{...}> for global input/event systems

=item Call-time parameter injection with C<using-params>

=item Phased execution via C<system-group>

=item Direct access to current entity via C<current-entity>, and world context via C<world-self>

=head1 AUTHOR

Fernando Corrêa de Oliveira <fco@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
