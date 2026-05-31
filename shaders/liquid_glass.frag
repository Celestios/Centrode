#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

#define PI         3.14159265359
#define BLUR_STEPS 12          // per ring
#define MAX_RECTS  4           // limit of four rectangles
#define MAX_BRIDGES 6          // all pairs for four rectangles

/* ── Global uniforms ─────────────────────────────────────────── */
uniform vec2   u_size;             // (w,h)  px
uniform vec4   uBounds;            // [minX,minY,maxX,maxY] px

uniform float  uBlendPx;           // smooth-union width
uniform float  uRefractStrength;
uniform float  uDistortFalloffPx;
uniform float  uDistortExponent;

uniform float  uRadialBlurPx;      // px, 0 = off

uniform float  uSpecAngle;
uniform float  uSpecStrength;
uniform float  uSpecPower;
uniform float  uSpecWidthPx;

uniform float  uLightbandOffsetPx;
uniform float  uLightbandWidthPx;
uniform float  uLightbandStrength;
uniform vec3   uLightbandColor;

uniform float  uAAPx;
uniform float  uRectCount;         // actual rects in use
uniform float  uBridgeThicknessFactor;

/* ── Per-rect data (centre.xy , size.zw), corner radii, tints ── */
uniform vec4   uRect0;  uniform float uCorner0;  uniform vec4 uTintColor0;
uniform vec4   uRect1;  uniform float uCorner1;  uniform vec4 uTintColor1;
uniform vec4   uRect2;  uniform float uCorner2;  uniform vec4 uTintColor2;
uniform vec4   uRect3;  uniform float uCorner3;  uniform vec4 uTintColor3;

uniform float  uBridgeCount;
uniform vec4   uBridge0;  uniform float uBridgeRadius0;  uniform vec4 uBridgeTint0;
uniform vec4   uBridge1;  uniform float uBridgeRadius1;  uniform vec4 uBridgeTint1;
uniform vec4   uBridge2;  uniform float uBridgeRadius2;  uniform vec4 uBridgeTint2;
uniform vec4   uBridge3;  uniform float uBridgeRadius3;  uniform vec4 uBridgeTint3;
uniform vec4   uBridge4;  uniform float uBridgeRadius4;  uniform vec4 uBridgeTint4;
uniform vec4   uBridge5;  uniform float uBridgeRadius5;  uniform vec4 uBridgeTint5;

uniform sampler2D u_texture_input;
out vec4 fragColor;

/* ── Helpers ─────────────────────────────────────────────────── */
#define R u_size
float px(float v) { return v / max(R.y, 0.001); }
vec3 bg(vec2 uv) {
  vec2 sampleUv = clamp(uv, 0.0, 1.0);
#ifdef IMPELLER_TARGET_OPENGLES
  sampleUv.y = 1.0 - sampleUv.y;
#endif
  return texture(u_texture_input, sampleUv).rgb;
}

/* getters keep main tidy */
vec4  getRect(int i){
  return (i==0)?uRect0 :(i==1)?uRect1 :(i==2)?uRect2
       :uRect3;
}
float getCorner(int i){
  return (i==0)?uCorner0 :(i==1)?uCorner1 :(i==2)?uCorner2
       :uCorner3;
}
vec4  getTint(int i){
  return (i==0)?uTintColor0 :(i==1)?uTintColor1 :(i==2)?uTintColor2
       :uTintColor3;
}
vec4 getBridge(int i){
  return (i==0)?uBridge0 :(i==1)?uBridge1 :(i==2)?uBridge2
       :(i==3)?uBridge3 :(i==4)?uBridge4
       :uBridge5;
}
float getBridgeRadius(int i){
  return (i==0)?uBridgeRadius0 :(i==1)?uBridgeRadius1
       :(i==2)?uBridgeRadius2 :(i==3)?uBridgeRadius3
       :(i==4)?uBridgeRadius4
       :uBridgeRadius5;
}
vec4 getBridgeTint(int i){
  return (i==0)?uBridgeTint0 :(i==1)?uBridgeTint1
       :(i==2)?uBridgeTint2 :(i==3)?uBridgeTint3
       :(i==4)?uBridgeTint4
       :uBridgeTint5;
}

