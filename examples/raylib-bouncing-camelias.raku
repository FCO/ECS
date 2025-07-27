use Raylib::Bindings;
use ECS;

constant $screen-width  = 1024;
constant $screen-height = 450;
my $white               = init-white;
my $background          = init-skyblue;
init-window($screen-width, $screen-height, "Bouncing Camelias");

my $string         = "./camelia.png";
my $camelia        = load-image($string);
my $camelia-height = $camelia.height;
my $camelia-width  = $camelia.width;
my $camelia-pos    = Vector2.init: $camelia-width/2e0, $camelia-height/2e0;
my $texture        = load-texture-from-image($camelia);
unload-image($camelia);

set-target-fps(60);

sub term:<vector2-zero> {Vector2.init: 0e0, 0e0}
multi infix:<+>(Vector2 $a, Vector2 $b) { Vector2.init: $a.x + $b.x, $a.y + $b.y }
multi infix:<->(Vector2 $a, Vector2 $b) { Vector2.init: $a.x - $b.x, $a.y - $b.y }
multi infix:<*>(Vector2 $a, Numeric $i) { Vector2.init: $a.x * $i, $a.y * $i }
multi infix:</>(Vector2 $a, Numeric $i) { Vector2.init: $a.x / $i, $a.y / $i }

END {
    unload-texture($texture);
    close-window;
}

my $world = world {
    component position => Vector2;
    component velocity => Vector2;

    entity "camelia";

    system "click", :when{is-mouse-button-pressed MOUSE_BUTTON_LEFT}, -> {
        world-self.new-camelia:
            :position(get-mouse-position - $camelia-pos),
            :velocity(vector2-zero),
        ;
    }

    system-group "input", <click>;

    system "move", -> :$position! is rw, :$velocity! {
        using-params -> Num $delta {
            $position += $velocity * $delta
        }
    }

    system "bounce", -> :$position! where *.y >= $screen-height - $camelia-height.Num, :$velocity! where *.y > 0 {
        $velocity.y *= -.8
    }

    system "gravity", -> :$velocity! {
        using-params -> Num $delta {
            $velocity.y += 100 * $delta;
        }
    }

    system "draw", -> :$position! {
        draw-texture-v $texture, $position, $white;
    }

    system-group "physics", <move gravity bounce>;
}

until window-should-close {
    $world.input;
    $world.physics: get-frame-time;
    begin-drawing;
    clear-background $background;
    $world.draw;
    draw-fps 10, 10;
    end-drawing;
}
