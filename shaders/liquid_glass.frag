#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

#define PI        3.14159265359
#define MAX_RECTS 4

/* ── Global uniforms ─────────────────────────────────────────── */
// Physical dimensions of either the local widget bounds (Path A) or the FULL background snapshot (Path B).
uniform float u_path_mode;
uniform vec2  u_layer_size;
uniform vec2  u_inflated_offset;
uniform vec2  u_global_offset;
uniform vec2  u_bg_size;

uniform float uBlendPx;           // physical px
uniform float uRefractStrength;
uniform float uDistortFalloffPx;  // physical px
uniform float uDistortExponent;
uniform float uRadialBlurPx;      // physical px

uniform float uSpecAngle;
uniform float uSpecStrength;
uniform float uSpecPower;
uniform float uSpecWidthPx;       // physical px

uniform float uLightbandOffsetPx; // physical px
uniform float uLightbandWidthPx;  // physical px
uniform float uLightbandStrength;
uniform vec3  uLightbandColor;

uniform float uAAPx;              // physical AA width
uniform float uRectCount;
uniform float uBridgeThicknessFactor;

/* ── Per-rect: centre (xy), half-size (zw) in physical px ───── */
uniform vec4  uRect0; uniform float uCorner0; uniform vec4 uTintColor0;
uniform vec4  uRect1; uniform float uCorner1; uniform vec4 uTintColor1;
uniform vec4  uRect2; uniform float uCorner2; uniform vec4 uTintColor2;
uniform vec4  uRect3; uniform float uCorner3; uniform vec4 uTintColor3;

uniform sampler2D u_texture_input;
out vec4 fragColor;

/* ── Helpers ─────────────────────────────────────────────────── */
vec3 bg(vec2 uv) {
  vec2 s = clamp(uv, 0.0, 1.0);
#ifdef IMPELLER_TARGET_OPENGLES
  s.y = 1.0 - s.y;
#endif
  return texture(u_texture_input, s).rgb;
}

vec4  getRect(int i)   { return (i==0)?uRect0:(i==1)?uRect1:(i==2)?uRect2:uRect3; }
float getCorner(int i) { return (i==0)?uCorner0:(i==1)?uCorner1:(i==2)?uCorner2:uCorner3; }
vec4  getTint(int i)   { return (i==0)?uTintColor0:(i==1)?uTintColor1:(i==2)?uTintColor2:uTintColor3; }