/* rounded-rect SDF */
float sdRoundRect(vec2 p, vec2 hsz, float r){
  vec2 q = abs(p) - (hsz - vec2(r));
  return length(max(q,vec2(0.))) + min(max(q.x,q.y),0.) - r;
}
float smin(float a, float b, float k, float thicknessFactor) {
  if (k <= 0.0) return min(a, b);
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  float h1h = h * (1.0 - h);
  float c = 4.0 * (1.0 / max(thicknessFactor, 0.001) - 1.0);
  float curve = h1h / max(1.0 + c * h1h, 0.001);
  return mix(b, a, h) - k * curve;
}

float unionDistance(vec2 uvCenter, int cnt, float k0){
  float dU = 1e5;
  for(int i=0;i<MAX_RECTS;++i){
    if(i>=cnt) break;
    vec4 r = getRect(i);
    float d = sdRoundRect(uvCenter - r.xy, r.zw, getCorner(i));
    if (i == 0) {
      dU = d;
    } else {
      float minGap = 1e5;
      float maxOverlap = 0.0;
      for(int j=0; j<MAX_RECTS; ++j) {
         if (j >= i) break;
         vec4 r_j = getRect(j);
         vec2 diff = abs(r.xy - r_j.xy);
         vec2 gap2D = diff - (r.zw + r_j.zw);
         float gap = length(max(gap2D, vec2(0.0))) + min(max(gap2D.x, gap2D.y), 0.0);
         if (gap < minGap) {
             minGap = gap;
             maxOverlap = min(min(r.z, r.w), min(r_j.z, r_j.w));
         }
      }
      float k = k0 * smoothstep(-maxOverlap * 2.0, 0.0, minGap);
      dU = smin(dU, d, k, uBridgeThicknessFactor);
    }
  }
  return dU;
}

vec2 unionGradient(vec2 uvCenter, int cnt, float k0){
  float eps = px(1.0);
  vec2 dx = vec2(eps, 0.0);
  vec2 dy = vec2(0.0, eps);
  return vec2(
    unionDistance(uvCenter + dx, cnt, k0) -
      unionDistance(uvCenter - dx, cnt, k0),
    unionDistance(uvCenter + dy, cnt, k0) -
      unionDistance(uvCenter - dy, cnt, k0)
  );
}



/* radial blur directions */
vec2 getBlurDir(int j) {
  if (j == 0) return vec2(1.0, 0.0);
  if (j == 1) return vec2(0.8660254, 0.5);
  if (j == 2) return vec2(0.5, 0.8660254);
  if (j == 3) return vec2(0.0, 1.0);
  if (j == 4) return vec2(-0.5, 0.8660254);
  if (j == 5) return vec2(-0.8660254, 0.5);
  if (j == 6) return vec2(-1.0, 0.0);
  if (j == 7) return vec2(-0.8660254, -0.5);
  if (j == 8) return vec2(-0.5, -0.8660254);
  if (j == 9) return vec2(0.0, -1.0);
  if (j == 10) return vec2(0.5, -0.8660254);
  return vec2(0.8660254, -0.5);
}

/* radial blur */
vec3 radialBlur(vec2 uv, float radiusPx){
  if(radiusPx<0.5) return bg(uv);
  float aspect = R.x / max(R.y, 0.001);
  vec3 sum = bg(uv);
  float nr = radiusPx / max(R.y, 0.001);
  int cnt  = 1;
  for(int ring=1; ring<=4; ++ring){
    float rad = nr * float(ring)/4.0;
    for(int j=0; j<12; ++j){
      vec2 dir = getBlurDir(j);
      sum += bg(uv + vec2(dir.x / aspect, dir.y) * rad);
      cnt++;
    }
  }
  return sum/float(cnt);
}

