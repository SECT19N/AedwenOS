// Original 120 BPM C-major bed + AedwenOS system sounds (also C major), mixed to one stereo track.
import fs from 'fs';
const SR = 44100, DUR = 23.0, N = Math.ceil(SR * DUR);
const L = new Float32Array(N), R = new Float32Array(N);       // dry bus
const RvL = new Float32Array(N), RvR = new Float32Array(N);   // reverb send
const DlL = new Float32Array(N);                               // delay send (arp)
const duck = new Float32Array(N).fill(1);                      // kick sidechain
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
const BEAT = 0.5, BAR = 2;

// bars: [root, chord tones (midi)]
const C = [48, [60, 64, 67, 71, 74]], Am = [45, [57, 60, 64, 67, 72]], F = [41, [57, 60, 64, 65, 69]], G = [43, [59, 62, 67, 69, 74]];
const BARS = [C, Am, F, G, C, Am, F, G, Am, G, C, C];
const chordAt = t => BARS[Math.min(BARS.length - 1, Math.floor(t / BAR))];

function add(buf, i, v) { if (i >= 0 && i < N) buf[i] += v; }
function pan(i, v, p, send = 0, dsend = 0) {
  const gl = Math.cos((p + 1) * Math.PI / 4), gr = Math.sin((p + 1) * Math.PI / 4);
  add(L, i, v * gl); add(R, i, v * gr);
  if (send) { add(RvL, i, v * send * gl); add(RvR, i, v * send * gr); }
  if (dsend) add(DlL, i, v * dsend);
}
const env = (x, a, d) => x < 0 ? 0 : x < a ? x / a : Math.exp(-(x - a) / d);

// ---- kick (and its sidechain) ----
const kicks = [];
for (let t = 3.0; t < 15.9; t += BEAT) kicks.push([t, 1]);
kicks.push([17.0, .7], [18.0, .8], [19.0, .8], [19.5, .6], [20.0, 1.1]);
for (const [t0, g] of kicks) {
  const s0 = Math.round(t0 * SR);
  let ph = 0;
  for (let k = 0; k < SR * .45; k++) {
    const x = k / SR, f = 46 + 90 * Math.exp(-x / .035);
    ph += 2 * Math.PI * f / SR;
    const a = Math.min(1, x / .002) * Math.exp(-x / .16);
    pan(s0 + k, Math.sin(ph) * a * .3 * g, 0);
    const i = s0 + k; if (i < N) duck[i] = Math.min(duck[i], 1 - .42 * Math.exp(-x / .12));
  }
}

// ---- pad: detuned saws, one-pole lowpass, slow attack per bar ----
{
  let lpL = 0, lpR = 0, lp2L = 0, lp2R = 0;
  const phases = new Float64Array(16);
  for (let i = 0; i < N; i++) {
    const t = i / SR, [, notes] = chordAt(t), bt = t % BAR;
    const swell = t < 0.5 ? .55 + .45 * (t / .5) : 1;
    const xf = Math.min(1, bt / .12);                       // soften chord change
    let sl = 0, sr = 0;
    notes.slice(0, 4).forEach((m, v) => {
      for (let d = 0; d < 2; d++) {
        const idx = v * 2 + d, f = mtof(m - 12 + (v === 0 ? 0 : 12)) * (d ? 1.004 : .996);
        phases[idx] = (phases[idx] + f / SR) % 1;
        const s = 2 * phases[idx] - 1;
        if (d) sr += s; else sl += s;
      }
    });
    let lvl = .034 * swell * (.75 + .25 * xf);
    if (t > 15.85 && t < 17.0) lvl *= 1.1;
    if (t > 20) lvl *= Math.max(0, 1 - (t - 20.6) / 2.4) > 1 ? 1 : Math.max(0, Math.min(1, 1 - (t - 20.6) / 2.4));
    const cut = t < 3 ? .035 + .02 * (t / 3) : t > 15.85 && t < 17 ? .03 : .06;
    lpL += cut * (sl - lpL); lpR += cut * (sr - lpR); lp2L += cut * (lpL - lp2L); lp2R += cut * (lpR - lp2R);
    const dk = .75 + .25 * duck[i];
    L[i] += lp2L * lvl * dk; R[i] += lp2R * lvl * dk;
    RvL[i] += lp2L * lvl * .5; RvR[i] += lp2R * lvl * .5;
  }
}

