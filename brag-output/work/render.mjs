import { chromium } from 'playwright-core';
import { spawn } from 'child_process';
import path from 'path';
const exe = process.env.HOME + '/.cache/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell';
const FPS = 30;
const b = await chromium.launch({ executablePath: exe, args: ['--allow-file-access-from-files', '--force-color-profile=srgb'] });
const p = await b.newPage({ viewport: { width: 1920, height: 1080 } });
p.on('pageerror', e => console.log('ERR', e.message));
await p.goto('file://' + path.resolve('index.html')); await p.evaluate(() => window.ready);
const dur = await p.evaluate(() => window.DUR), n = Math.round(dur * FPS);
const ff = spawn('ffmpeg', ['-v', 'error', '-y', '-f', 'image2pipe', '-framerate', String(FPS), '-i', '-', '-i', 'music.wav',
  '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-colorspace', 'bt709',
  '-vf', 'scale=out_color_matrix=bt709', '-c:a', 'aac', '-b:a', '256k', '-shortest', '-movflags', '+faststart', 'raw.mp4'], { stdio: ['pipe', 'inherit', 'inherit'] });
for (let i = 0; i < n; i++) {
  await p.evaluate(t => render(t), i / FPS);
  const buf = await p.screenshot({ type: 'png' });
  if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
  if (i % 60 === 0) console.log('frame', i, '/', n);
}
ff.stdin.end(); await new Promise(r => ff.on('close', r)); await b.close(); console.log('done');
