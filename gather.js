const fs = require("fs");
const path = require("path");
const os = require("os");

const baseDir = typeof __dirname !== "undefined" ? __dirname : process.cwd();

const targetDir = path.join(os.homedir(), "storage");

const imageExtensions = [".jpg", ".jpeg", ".png"];
const videoExtensions = [".mp4", ".MP4"];

let imageResults = [];
let videoResults = [];

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
          
          if (imageExtensions.includes(ext)) {
            imageResults.push({
              path: fullPath,
              time: stat.mtimeMs
            });
          } else if (videoExtensions.includes(ext)) {
            videoResults.push({
              path: fullPath,
              time: stat.mtimeMs
            });
          }
        }
      } catch (err) {
      }
    }
  } catch (err) {
  }
}

console.log("Work in progress ...");
scanDir(targetDir);

imageResults.sort((a, b) => b.time - a.time);
videoResults.sort((a, b) => b.time - a.time);

let newImagePaths = imageResults.map(r => r.path);
let newVideoPaths = videoResults.map(r => r.path);

let newPaths = [...newImagePaths, ...newVideoPaths];

const fileName = "stonx-mg.txt";
const outputFile = path.join(baseDir, fileName);

let oldPaths = [];
if (fs.existsSync(outputFile)) {
  oldPaths = fs.readFileSync(outputFile, "utf-8")
    .split("\n")
    .filter(Boolean);
}

const finalPaths = Array.from(new Set([...newPaths, ...oldPaths]));

fs.writeFileSync(outputFile, finalPaths.join("\n"));

console.log("✅ Completed successfully ");
console.log(`📊 Statistics_1: ${newImagePaths.length}`);
console.log(`📊 Statistics_2: ${newVideoPaths.length}`);
console.log(`📩 Total statistics: ${newPaths.length}`);
console.log(`📝 file name: ${fileName}`);
console.log(`📍 the site: ${outputFile}`);