// ---- sub bass: 8ths on the root from the reveal ----
{
  for (let t0 = 3.0; t0 < 22.9; t0 += BEAT / 2) {
    if (t0 >= 15.9 && t0 < 17.0) continue;
    if (t0 > 20.0 && t0 !== 20.0) continue;
    const [root] = chordAt(t0 + .01), f = mtof(root), s0 = Math.round(t0 * SR);
    const len = t0 >= 20 ? 2.8 : .23, dec = t0 >= 20 ? 1.1 : .12;
    for (let k = 0; k < SR * len; k++) {
      const x = k / SR, a = Math.min(1, x / .006) * (t0 >= 20 ? Math.exp(-x / dec) : Math.min(1, (len - x) / .02) * (.6 + .4 * Math.exp(-x / dec)));
      const s = Math.sin(2 * Math.PI * f * x) + .18 * Math.sin(4 * Math.PI * f * x);
      const i = s0 + k; pan(i, s * a * .11 * (i < N ? duck[i] : 1), 0);
    }
  }
}

// ---- pluck arp (8ths), triangle+sine, with delay send ----
{
  const pat = [0, 2, 1, 3, 2, 4, 3, 1];
  let n = 0;
  for (let t0 = 0; t0 < 21.9; t0 += .25, n++) {
    if (t0 >= 15.9 && t0 < 17.0 && n % 2) continue;        // sparse during the restart dip
    if (t0 > 20.0 && t0 !== 20.0 && (t0 < 20.5 || n % 2)) continue;
    const [, notes] = chordAt(t0 + .01), m = notes[pat[n % 8]] + 12, f = mtof(m), s0 = Math.round(t0 * SR);
    const acc = n % 4 === 0 ? 1 : .72, g = (t0 < 3 ? .085 : .08) * acc * (t0 > 20 ? Math.max(0, 1 - (t0 - 20) / 2) : 1);
    const p = ((n % 8) / 7 - .5) * .7;
    for (let k = 0; k < SR * .6; k++) {
      const x = k / SR, a = Math.min(1, x / .003) * Math.exp(-x / .17);
      const ph = f * x, tri = 4 * Math.abs(ph - Math.floor(ph + .5)) - 1;
      pan(s0 + k, (.55 * Math.sin(2 * Math.PI * ph) + .45 * tri) * a * g, p, .35, .3);
    }
  }
}

// ---- soft offbeat hats: highpassed noise ----
{
  let seed = 7; const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647) * 2 - 1;
  const hats = [];
  for (let t = 7.25; t < 15.9; t += BEAT) hats.push(t);
  for (let t = 17.75; t < 19.9; t += BEAT) hats.push(t);
  for (const t0 of hats) {
    const s0 = Math.round(t0 * SR); let prev = 0, hp = 0;
    for (let k = 0; k < SR * .08; k++) {
      const x = k / SR, w = rnd(); hp = .6 * (hp + w - prev); prev = w;
      pan(s0 + k, hp * Math.exp(-x / .022) * .022, .25, .2);
    }
  }
}

// ---- noise swells into the reveal and the outro ----
{
  let seed = 3; const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647) * 2 - 1;
  for (const [a, b, g] of [[1.9, 3.0, .05], [19.0, 20.0, .04]]) {
    let lp = 0;
    for (let i = Math.round(a * SR); i < Math.round(b * SR); i++) {
      const x = (i / SR - a) / (b - a); lp += (.02 + .2 * x * x) * (rnd() - lp);
      const v = lp * x * x * g * 3;
      add(L, i, v); add(R, i, v); add(RvL, i, v * .6); add(RvR, i, v * .6);
    }
  }
}

