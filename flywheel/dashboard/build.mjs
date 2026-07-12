#!/usr/bin/env node
// Build flywheel/dashboard/dashboard.html from config.json + state/*.json.
//
// Run from anywhere: node flywheel/dashboard/build.mjs
// Override the "generated" timestamp for deterministic builds:
//   FLYWHEEL_BUILD_TS=2026-07-06T00:00 node flywheel/dashboard/build.mjs

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const FLYWHEEL_DIR = path.dirname(SCRIPT_DIR);
const CONFIG_PATH = path.join(FLYWHEEL_DIR, "config.json");
const STATE_DIR = path.join(FLYWHEEL_DIR, "state");
const TEMPLATE_PATH = path.join(SCRIPT_DIR, "template.html");
const OUTPUT_PATH = path.join(SCRIPT_DIR, "dashboard.html");

const PLACEHOLDER = "/*__FLYWHEEL_DATA__*/ null";

function loadJson(p) {
  if (!fs.existsSync(p)) {
    console.error(`flywheel dashboard build: missing file: ${p}`);
    process.exit(1);
  }
  let text;
  try {
    text = fs.readFileSync(p, "utf-8");
    return JSON.parse(text);
  } catch (e) {
    console.error(`flywheel dashboard build: invalid JSON in ${p}: ${e.message}`);
    process.exit(1);
  }
}

function nowToMinute() {
  const d = new Date();
  const pad = n => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function mdToHtml(mdText) {
  const htmlLines = [];
  let inList = false;
  for (let line of mdText.split(/\r?\n/)) {
    line = line.trim();
    if (!line) continue;
    if (line.startsWith("# ")) {
      if (inList) { htmlLines.push("</ul>"); inList = false; }
      htmlLines.push(`<h3>${line.slice(2)}</h3>`);
    } else if (line.startsWith("## ")) {
      if (inList) { htmlLines.push("</ul>"); inList = false; }
      htmlLines.push(`<h4>${line.slice(3)}</h4>`);
    } else if (line.startsWith("- ")) {
      if (!inList) { htmlLines.push("<ul style='margin-top:4px; margin-bottom:12px;'>"); inList = true; }
      const parts = line.slice(2).split("`");
      let formatted = "";
      for (let i = 0; i < parts.length; i++) {
        if (i % 2 === 1) formatted += `<code>${parts[i]}</code>`;
        else formatted += parts[i];
      }
      htmlLines.push(`<li>${formatted}</li>`);
    } else {
      if (inList) { htmlLines.push("</ul>"); inList = false; }
      const parts = line.split("`");
      let formatted = "";
      for (let i = 0; i < parts.length; i++) {
        if (i % 2 === 1) formatted += `<code>${parts[i]}</code>`;
        else formatted += parts[i];
      }
      htmlLines.push(`<p>${formatted}</p>`);
    }
  }
  if (inList) htmlLines.push("</ul>");
  return htmlLines.join("\n");
}

function main() {
  const config = loadJson(CONFIG_PATH);
  const projects = loadJson(path.join(STATE_DIR, "projects.json"));
  const issues = loadJson(path.join(STATE_DIR, "issues.json"));
  const decisions = loadJson(path.join(STATE_DIR, "decisions.json"));
  const activity = loadJson(path.join(STATE_DIR, "activity.json"));
  const spawns = loadJson(path.join(STATE_DIR, "spawns.json"));

  const archPath = path.join(FLYWHEEL_DIR, "..", "docs", "ARCHITECTURE.md");
  let archHtml = "";
  let mermaidText = "";
  if (fs.existsSync(archPath)) {
    try {
      const archContent = fs.readFileSync(archPath, "utf-8");
      const mermaidMatch = archContent.match(/```mermaid\r?\n([\s\S]*?)\r?\n```/);
      let textWithoutMermaid = archContent;
      if (mermaidMatch) {
        mermaidText = mermaidMatch[1];
        mermaidText = mermaidText.split('"../').join('"../../').split("'../").join("'../../");
        textWithoutMermaid = archContent.replace(mermaidMatch[0], "");
      }
      archHtml = mdToHtml(textWithoutMermaid);
    } catch (e) {
      console.warn(`warning: failed to parse docs/ARCHITECTURE.md: ${e.message}`);
    }
  }

  const generated = process.env.FLYWHEEL_BUILD_TS || nowToMinute();

  const blob = {
    generated,
    config: {
      project_name: config.project_name,
      autonomy: config.autonomy,
      flywheel_version: config.flywheel_version,
    },
    projects,
    issues,
    decisions,
    activity,
    spawns,
    architecture_html: archHtml,
    architecture_mermaid: mermaidText
  };
  const jsonText = JSON.stringify(blob);

  if (!fs.existsSync(TEMPLATE_PATH)) {
    console.error(`flywheel dashboard build: missing template: ${TEMPLATE_PATH}`);
    process.exit(1);
  }
  const template = fs.readFileSync(TEMPLATE_PATH, "utf-8");
  if (!template.includes(PLACEHOLDER)) {
    console.error("flywheel dashboard build: placeholder not found in template.html");
    process.exit(1);
  }
  // split/join, not .replace(): jsonText may contain "$" sequences that
  // String.prototype.replace would reinterpret as replacement patterns.
  const output = template.split(PLACEHOLDER).join(jsonText);

  fs.writeFileSync(OUTPUT_PATH, output, "utf-8");
  console.log(`wrote ${OUTPUT_PATH}`);
}

main();
