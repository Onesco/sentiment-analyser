/* eslint-disable @typescript-eslint/no-require-imports */
// esbuild.config.js
const { build } = require('esbuild');
const { dependencies } = require('./package.json');

build({
  entryPoints: ['apps/worker/src/main.ts'],
  bundle: true,
  minify: false,
  external: Object.keys(dependencies),
  platform: 'node',
  format: 'cjs',
  outfile: 'dist/function.js',
});
