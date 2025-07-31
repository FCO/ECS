use Raylib::Bindings;
use ECS;

constant $screen-width  = 1024;
constant $screen-height = 600;
constant $radius        = 10e0;
init-window($screen-width, $screen-height, "Bouncing Ball");
END close-window;
set-target-fps(60);

my $world = world {
    component position => Vector2;
    component velocity => Vector2;

    entity "ball",
        :position{ Vector2.init: (0 .. $screen-width).pick.Num, (0 .. $screen-height).pick.Num },
        :velocity{ Vector2.init: (-300 .. 300).pick.Num, (-240 .. 240).pick.Num },
    ;

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

    system "bounce-wall", -> :$position! where { .x < $radius || .x > $screen-width - $radius }, :$velocity! {
        $velocity.x *= -.99;
    }

    system "gravity", -> :$velocity! {
        using-params -> Num $delta {
            $velocity.y += 100 * $delta
        }
    }

    system "collision", -> :position($pos1)! is rw, :velocity($vel1)! is rw {
        # Loop over the next entities...
        # for example, if the entities are 1, 2, 3; pos2 is 1, pos2 will iterate over 2 and 3
        # then pos1 goes to 2, pos2 will be only 3.
        query :after-current, -> :position($pos2)! is rw, :velocity($vel2)! is rw {
            my $dx   = $pos1.x - $pos2.x;
            my $dy   = $pos1.y - $pos2.y;
            my $dist = sqrt( $dx² + $dy² );

            if 0 < $dist <= 2 * $radius {
                my $overlap = (2 * $radius - $dist) / 2;
                my $overx = $dx / $dist;
                my $overy = $dy / $dist;

                my $norx = $dx / $dist;
                my $nory = $dy / $dist;

                $pos1.x += $overlap * $norx;
                $pos1.y += $overlap * $nory;
                $pos2.x += $overlap * $norx;
                $pos2.y += $overlap * $nory;

                my $dp =  ($vel2.x * $norx + $vel2.y * $nory) - ($vel1.x * $norx + $vel1.y * $nory);

                $vel1.x += $dp * $norx;
                $vel1.y += $dp * $nory;

                $vel2.x -= $dp * $norx;
                $vel2.y -= $dp * $nory;
            }
        }
    }

    system-group "physics", <move bounce-floor bounce-ceiling bounce-wall gravity collision>;

    system "draw", -> :$position! {
        draw-circle-v $position, $radius, init-red
    }
}

$world.new-ball xx 20;

until window-should-close {
    $world.physics: get-frame-time;
    begin-drawing;
    clear-background init-skyblue;
    $world.draw;
    draw-fps 10, 10;
    end-drawing;
}
