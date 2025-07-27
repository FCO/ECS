use Raylib::Bindings;
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
            $velocity.y += 100 * $delta
        }
    }

    system-group "physics", <move bounce-floor bounce-ceiling bounce-h gravity>;

    system "draw", -> :$position! {
        draw-circle-v $position, $radius, init-red
    }
}

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
