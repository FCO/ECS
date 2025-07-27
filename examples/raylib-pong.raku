use Raylib::Bindings;
use ECS;

constant $screen-width  = 1024;
constant $screen-height = 450;
my $white               = init-white;
my $background          = init-skyblue;
init-window($screen-width, $screen-height, "Pong");

my $ball-ray = 10e0;

set-target-fps(60);

END {
    close-window;
}

my $world = world {
    component position => Vector2;
    component velocity => Vector2;

    entity "player";
    entity "ball";

    system "move-ball", -> "ball", "live", :$position!, :$velocity! {
        using-params -> Num $delta {
            $position.x += $velocity.x * $delta;
            $position.y += $velocity.y * $delta;
        }
    }

    system "goal", -> "live", :$position! where { .x < $ball-ray * 2e0 || .x > $screen-width - $ball-ray * 2e0 } {
        current-entity.del-tag: "live";
    }

    system "bounce", -> "live", :$position! where { .y < $ball-ray * 2e0 || .y > $screen-height - $ball-ray * 2e0 }, :$velocity! {
        $velocity.y *= -1;
    }

    system-group "move", <move-ball goal bounce>;

    system "draw-ball", -> "ball", :$position! {
        draw-circle-v $position, $ball-ray, init-red
    }

    system-group "draw", <draw-ball>;
}

$world.new-ball:
    "live",
    :position(Vector2.init: $screen-width/2e0, $screen-height/2e0),
    :velocity(Vector2.init: 100e0, 80e0),
;

until window-should-close {
    $world.move: get-frame-time;
    begin-drawing;
    clear-background $background;
    $world.draw;
    draw-fps 10, 10;
    end-drawing;
}