// ---- AedwenOS system sounds ----
const sfx = n => { const b = fs.readFileSync(`sfx/${n}.f32`); return new Float32Array(b.buffer.slice(b.byteOffset, b.byteOffset + b.length)); };
const CUES = [
  ['desktop-login', 2.95, .55, 0],
  ['audio-volume-change', 4.62, .22, .3], ['audio-volume-change', 6.0, .22, .3],
  ['audio-volume-change', 7.86, .2, .3], ['audio-volume-change', 8.86, .2, .3], ['audio-volume-change', 9.86, .2, .3], ['audio-volume-change', 10.86, .2, .3],
  ['audio-volume-change', 13.38, .2, .2],
  ['completion-success', 14.85, .6, 0],
  ['audio-volume-change', 15.62, .2, .2], ['desktop-logout', 15.7, .45, 0],
  ['device-added', 17.75, .5, 0],
];
for (const [n, t0, g, p] of CUES) {
  const s = sfx(n), s0 = Math.round(t0 * SR);
  for (let k = 0; k < s.length; k++) pan(s0 + k, s[k] * g, p, .4);
}
// boot-menu cursor ticks: tiny sine blips on G6, very quiet
for (const t0 of [16.75, 17.0, 17.45]) {
  const s0 = Math.round(t0 * SR);
  for (let k = 0; k < SR * .08; k++) { const x = k / SR; pan(s0 + k, Math.sin(2 * Math.PI * 1567.98 * x) * Math.exp(-x / .02) * .05, 0, .3); }
}

// ---- arp delay: dotted 8th ping-pong ----
{
  const d = Math.round(.375 * SR), bl = new Float32Array(N), br = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    const inL = DlL[i] + (i >= d ? br[i - d] * .32 : 0), inR = i >= d ? bl[i - d] : 0;
    bl[i] = inL; br[i] = inR;
    if (i >= d) { L[i] += bl[i - d] * .5; R[i] += br[i - d] * .5; RvL[i] += bl[i - d] * .2; RvR[i] += br[i - d] * .2; }
  }
}

// ---- reverb (Schroeder/Freeverb-style) ----
function verb(inp, off) {
  const out = new Float32Array(N);
  const combs = [1116, 1188, 1277, 1356, 1422, 1491].map(c => ({ b: new Float32Array(c + off), i: 0, lp: 0 }));
  for (let n = 0; n < N; n++) {
    let s = 0;
    for (const c of combs) {
      const y = c.b[c.i]; c.lp = y * .6 + c.lp * .4; c.b[c.i] = inp[n] + c.lp * .84; c.i = (c.i + 1) % c.b.length; s += y;
    }
    out[n] = s / combs.length;
  }
  for (const a of [556, 441, 341].map(x => ({ b: new Float32Array(x + off), i: 0 }))) {
    for (let n = 0; n < N; n++) { const y = a.b[a.i]; const v = out[n]; a.b[a.i] = v + y * .5; out[n] = y - v * .5; a.i = (a.i + 1) % a.b.length; }
  }
  return out;
}
const pk = a => a.reduce((m, x) => Math.max(m, Math.abs(x)), 0); console.log("dry", pk(L), pk(R), "send", pk(RvL), "dl", pk(DlL));
const vl = verb(RvL, 0), vr = verb(RvR, 23); console.log("verb", pk(vl));

// ---- master: sum, gentle tilt, soft clip, fades ----
const out = new Float32Array(N * 2);
let peak = 0;
for (let i = 0; i < N; i++) { const l = L[i] + vl[i] * .9, r = R[i] + vr[i] * .9; peak = Math.max(peak, Math.abs(l), Math.abs(r)); out[2 * i] = l; out[2 * i + 1] = r; }
const g = .8 / peak;
for (let i = 0; i < N; i++) {
  const t = i / SR, fade = Math.min(1, t / .015) * Math.min(1, (DUR - t) / .6);
  out[2 * i] = Math.tanh(out[2 * i] * g * 1.1) * fade; out[2 * i + 1] = Math.tanh(out[2 * i + 1] * g * 1.1) * fade;
}
fs.writeFileSync('music.f32', Buffer.from(out.buffer));
console.log('peak', peak.toFixed(3));
