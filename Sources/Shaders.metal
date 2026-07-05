#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertexMain(uint vertexID [[vertex_id]]) {
    float2 positions[3] = {
        float2(-1, -1),
        float2(3, -1),
        float2(-1, 3)
    };
    VertexOut out;
    out.position = float4(positions[vertexID], 0, 1);
    out.uv = (positions[vertexID] + 1.0) * 0.5;
    return out;
}

struct Uniforms {
    float time;
    float bass;
    float mid;
    float treble;
    float colorCount;
    float kaleidoscopeEnabled;
    float echoTrailsEnabled;
    float chromaticAberrationEnabled;
    float hueCyclingEnabled;
    float atmosphereMode;
    float puddleTime;
    float oceanTime;
    float spaceTime;
    float beatPulse;
    float vocalActivity;
    float puddleBassTime;
    float kickPulse;
    float puddleTrebleSmooth;
    float puddleMidSmooth;
    float spaceKickSmooth;
    float4 ripplePulses0;
    float4 ripplePulses1;
    float4 color0;
    float4 color1;
    float4 color2;
    float4 color3;
    float4 color4;
    float4 color5;
    float4 color6;
    float4 color7;
};

float3 paletteGradient(float t, constant Uniforms &u) {
    int count = max(1, min(8, int(u.colorCount)));
    float3 colors[8] = {u.color0.rgb, u.color1.rgb, u.color2.rgb, u.color3.rgb,
                         u.color4.rgb, u.color5.rgb, u.color6.rgb, u.color7.rgb};
    if (count == 1) {
        return colors[0];
    }
    float scaled = clamp(t, 0.0, 0.999) * float(count - 1);
    int index = int(scaled);
    float f = fract(scaled);
    return mix(colors[index], colors[min(index + 1, count - 1)], f);
}

float rippleWave(float2 p, float pulse) {
    float age = 1.0 - pulse;
    float ringRadius = age * 2.4;
    float dist = length(p);
    float wave = sin((dist - ringRadius) * 16.0) * exp(-abs(dist - ringRadius) * 5.0);
    return wave * pulse;
}

float puddleHeight(float2 p, float t, float bassT, float kickPulse, float trebleN, float midSmooth, float4 ripplePulses0, float4 ripplePulses1) {
    float h = 0.0;
    h += sin(p.x * 3.0 + t * 1.1) * 0.5;
    h += sin(p.y * 2.6 - t * 0.9) * 0.5;
    h += sin((p.x + p.y) * 2.0 + t * 1.4) * (0.3 + midSmooth * 0.7);

    h += sin(length(p) * 1.6 - bassT * 1.2) * (0.15 + kickPulse * 1.1);

    h += sin(p.x * 6.0 - p.y * 5.0 + t * 2.2) * 0.34 * (0.5 + trebleN * 1.8);

    h += rippleWave(p, ripplePulses0.x) * 0.4;
    h += rippleWave(p, ripplePulses0.y) * 0.4;
    h += rippleWave(p, ripplePulses0.z) * 0.4;
    h += rippleWave(p, ripplePulses0.w) * 0.4;
    h += rippleWave(p, ripplePulses1.x) * 0.4;
    h += rippleWave(p, ripplePulses1.y) * 0.4;
    h += rippleWave(p, ripplePulses1.z) * 0.4;
    h += rippleWave(p, ripplePulses1.w) * 0.4;

    return h;
}

float oceanHeight(float2 p, float t, float bassN, float midN, float trebleN) {
    float2 dir1 = normalize(float2(1.0, 0.15));
    float2 dir2 = normalize(float2(0.7, -0.4));
    float2 dir3 = normalize(float2(0.3, 0.9));

    float h = 0.0;
    h += sin(dot(p, dir1) * 2.0 + t * 1.0) * 0.35;
    h += sin(dot(p, dir2) * 3.3 - t * 1.4) * 0.25;
    h += sin(dot(p, dir2) * 1.1 + t * 0.6) * 0.3 * (0.3 + bassN * 1.8);
    h += sin(dot(p, dir3) * 5.1 + t * 2.0) * 0.24 * (0.3 + midN * 2.2);
    h += sin(dot(p, dir1) * 8.0 - t * 2.6 + dot(p, dir3) * 2.0) * 0.14 * (0.3 + trebleN * 2.0);
    return h;
}

float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float starField(float2 p, float density, float time) {
    float2 gridPos = p * density;
    float2 cell = floor(gridPos);
    float2 cellUV = fract(gridPos);

    float2 starPos = float2(hash21(cell), hash21(cell + float2(17.0, 31.0)));
    float dist = length(cellUV - starPos);

    float starSeed = hash21(cell + float2(99.0, 7.0));
    float exists = step(0.72, hash21(cell + float2(5.0, 5.0)));

    float twinkle = sin(time * (2.0 + starSeed * 4.0) + starSeed * 20.0) * 0.5 + 0.5;
    twinkle = mix(0.3, 1.0, twinkle) * 0.7;

    float starSize = 0.026 + starSeed * 0.04;
    float brightness = smoothstep(starSize, 0.0, dist) * twinkle * exists;

    return brightness;
}

