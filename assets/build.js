const esbuild = require("esbuild");
const path = require("path")
const fs = require("fs")

const args = process.argv.slice(2);
const watch = args.includes('--watch');
const deploy = args.includes('--deploy');

const loader = {
  // Add loaders for images/fonts/etc, e.g. { '.svg': 'file' }
};

const plugins = [
  // Add and configure plugins here
];

function copyCSS() {
  const srcDir = path.join(__dirname, "css")
  const destDir = path.join(__dirname, "..", "priv", "static", "assets", "css")

  if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir, { recursive: true });
  }

  // Copy *.css from assets/css to priv/static/assets/css
  const files = fs.readdirSync(srcDir);
  files.forEach(file => {
    const srcFile = path.join(srcDir, file);
    if (!file.endsWith(".css")) {
      return;
    }
    const destFile = path.join(destDir, file);

    // Only copy files, not directories
    if (fs.statSync(srcFile).isFile()) {
      fs.copyFileSync(srcFile, destFile);
      console.log(`Copied css/${file}`);
    }
  });
}

// Define esbuild options
let opts = {
  entryPoints: ["js/app.js"],
  bundle: true,
  logLevel: "info",
  target: "es2022",
  outdir: "../priv/static/assets/js",
  external: ["*.css", "fonts/*", "images/*", "audio/*"],
  nodePaths: ["../deps", process.env.NODE_PATH].filter(p => p != null),
  loader: loader,
  plugins: plugins,
};

if (deploy) {
  opts = {
    ...opts,
    minify: true,
  };
}

if (watch) {
  opts = {
    ...opts,
    sourcemap: "inline",
  };

  copyCSS();

  fs.watch(path.join(__dirname, "css"), (e, filename) => {
    if (filename) {
      copyCSS();
    }
  });

  esbuild
    .context(opts)
    .then((ctx) => {
      ctx.watch();
    })
    .catch((_error) => {
      process.exit(1);
    });
} else {
  copyCSS();
  esbuild.build(opts);
}
