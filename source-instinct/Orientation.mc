// Orientation reflects the device's orientation. Horizontal, or "flat",
// refers to being held horizontally (such as lying flat on a table). Bottom,
// Top, Left, and Right all refer to being held vertically. Bottom refers to
// being held right side up. Top refers to being held upside down. Left and
// Right refer to being held sideways, either to the left or to the right.
module Orientation {
    enum {
        HORIZONTAL,
        BOTTOM,
        TOP,
        LEFT,
        RIGHT,
    }
    
    const strings = ["flat", "bottom", "top", "left", "right"];
}