/* ── Main ────────────────────────────────────────────────────── */
void main(){
  vec2 fragPx = FlutterFragCoord().xy;
  vec2 globalFragPx = fragPx;
  float safeRy = max(R.y, 0.001);
  float aspect = R.x / safeRy;

  /* passthrough */
  if(globalFragPx.x<uBounds.x||globalFragPx.x>uBounds.z||
     globalFragPx.y<uBounds.y||globalFragPx.y>uBounds.w){
    fragColor = vec4(bg(globalFragPx/max(R, vec2(0.001))), 1.0);
    return;
  }

  vec2 uv0      = globalFragPx/max(R, vec2(0.001));
  vec2 uvCenter = (globalFragPx - 0.5*R) / safeRy;

  /* union SDF + store individual distances */
  float k0 = px(uBlendPx * 3.0);
  float tintK = max(k0, px(1.0));
  int   cnt = int(uRectCount);
  float dU  = 1e5;
  float d[MAX_RECTS];

  for(int i=0;i<MAX_RECTS;++i){
    if(i>=cnt){ d[i]=1e5; continue; }
    vec4 r = getRect(i);
    d[i]  = sdRoundRect(uvCenter - r.xy, r.zw, getCorner(i));
    if (i == 0) {
      dU = d[i];
    } else {
      float minGap = 1e5;
      float maxOverlap = 0.0;
      for(int j=0; j<MAX_RECTS; ++j) {
         if (j >= i) break;
         vec4 r_j = getRect(j);
         vec2 diff = abs(r.xy - r_j.xy);
         vec2 gap2D = diff - (r.zw + r_j.zw);
         float gap = length(max(gap2D, vec2(0.0))) + min(max(gap2D.x, gap2D.y), 0.0);
         if (gap < minGap) {
             minGap = gap;
             maxOverlap = min(min(r.z, r.w), min(r_j.z, r_j.w));
         }
      }
      float k = k0 * smoothstep(-maxOverlap * 2.0, 0.0, minGap);
      dU = smin(dU, d[i], k, uBridgeThicknessFactor);
    }
  }

  float mask = smoothstep(uAAPx/safeRy, -uAAPx/safeRy, dU);

  vec2 grad = unionGradient(uvCenter,cnt,k0);
  grad = normalize(grad+1e-6);

  vec2 off = grad * pow(smoothstep(-px(uDistortFalloffPx),0.0,dU),
                        uDistortExponent) * uRefractStrength * mask;

  vec2 uvOffset = off * vec2(1.0 / aspect, 1.0);
  vec3 glassBase = radialBlur(uv0 + uvOffset*0.6, uRadialBlurPx);

  /* tint blend (soft-max) */
  vec3  accum = vec3(0.0);
  float wSum  = 0.0;
  for(int i=0;i<MAX_RECTS;++i){
    if(i>=cnt) break;
    float w = exp(-d[i]/tintK);
    vec4 tint = getTint(i);          // rgb + strength (a)
    accum += mix(glassBase, tint.rgb, tint.a) * w;
    wSum  += w;
  }
  vec3 glass = accum / max(wSum, 1e-6);

  /* specular rim */
  vec3 N3 = normalize(vec3(grad,0.6));
  vec3 L1 = normalize(vec3(cos(uSpecAngle), sin(uSpecAngle), 0.5));
  vec3 L2 = normalize(vec3(-cos(uSpecAngle),-sin(uSpecAngle),0.5));
  float rim = smoothstep(px(-uSpecWidthPx),0.0,dU);
  glass += (pow(max(dot(N3,L1),0.0),uSpecPower) +
            pow(max(dot(N3,L2),0.0),uSpecPower)) * uSpecStrength * rim;

  /* light band */
  float lb = smoothstep(0.0,px(uLightbandWidthPx),dU+px(uLightbandOffsetPx));
  glass += uLightbandColor * lb * uLightbandStrength;

  fragColor = vec4(mix(bg(uv0),glass,mask),1.0);
}
