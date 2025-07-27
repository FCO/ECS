NAME
====

ECS — a declarative Entity‑Component‑System micro‑framework in Raku

SYNOPSIS
========

```raku
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
```

DESCRIPTION
===========

ECS is a minimalist, declarative ECS engine for Raku that uses a `world { … }` DSL to define components, systems, and system groups. It uses strong introspection to allow systems to match entities by **tags**, **components**, and **where** filters in their signatures, without boilerplate.

ECS is inspired by the standard architectural pattern where **entities** are identifiers carrying sets of components (pure data) and **systems** operate globally on entities with required component combinations.

This framework enables:

  * Definition of components with `component ComponentType` or `component component-name => ComponentType`; component-name is inferred via kebab-case conversion if not explicit.

  * Creation of entities with tags and per-entity components via: `entity "ball"; ... $world.new-ball("alive", :position(...), :velocity(...));`

  * Declaration of systems with signatures indicating matching tags, components, and optional `where` filters.

  * Injection of call-time parameters (like delta time, input events) inside the system body using `using-params -> ... { ... }`.

  * Grouping of systems into phases (e.g. “physics”, “render”) via `system-group`, which can be invoked with parameters.

  * Access to the current iterated entity inside systems/queries via `current-entity`, allowing dynamic entity creation.

  * Access to the world context inside systems via `world-self`, allowing dynamic entity creation.

Example Explained
-----------------

In the `Bouncing Ball` example:

  * A `ball` entity is defined with `position` and `velocity` components (`Vector2`).

  * The **move** system updates the ball’s position based on its velocity and delta time.

  * The **gravity** system applies a downward acceleration to velocity.

  * **bounce-floor**, **bounce-ceiling**, and **bounce-h** systems enforce collision boundaries and damp velocity and bounce.

  * The systems are grouped into a `physics` phase using `system-group`, so that `$world.physics: get-frame-time;` runs move → gravity → bounce.

  * The **draw** system is independent and renders all balls each frame.

This example demonstrates:

- Separation of concerns: physics logic is decoupled from rendering. - Declarative entity matching: systems only affect entities satisfying signature and `where` clauses. - Dynamic creation: new balls could be spawned from input systems via `world-self`.

FEATURES
========

  * Signature-based system dispatch using tags and component introspection

  * Value filters with `where` clauses

  * Conditional systems with `:condition{...}` for global input/event systems

  * Call-time parameter injection with `using-params`

  * Phased execution via `system-group`

  * Direct access to current entity via `current-entity`, and world context via `world-self`

AUTHOR
======

Fernando Corrêa de Oliveira <fco@cpan.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

