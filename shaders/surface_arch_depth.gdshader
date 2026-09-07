shader_type canvas_item;
uniform bool front_layer = false;
void fragment() {
    // Two complementary draw layers reference one complete production texture.
    bool near_pillar = UV.x > 0.59 && UV.y > 0.38;
    if (near_pillar != front_layer) { discard; }
}
