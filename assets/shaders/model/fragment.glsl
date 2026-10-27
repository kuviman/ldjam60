varying vec2 v_uv;
varying vec3 v_normal;
varying vec3 v_camera_normal;
varying vec3 v_world_pos;
varying vec3 v_camera_pos;

uniform sampler2D u_texture;
uniform mat4 u_view_matrix;

const vec3 light_dir = vec3(2.0, 6.0, 7.0);
const vec3 light_color = vec3(0.9, 0.8, 1.0);

void main() {
    vec4 color = texture2D(u_texture, v_uv);
    if (color.a < 0.1) {
        discard;
    }

    vec3 n = normalize(v_normal);
    vec3 l = normalize((u_view_matrix * vec4(light_dir, 0.0)).xyz);
    vec3 v = normalize(-v_camera_pos);
    vec3 h = normalize(l + v);

    float ambient = 0.8;
    float diffuse = max(dot(n, l), 0.0);
    float specular = pow(max(dot(n, h), 0.0), 32.0) * 0.3;

    vec3 light = vec3(ambient) + light_color * (diffuse * (1.0 - ambient));
    vec3 lit = color.rgb * light + light_color * specular;

    float fog = 1.0 - pow(0.9, -v_camera_pos.z / 50.0);
    gl_FragColor = vec4(mix(lit, vec3(0.8, 0.8, 1.0), fog), color.a);
}
