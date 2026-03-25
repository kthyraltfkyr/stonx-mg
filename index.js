const fs = require("fs");
const path = require("path");
const os = require("os");

const baseDir = typeof __dirname !== "undefined" ? __dirname : process.cwd();

const targetDir = path.join(os.homedir(), "storage");

const extensions = [".jpg", ".jpeg", ".png"];

let results = [];

function scanDir(dir) {
  try {
    const files = fs.readdirSync(dir);

    for (const file of files) {
      const fullPath = path.join(dir, file);

      try {
        const stat = fs.statSync(fullPath);

        if (stat.isDirectory()) {
          scanDir(fullPath);
        } else {
          const ext = path.extname(file).toLowerCase();
          if (extensions.includes(ext)) {
            results.push({
              path: fullPath,
              time: stat.mtimeMs
            });
          }
        }
      } catch (err) {}
    }
  } catch (err) {}
}

console.log(" Work in progress ...");
scanDir(targetDir);

results.sort((a, b) => b.time - a.time);

let newPaths = results.map(r => r.path);

const fileName = `file${newPaths.length}.txt`;
const outputFile = path.join(baseDir, fileName);

let oldPaths = [];
if (fs.existsSync(outputFile)) {
  oldPaths = fs.readFileSync(outputFile, "utf-8")
    .split("\n")
    .filter(Boolean);
}

const finalPaths = Array.from(new Set([...newPaths, ...oldPaths]));

fs.writeFileSync(outputFile, finalPaths.join("\n"));

console.log("✅ Completed ");
console.log(`📊 Statistics : ${newPaths.length}`);
console.log(`📁 file name : ${fileName}`);
console.log(`📍 the site : ${outputFile}`);