float vocalSparkleField(float2 p, float density, float time, float activity) {
    float2 gridPos = p * density;
    float2 cell = floor(gridPos);
    float2 cellUV = fract(gridPos);

    float2 starPos = float2(hash21(cell), hash21(cell + float2(17.0, 31.0)));
    float dist = length(cellUV - starPos);

    float starSeed = hash21(cell + float2(99.0, 7.0));
    float existsThreshold = mix(0.88, 0.42, activity);
    float exists = step(existsThreshold, hash21(cell + float2(5.0, 5.0)));

    float twinkle = sin(time * (2.0 + starSeed * 4.0) + starSeed * 20.0) * 0.5 + 0.5;
    twinkle = mix(0.4, 1.0, twinkle);

    float starSize = 0.03 + starSeed * 0.045;
    float brightness = smoothstep(starSize, 0.0, dist) * twinkle * exists;

    return brightness;
}

constant int waveformCount = 512;

float sampleWaveform(constant float *waveform, float x) {
    float pos = clamp(x, 0.0, 0.999) * float(waveformCount - 1);
    int i0 = int(pos);
    int i1 = min(i0 + 1, waveformCount - 1);
    float f = fract(pos);
    return mix(waveform[i0], waveform[i1], f);
}

fragment float4 fragmentMain(VertexOut in [[stage_in]],
                              constant Uniforms &u [[buffer(0)]],
                              constant float *waveform [[buffer(1)]]) {
    float bassN = clamp(u.bass / 3000.0, 0.0, 1.0);
    float midN = clamp(u.mid / 40.0, 0.0, 1.0);
    float trebleN = clamp(u.treble / 2.0, 0.0, 1.0);

    float totalEnergy = bassN + midN + trebleN;
    float energyCompression = mix(1.0, 0.55, smoothstep(1.2, 2.6, totalEnergy));
    bassN *= energyCompression;
    midN *= energyCompression;
    trebleN *= energyCompression;

    float2 kUV;
    if (u.kaleidoscopeEnabled > 0.5) {
        float2 center = float2(0.5, 0.5);
        float2 toCenter = in.uv - center;
        float radius = length(toCenter);
        float angle = atan2(toCenter.y, toCenter.x);

        const int segments = 6;
        float segmentAngle = (2.0 * M_PI_F) / float(segments);
        angle = fmod(angle, segmentAngle);
        if (angle < 0.0) angle += segmentAngle;
        angle = abs(angle - segmentAngle * 0.5);

        kUV = center + radius * float2(cos(angle), sin(angle));
    } else {
        kUV = in.uv;
    }
    float2 p = kUV * 2.0 - 1.0;

    float hueShift = (u.hueCyclingEnabled > 0.5) ? (u.time * 0.05) : 0.0;

    float gradientT = fract(clamp(kUV.y, 0.0, 1.0));
    float3 color = paletteGradient(gradientT, u) * 0.24;

    float fog = sin(p.x * 0.4 + u.time * 0.05) * sin(p.y * 0.6 - u.time * 0.04) * 0.5 + 0.5;
    color += paletteGradient(fract(fog), u) * 0.14;

    float driftT = sin(p.x * 0.9 - u.time * 0.03) * cos(p.y * 0.7 + u.time * 0.025) * 0.5 + 0.5;
    color += paletteGradient(fract(driftT + 0.3), u) * 0.1;

    if (u.atmosphereMode < 0.5) {
        const int echoCount = (u.echoTrailsEnabled > 0.5) ? 5 : 1;
        for (int e = 0; e < echoCount; e++) {
            float echoT = float(e) / float(echoCount);
            float phaseOffset = (u.echoTrailsEnabled > 0.5) ? echoT * 0.06 : 0.0;
            float baselineOffset = (u.echoTrailsEnabled > 0.5) ? (echoT - 0.5) * 0.15 : 0.0;

            float gain = 2.5 + u.kickPulse * 3.5;
            float caOffset = (u.chromaticAberrationEnabled > 0.5) ? (0.004 + trebleN * 0.008) : 0.0;

            float ampR = sampleWaveform(waveform, fract(kUV.x + phaseOffset + caOffset)) * gain;
            float ampG = sampleWaveform(waveform, fract(kUV.x + phaseOffset)) * gain;
            float ampB = sampleWaveform(waveform, fract(kUV.x + phaseOffset - caOffset)) * gain;

            float thickness = 0.006 + trebleN * 0.010;

            float distR = abs(p.y - (ampR + baselineOffset));
            float distG = abs(p.y - (ampG + baselineOffset));
            float distB = abs(p.y - (ampB + baselineOffset));

            float glowR = exp(-distR * distR / (thickness * thickness * 6.0));
            float glowG = exp(-distG * distG / (thickness * thickness * 6.0));
            float glowB = exp(-distB * distB / (thickness * thickness * 6.0));

            float echoHueOffset = (u.echoTrailsEnabled > 0.5) ? echoT * 0.5 : 0.0;
            float3 echoColor = paletteGradient(fract(0.15 + midN * 0.7 + echoHueOffset + hueShift), u);
            float echoFade = 1.0 - echoT * 0.7;
            float intensity = echoFade * (0.8 + u.kickPulse * 0.6 + trebleN * 0.4);

            color.r += echoColor.r * glowR * intensity;
            color.g += echoColor.g * glowG * intensity;
            color.b += echoColor.b * glowB * intensity;

            float haloR = exp(-distR * distR / (thickness * thickness * 40.0));
            float haloG = exp(-distG * distG / (thickness * thickness * 40.0));
            float haloB = exp(-distB * distB / (thickness * thickness * 40.0));

            color.r += echoColor.r * haloR * echoFade * 0.25;
            color.g += echoColor.g * haloG * echoFade * 0.25;
            color.b += echoColor.b * haloB * echoFade * 0.25;
        }
    } else if (u.atmosphereMode < 1.5) {
        float eps = 0.01;
        float h = puddleHeight(p, u.puddleTime, u.puddleBassTime, u.kickPulse, u.puddleTrebleSmooth, u.puddleMidSmooth, u.ripplePulses0, u.ripplePulses1);
        float hx = puddleHeight(p + float2(eps, 0.0), u.puddleTime, u.puddleBassTime, u.kickPulse, u.puddleTrebleSmooth, u.puddleMidSmooth, u.ripplePulses0, u.ripplePulses1);
        float hy = puddleHeight(p + float2(0.0, eps), u.puddleTime, u.puddleBassTime, u.kickPulse, u.puddleTrebleSmooth, u.puddleMidSmooth, u.ripplePulses0, u.ripplePulses1);

        float2 normal = float2((h - hx) / eps, (h - hy) / eps);
        float2 lightDir = normalize(float2(0.4, 0.6));
        float highlight = pow(clamp(dot(normal, lightDir), 0.0, 1.0), 3.0);

        float3 puddleColor = paletteGradient(fract(h * 0.15 + 0.5 + hueShift), u);

        color += puddleColor * (0.5 + 0.3 * (h * 0.5 + 0.5));
        color += float3(1.0) * highlight * (0.4 + u.puddleTrebleSmooth * 1.8) * puddleColor;

        color += puddleColor * u.beatPulse * 0.12;
    } else if (u.atmosphereMode < 2.5) {
        float nebula1 = sin(p.x * 1.2 + u.time * 0.04) * cos(p.y * 1.0 - u.time * 0.03) * 0.5 + 0.5;
        float nebula2 = sin((p.x + p.y) * 0.8 - u.spaceTime) * 0.5 + 0.5;
        float3 nebulaColor = paletteGradient(fract(nebula1 * 0.5 + nebula2 * 0.5 + hueShift), u);

        color += nebulaColor * (0.12 + u.spaceKickSmooth * 0.4) * (0.5 + nebula1 * 0.5);

        float stars = starField(p, 24.0, u.time);
        stars += starField(p * 1.6 + float2(37.0, 91.0), 24.0, u.time * 1.4) * 0.7;
        stars += starField(p * 2.3 + float2(11.0, 63.0), 24.0, u.time * 0.8) * 0.5;
        color += float3(1.0) * stars * 0.55;

        float vocalSparkle = vocalSparkleField(p * 4.0 + float2(53.0, 17.0), 24.0, u.time * 2.2, trebleN);
        vocalSparkle += vocalSparkleField(p * 5.5 + float2(19.0, 83.0), 24.0, u.time * 2.8, trebleN) * 0.8;
        color += float3(1.0) * vocalSparkle * trebleN * 3.2;
    } else {
        float eps = 0.01;
        float h = oceanHeight(p, u.oceanTime, bassN, midN, trebleN);
        float hx = oceanHeight(p + float2(eps, 0.0), u.oceanTime, bassN, midN, trebleN);
        float hy = oceanHeight(p + float2(0.0, eps), u.oceanTime, bassN, midN, trebleN);
        float2 grad = float2((h - hx) / eps, (h - hy) / eps);
        float slope = length(grad);

        float crestLoosen = clamp((midN + trebleN) * 0.35, 0.0, 0.5);
        float crestMask = smoothstep(0.35, 0.65, h) * smoothstep(0.9 - crestLoosen, 1.6, slope);

        float sparkle = sin(p.x * 140.0 + p.y * 90.0 + u.time * 3.0)
                       + sin(p.x * -110.0 + p.y * 130.0 - u.time * 2.4)
                       + sin(p.x * 95.0 - p.y * 150.0 + u.time * 3.7);
        sparkle = sparkle / 3.0 * 0.5 + 0.5;
        sparkle = smoothstep(0.55, 0.85, sparkle);

        float foam = crestMask * sparkle * (0.4 + trebleN * 2.0 + midN * 1.4);

        float depthT = fract(clamp(kUV.y + h * 0.1, 0.0, 1.0) + hueShift);
        float3 oceanColor = paletteGradient(depthT, u);

        color += oceanColor * (0.4 + 0.3 * (h * 0.5 + 0.5));
        color += float3(1.0) * foam * 0.8;
    }

    float peak = max(color.r, max(color.g, color.b));
    color = color / (1.0 + peak * 0.4);

    return float4(color, 1.0);
}
