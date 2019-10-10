shader_type canvas_item;

uniform bool apply = true;
uniform float amount : hint_range(0, 10);
uniform sampler2D offset_texture : hint_white;

void fragment(){
	if (apply == true){
		float adjusted_amount = amount / 100.0;
		COLOR.r = texture(SCREEN_TEXTURE, SCREEN_UV + amount/100.0).r;
		COLOR.g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
		COLOR.b = texture(SCREEN_TEXTURE, SCREEN_UV - amount/100.0).b;
		COLOR.a = texture(SCREEN_TEXTURE, SCREEN_UV).a;
	}
}