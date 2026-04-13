#!/usr/bin/env node

// compass-cc installer
// Copies COMPASS skills, agents, scripts, templates, hooks, and references
// to ~/.claude/ and registers hooks in settings.json.

const fs = require("fs");
const path = require("path");
const os = require("os");

const CLAUDE_DIR = path.join(os.homedir(), ".claude");
const COMPASS_DIR = path.join(CLAUDE_DIR, "compass");
const SKILLS_DIR = path.join(CLAUDE_DIR, "skills");
const HOOKS_DIR = path.join(CLAUDE_DIR, "hooks");
const SETTINGS_FILE = path.join(CLAUDE_DIR, "settings.json");

// Source directory — where the npm package was installed
const SRC = path.resolve(__dirname, "..");

const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const RED = "\x1b[31m";
const NC = "\x1b[0m";

function info(msg) {
  console.log(`${GREEN}[compass]${NC} ${msg}`);
}
function warn(msg) {
  console.log(`${YELLOW}[compass]${NC} ${msg}`);
}
function err(msg) {
  console.error(`${RED}[compass]${NC} ${msg}`);
}

function mkdirp(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function copyFile(src, dest) {
  fs.copyFileSync(src, dest);
}

function copyDir(srcDir, destDir, pattern) {
  mkdirp(destDir);
  const files = fs.readdirSync(srcDir).filter((f) => {
    if (!pattern) return true;
    return f.match(pattern);
  });
  for (const file of files) {
    const srcPath = path.join(srcDir, file);
    const destPath = path.join(destDir, file);
    if (fs.statSync(srcPath).isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      copyFile(srcPath, destPath);
    }
  }
  return files.length;
}

function makeExecutable(filePath) {
  try {
    fs.chmodSync(filePath, 0o755);
  } catch (_) {
    // Windows — chmod not supported, skip
  }
}

// --- Uninstall ---

function doUninstall() {
  info("Uninstalling COMPASS...");

  // Remove skills
  if (fs.existsSync(SKILLS_DIR)) {
    const skillDirs = fs
      .readdirSync(SKILLS_DIR)
      .filter((d) => d.startsWith("compass-"));
    for (const d of skillDirs) {
      const p = path.join(SKILLS_DIR, d);
      fs.rmSync(p, { recursive: true, force: true });
      info(`  removed: ${p}`);
    }
  }

  // Remove compass runtime
  if (fs.existsSync(COMPASS_DIR)) {
    fs.rmSync(COMPASS_DIR, { recursive: true, force: true });
    info(`  removed: ${COMPASS_DIR}`);
  }

  // Remove hooks
  if (fs.existsSync(HOOKS_DIR)) {
    const hooks = fs
      .readdirSync(HOOKS_DIR)
      .filter((f) => f.startsWith("compass-"));
    for (const h of hooks) {
      fs.unlinkSync(path.join(HOOKS_DIR, h));
      info(`  removed: ${path.join(HOOKS_DIR, h)}`);
    }
  }

  // Remove hook registrations from settings.json
  if (fs.existsSync(SETTINGS_FILE)) {
    try {
      const settings = JSON.parse(fs.readFileSync(SETTINGS_FILE, "utf-8"));
      if (settings.hooks) {
        for (const hookType of ["PostToolUse", "PreToolUse"]) {
          if (Array.isArray(settings.hooks[hookType])) {
            settings.hooks[hookType] = settings.hooks[hookType].filter(
              (entry) => !JSON.stringify(entry).includes("compass-")
            );
          }
        }
        fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2));
        info("  cleaned hook registrations from settings.json");
      }
    } catch (e) {
      warn(`  could not clean settings.json: ${e.message}`);
    }
  }

  info("COMPASS uninstalled.");
  process.exit(0);
}

// --- Install ---

function installSkills() {
  const skillsRoot = path.join(SRC, "skills");
  if (!fs.existsSync(skillsRoot)) {
    err("skills/ not found in package");
    process.exit(1);
  }

  const skillDirs = fs
    .readdirSync(skillsRoot)
    .filter((d) => d.startsWith("compass-"));
  for (const d of skillDirs) {
    const target = path.join(SKILLS_DIR, d);
    mkdirp(target);
    copyFile(
      path.join(skillsRoot, d, "SKILL.md"),
      path.join(target, "SKILL.md")
    );
    info(`  skill: ${d}`);
  }
  return skillDirs.length;
}