/* Rounded-rect SDF in physical pixels */
float sdRoundRect(vec2 p, vec2 hsz, float r) {
  vec2 q = abs(p) - (hsz - vec2(r));
  return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

float smin(float a, float b, float k, float tf) {
  if (k <= 0.0) return min(a, b);
  float h   = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
  float h1h = h*(1.0-h);
  float c   = 4.0*(1.0/max(tf,0.001)-1.0);
  return mix(b,a,h) - k*(h1h/max(1.0+c*h1h,0.001));
}

float calcDynamicBlendK(int idx, vec4 r, float k0) {
  float minGap = 1e5; float maxOverlap = 0.0;
  for (int j=0; j<MAX_RECTS; ++j) {
    if (j>=idx) break;
    vec4 rj = getRect(j);
    vec2 gap2D = abs(r.xy-rj.xy) - (r.zw+rj.zw);
    float gap = length(max(gap2D,vec2(0.0))) + min(max(gap2D.x,gap2D.y),0.0);
    if (gap<minGap) { minGap=gap; maxOverlap=min(min(r.z,r.w),min(rj.z,rj.w)); }
  }
  return k0 * smoothstep(-maxOverlap*2.0, k0, minGap);
}

float unionDist(vec2 p, int cnt, float k0) {
  float dU = 1e5;
  for (int i=0; i<MAX_RECTS; ++i) {
    if (i>=cnt) break;
    vec4 r = getRect(i);
    float d = sdRoundRect(p-r.xy, r.zw, getCorner(i));
    dU = (i==0) ? d : smin(dU,d,calcDynamicBlendK(i,r,k0),uBridgeThicknessFactor);
  }
  return dU;
}

/* Gradient with 1 physical-px epsilon */
vec2 unionGrad(vec2 p, int cnt, float k0) {
  const float e = 1.0;
  return vec2(unionDist(p+vec2(e,0),cnt,k0)-unionDist(p-vec2(e,0),cnt,k0),
              unionDist(p+vec2(0,e),cnt,k0)-unionDist(p-vec2(0,e),cnt,k0));
}

vec2 blurDir(int j) {
  if(j==0)  return vec2( 1.000, 0.000); if(j==1)  return vec2( 0.866, 0.500);
  if(j==2)  return vec2( 0.500, 0.866); if(j==3)  return vec2( 0.000, 1.000);
  if(j==4)  return vec2(-0.500, 0.866); if(j==5)  return vec2(-0.866, 0.500);
  if(j==6)  return vec2(-1.000, 0.000); if(j==7)  return vec2(-0.866,-0.500);
  if(j==8)  return vec2(-0.500,-0.866); if(j==9)  return vec2( 0.000,-1.000);
  if(j==10) return vec2( 0.500,-0.866); return     vec2( 0.866,-0.500);
}

vec3 radialBlur(vec2 uv, float rPx, vec2 texSize) {
  if (rPx < 0.5) return bg(uv);
  vec3 sum = bg(uv);
  
  vec2 uvR = rPx / max(texSize, vec2(1.0));
  
  // Cut rings from 4 to 2, and directions from 12 to 6 (12 total fetches instead of 48)
  for (int ring=1; ring<=2; ++ring) {
    float rad = float(ring) / 2.0;
    
    // Unrolling for maximum branchless performance
    sum += bg(uv + vec2( 1.000,  0.000) * rad * uvR);
    sum += bg(uv + vec2( 0.500,  0.866) * rad * uvR);
    sum += bg(uv + vec2(-0.500,  0.866) * rad * uvR);
    sum += bg(uv + vec2(-1.000,  0.000) * rad * uvR);
    sum += bg(uv + vec2(-0.500, -0.866) * rad * uvR);
    sum += bg(uv + vec2( 0.500, -0.866) * rad * uvR);
  }
  
  return sum / 13.0; // 1 (center) + 12 (samples)
}

/* ── Main ────────────────────────────────────────────────────── */
void main() {
  vec2 fragPos = FlutterFragCoord().xy;
  vec2 localPx = fragPos + u_inflated_offset;

  vec2 uv0;
  vec2 currentSize;
  if (u_path_mode < 0.5) {
    currentSize = u_layer_size;
    uv0 = fragPos / max(currentSize, vec2(0.001));
  } else {
    currentSize = u_bg_size;
    vec2 globalPx = localPx + u_global_offset;
    uv0 = globalPx / max(currentSize, vec2(0.001));
  }

  int   cnt   = int(uRectCount);
  float k0    = uBlendPx * 4.0;
  float tintK = max(uBlendPx, 1.0);

  float dU = 1e5;
  float d[MAX_RECTS];
  for (int i=0; i<MAX_RECTS; ++i) {
    if (i>=cnt) { d[i]=1e5; continue; }
    vec4 r = getRect(i);
    d[i] = sdRoundRect(localPx - r.xy, r.zw, getCorner(i));
    dU = (i==0) ? d[i] : smin(dU, d[i], calcDynamicBlendK(i,r,k0), uBridgeThicknessFactor);
  }

  // GLSL §8.3: edge0 < edge1 required.
  float mask = 1.0 - smoothstep(-uAAPx, uAAPx, dU);

  vec2  grad      = normalize(unionGrad(localPx, cnt, k0) + 1e-6);
  float depth     = clamp(-dU / max(uDistortFalloffPx, 1.0), 0.0, 1.0);
  float lensCurve = pow(1.0 - depth, uDistortExponent);
  vec2  off       = grad * lensCurve * uRefractStrength;

  vec2 uvOffset  = off * vec2(currentSize.y / max(currentSize.x, 0.001), 1.0);
  vec3 glassBase = radialBlur(uv0 + uvOffset, uRadialBlurPx, currentSize);

  vec3 accum = vec3(0.0);
  float wSum = 0.0;
  for (int i=0; i<MAX_RECTS; ++i) {
    if (i>=cnt) break;

    float dist = d[i];
    float safeDist = max(dist, -100.0);
    float w = exp(-safeDist / tintK) * smoothstep(tintK * 1.5, tintK, dist);

    vec4 t = getTint(i);
    accum += mix(glassBase, t.rgb, t.a) * w;
    wSum  += w;
  }
  vec3 glass = accum / max(wSum, 1e-6);

  /* Specular highlights */
  vec3  N3  = normalize(vec3(grad, 0.6));
  vec3  L1  = normalize(vec3( cos(uSpecAngle), sin(uSpecAngle), 0.5));
  vec3  L2  = normalize(vec3(-cos(uSpecAngle),-sin(uSpecAngle), 0.5));
  float rim = smoothstep(-uSpecWidthPx, 0.0, dU);
  glass += (pow(max(dot(N3,L1),0.0),uSpecPower) +
            pow(max(dot(N3,L2),0.0),uSpecPower)) * uSpecStrength * rim;

  // Directional rim light: decouple edge-proximity from angular intensity.
  // 'grad' is already the normalized SDF surface normal (computed above for refraction).
  // Projecting it against the light direction ensures the highlight traces the
  // perimeter continuously — the old 1D Cartesian smoothstep sliced a 2D distance
  // field, which produces triangle artifacts at rounded corners.
  vec2  rimLightDir  = vec2(cos(uSpecAngle), sin(uSpecAngle));
  float rimIntensity = max(0.0, dot(grad, rimLightDir));
  // Band centred on the uLightbandOffsetPx isoline of the SDF.
  // 1.0 at the exact isoline, falling to 0 over uLightbandWidthPx.
  float edgeMask     = 1.0 - smoothstep(0.0, uLightbandWidthPx, abs(dU - uLightbandOffsetPx));
  glass += uLightbandColor * (rimIntensity * edgeMask * uLightbandStrength);

  fragColor = vec4(glass * mask, mask);
}