function installAgents() {
  const count = copyDir(
    path.join(SRC, "agents"),
    path.join(COMPASS_DIR, "agents"),
    /\.md$/
  );
  info(`  agents: ${count} files`);
}

function installScripts() {
  mkdirp(path.join(COMPASS_DIR, "scripts"));
  const src = path.join(SRC, "scripts", "compass-tools.sh");
  const dest = path.join(COMPASS_DIR, "scripts", "compass-tools.sh");
  copyFile(src, dest);
  makeExecutable(dest);
  info("  scripts: compass-tools.sh");
}

function installTemplates() {
  const count = copyDir(
    path.join(SRC, "templates"),
    path.join(COMPASS_DIR, "templates")
  );
  info(`  templates: ${count} files`);
}

function installConstitutionAndRefs() {
  copyFile(
    path.join(SRC, "constitution.md"),
    path.join(COMPASS_DIR, "constitution.md")
  );
  const count = copyDir(
    path.join(SRC, "references"),
    path.join(COMPASS_DIR, "references"),
    /\.md$/
  );
  info(`  constitution + ${count} reference(s)`);
}

function installHooks() {
  mkdirp(HOOKS_DIR);
  const hooksRoot = path.join(SRC, "hooks");
  const hooks = fs
    .readdirSync(hooksRoot)
    .filter((f) => f.startsWith("compass-"));
  for (const h of hooks) {
    const dest = path.join(HOOKS_DIR, h);
    copyFile(path.join(hooksRoot, h), dest);
    makeExecutable(dest);
    info(`  hook: ${h}`);
  }
  return hooks;
}

function registerHooks(hookFiles) {
  let settings = {};

  if (fs.existsSync(SETTINGS_FILE)) {
    try {
      settings = JSON.parse(fs.readFileSync(SETTINGS_FILE, "utf-8"));
    } catch (e) {
      warn(`could not parse settings.json: ${e.message}`);
      warn("hooks not registered — add them manually");
      return;
    }
  }

  if (!settings.hooks) settings.hooks = {};

  const hookDefs = [
    {
      type: "PostToolUse",
      matcher: "Write|Edit",
      file: "compass-scope-guardian.sh",
    },
    {
      type: "PostToolUse",
      matcher: "*",
      file: "compass-context-monitor.sh",
    },
    {
      type: "PreToolUse",
      matcher: "Skill",
      file: "compass-preflight.sh",
    },
    {
      type: "PreToolUse",
      matcher: "Bash",
      file: "compass-commit-check.sh",
    },
  ];

  for (const def of hookDefs) {
    if (!Array.isArray(settings.hooks[def.type])) {
      settings.hooks[def.type] = [];
    }

    const cmdPath = path.join(HOOKS_DIR, def.file);
    const already = settings.hooks[def.type].some((entry) =>
      JSON.stringify(entry).includes(def.file)
    );

    if (!already) {
      settings.hooks[def.type].push({
        matcher: def.matcher,
        hooks: [{ type: "command", command: cmdPath }],
      });
    }
  }

  fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2));
  info("  hooks registered in settings.json");
}

// --- Main ---

function main() {
  const args = process.argv.slice(2);

  if (args.includes("--uninstall")) {
    doUninstall();
    return;
  }

  info("Installing COMPASS to ~/.claude/");
  console.log();

  // Create base directories
  mkdirp(COMPASS_DIR);
  mkdirp(SKILLS_DIR);

  // Install components
  const skillCount = installSkills();
  installAgents();
  installScripts();
  installTemplates();
  installConstitutionAndRefs();
  const hookFiles = installHooks();
  registerHooks(hookFiles);

  console.log();
  info("COMPASS installed successfully!");
  console.log();
  console.log(`  Skills:      ${SKILLS_DIR}/compass-*/`);
  console.log(`  Runtime:     ${COMPASS_DIR}/`);
  console.log(`  Hooks:       ${HOOKS_DIR}/compass-*.sh`);
  console.log();
  console.log("  Get started: /compass:init in any project");
  console.log("  Navigation:  /compass:next | /compass:status");
  console.log();
  console.log(
    `  Uninstall:   npx compass-cc --uninstall`
  );
}

main();
