#!/usr/bin/env node

import { chromium } from "@playwright/test";
import { createHash } from "node:crypto";
import { createReadStream } from "node:fs";
import { promises as fs } from "node:fs";
import http from "node:http";
import path from "node:path";

const VIEWPORT = { width: 932, height: 430 };
const EXPECTED_CAPTURE_COUNT = 121;
const SUITE_ARG = "--visual-capture-suite";
const MARKER_PREFIX = "EVER_DEEPER_VISUAL_CAPTURE_";
const NEXT_MARKER_TIMEOUT_MS = 60 * 1000;
const DEFAULT_TIMEOUT_MS = NEXT_MARKER_TIMEOUT_MS;

const MIME_TYPES = new Map([
  [".html", "text/html; charset=utf-8"],
  [".js", "application/javascript; charset=utf-8"],
  [".mjs", "application/javascript; charset=utf-8"],
  [".wasm", "application/wasm"],
  [".pck", "application/octet-stream"],
  [".png", "image/png"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".svg", "image/svg+xml"],
]);

function parseArguments(argv) {
  const options = {
    webDir: "",
    outputDir: "",
    timeoutMs: DEFAULT_TIMEOUT_MS,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    const [name, inlineValue] = token.split("=", 2);
    const readValue = () => {
      if (inlineValue !== undefined) return inlineValue;
      index += 1;
      if (index >= argv.length) throw new Error(`Missing value for ${name}`);
      return argv[index];
    };
    if (name === "--web-dir") options.webDir = readValue();
    else if (name === "--output-dir") options.outputDir = readValue();
    else if (name === "--timeout-ms") options.timeoutMs = Number(readValue());
    else if (name === "--help" || name === "-h") options.help = true;
    else throw new Error(`Unknown argument: ${token}`);
  }
  return options;
}

function usage() {
  return [
    "Usage:",
    "  node tools/visual-qa/capture-web-visuals.mjs \\",
    "    --web-dir /absolute/path/to/final-web-dev-build \\",
    "    --output-dir /absolute/path/to/visual-captures",
  ].join("\n");
}

async function ensureInputs(options) {
  if (!options.webDir || !options.outputDir) throw new Error(usage());
  if (!Number.isFinite(options.timeoutMs) || options.timeoutMs <= 0) {
    throw new Error("--timeout-ms must be a positive number");
  }
  options.webDir = path.resolve(options.webDir);
  options.outputDir = path.resolve(options.outputDir);
  for (const filename of ["index.html", "index.pck", "index.js", "index.wasm"]) {
    const target = path.join(options.webDir, filename);
    const stat = await fs.stat(target).catch(() => null);
    if (!stat?.isFile()) throw new Error(`Final web build is missing ${target}`);
  }
  await fs.mkdir(options.outputDir, { recursive: true });
  const existing = await fs.readdir(options.outputDir);
  const stale = existing.filter((name) => name.endsWith(".png") || name === "manifest.json");
  if (stale.length > 0) {
    throw new Error(`Output directory must not contain stale captures: ${stale.join(", ")}`);
  }
}

async function sha256(filename) {
  const hash = createHash("sha256");
  const data = await fs.readFile(filename);
  hash.update(data);
  return hash.digest("hex");
}

function injectSuiteArgument(html) {
  const pattern = /const GODOT_CONFIG = (\{[^\r\n]+\});/;
  const match = html.match(pattern);
  if (!match) throw new Error("Could not find GODOT_CONFIG in final index.html");
  const config = JSON.parse(match[1]);
  const existingArgs = Array.isArray(config.args) ? config.args : [];
  const suiteArgs = existingArgs.filter((arg) => arg !== SUITE_ARG);
  // OS.get_cmdline_user_args() only exposes arguments after Godot's user separator.
  if (!suiteArgs.includes("--")) suiteArgs.push("--");
  config.args = [...suiteArgs, SUITE_ARG];
  return html.replace(pattern, `const GODOT_CONFIG = ${JSON.stringify(config)};`);
}

async function createStaticServer(webDir) {
  const root = path.resolve(webDir);
  const server = http.createServer(async (request, response) => {
    try {
      const requestUrl = new URL(request.url ?? "/", "http://127.0.0.1");
      const pathname = requestUrl.pathname === "/" ? "/index.html" : decodeURIComponent(requestUrl.pathname);
      const filename = path.resolve(root, `.${pathname}`);
      if (filename !== root && !filename.startsWith(`${root}${path.sep}`)) {
        response.writeHead(403).end("Forbidden");
        return;
      }
      const stat = await fs.stat(filename).catch(() => null);
      if (!stat?.isFile()) {
        response.writeHead(404).end("Not found");
        return;
      }
      const headers = {
        "Cache-Control": "no-store",
        "Content-Length": stat.size,
        "Content-Type": MIME_TYPES.get(path.extname(filename).toLowerCase()) ?? "application/octet-stream",
        "Cross-Origin-Embedder-Policy": "require-corp",
        "Cross-Origin-Opener-Policy": "same-origin",
        "Cross-Origin-Resource-Policy": "same-origin",
      };
      response.writeHead(200, headers);
      if (request.method === "HEAD") {
        response.end();
        return;
      }
      createReadStream(filename).pipe(response);
    } catch (error) {
      response.writeHead(500).end(String(error));
    }
  });
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("Static server did not bind a TCP port");
  return {
    server,
    url: `http://127.0.0.1:${address.port}/index.html`,
  };
}

async function closeServer(server) {
  if (!server) return;
  await new Promise((resolve) => server.close(resolve));
}

async function probeWebGL2(context) {
  const probe = await context.newPage();
  try {
    await probe.goto("about:blank");
    const details = await probe.evaluate(() => {
      const canvas = document.createElement("canvas");
      const gl = canvas.getContext("webgl2", {
        antialias: true,
        depth: true,
        stencil: true,
      });
      if (!gl) return null;
      const extension = gl.getExtension("WEBGL_debug_renderer_info");
      return {
        renderer: extension ? gl.getParameter(extension.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER),
        vendor: extension ? gl.getParameter(extension.UNMASKED_VENDOR_WEBGL) : gl.getParameter(gl.VENDOR),
        version: gl.getParameter(gl.VERSION),
      };
    });
    if (!details) throw new Error("Chromium did not provide WebGL2");
    if (!/swiftshader/i.test(`${details.vendor} ${details.renderer}`)) {
      throw new Error(`Capture renderer is not SwiftShader: ${details.vendor} / ${details.renderer}`);
    }
    return details;
  } finally {
    await probe.close();
  }
}

function pngDimensions(buffer) {
  const signature = "89504e470d0a1a0a";
  if (buffer.length < 24 || buffer.subarray(0, 8).toString("hex") !== signature) {
    throw new Error("Screenshot is not a valid PNG");
  }
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20),
  };
}

async function nextMarker(queue, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (queue.length > 0) return queue.shift();
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
  throw new Error(`Timed out waiting ${timeoutMs} ms for the next capture marker`);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function contactSheet(captures, metadata) {
  const cards = captures
    .map(
      (capture) => `
      <figure>
        <img src="${escapeHtml(capture.file)}" width="932" height="430" loading="lazy">
        <figcaption>${String(capture.index).padStart(3, "0")} · ${escapeHtml(capture.state)}</figcaption>
      </figure>`,
    )
    .join("\n");
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Ever Deeper visual capture suite</title>
<style>
  :root { color-scheme: dark; font-family: system-ui, sans-serif; }
  body { margin: 20px; background: #090a09; color: #f2e4c7; }
  header { position: sticky; top: 0; z-index: 2; padding: 12px 16px; background: #111d; backdrop-filter: blur(8px); }
  main { display: grid; grid-template-columns: repeat(auto-fit, minmax(460px, 1fr)); gap: 18px; }
  figure { margin: 0; padding: 9px; border: 1px solid #6f5a32; background: #111; }
  img { display: block; width: 100%; height: auto; aspect-ratio: 932 / 430; object-fit: contain; background: #000; }
  figcaption { padding: 8px 3px 2px; font: 600 13px/1.3 ui-monospace, monospace; }
</style></head><body>
<header><strong>${captures.length} final-build captures · 932×430 · SwiftShader WebGL2</strong><br>
<small>PCK sha256 ${escapeHtml(metadata.pckSha256)}</small></header>
<main>${cards}</main></body></html>`;
}

async function captureSuite(options) {
  const pckSha256 = await sha256(path.join(options.webDir, "index.pck"));
  const htmlSha256 = await sha256(path.join(options.webDir, "index.html"));
  const { server, url } = await createStaticServer(options.webDir);
  let browser;
  try {
    browser = await chromium.launch({
      headless: true,
      args: [
        "--enable-unsafe-swiftshader",
        "--enable-webgl",
        "--ignore-gpu-blocklist",
        "--use-angle=swiftshader",
        "--use-gl=angle",
      ],
    });
    const context = await browser.newContext({
      viewport: VIEWPORT,
      screen: VIEWPORT,
      deviceScaleFactor: 1,
      hasTouch: true,
      isMobile: true,
      colorScheme: "dark",
      locale: "en-US",
      userAgent:
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 " +
        "(KHTML, like Gecko) CriOS/124.0.0.0 Mobile/15E148 Safari/604.1",
    });
    const webgl = await probeWebGL2(context);
    const page = await context.newPage();
    page.setDefaultTimeout(NEXT_MARKER_TIMEOUT_MS);
    const markerQueue = [];
    const pageErrors = [];
    const requestFailures = [];
    page.on("console", (message) => {
      const text = message.text();
      if (text.includes(MARKER_PREFIX)) markerQueue.push(text.slice(text.indexOf(MARKER_PREFIX)));
    });
    page.on("pageerror", (error) => pageErrors.push(String(error)));
    page.on("requestfailed", (request) => {
      requestFailures.push(`${request.method()} ${request.url()} · ${request.failure()?.errorText ?? "unknown"}`);
    });
    await page.route("**/index.html", async (route) => {
      const response = await route.fetch();
      const originalHtml = await response.text();
      await route.fulfill({ response, body: injectSuiteArgument(originalHtml) });
    });
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: NEXT_MARKER_TIMEOUT_MS });

    const captures = [];
    const seenStates = new Set();
    let began = false;
    let completed = false;
    while (!completed) {
      // The complete matrix is deliberately exhaustive and can take longer on
      // SwiftShader runners. Fail on a stalled state, not on healthy progress.
      const marker = await nextMarker(markerQueue, Math.min(NEXT_MARKER_TIMEOUT_MS, options.timeoutMs));
      process.stdout.write(`${marker}\n`);
      if (marker.startsWith(`${MARKER_PREFIX}FAILED`)) throw new Error(marker);
      if (marker.startsWith(`${MARKER_PREFIX}BEGIN`)) {
        const match = marker.match(/count=(\d+) viewport=(\d+)x(\d+)/);
        if (!match) throw new Error(`Malformed BEGIN marker: ${marker}`);
        const [, count, width, height] = match.map(Number);
        if (count !== EXPECTED_CAPTURE_COUNT || width !== VIEWPORT.width || height !== VIEWPORT.height) {
          throw new Error(`Unexpected capture contract: ${marker}`);
        }
        began = true;
        continue;
      }
      if (marker.startsWith(`${MARKER_PREFIX}READY`)) {
        if (!began) throw new Error("READY marker arrived before BEGIN");
        const match = marker.match(/state=([a-z0-9_]+) index=(\d+) total=(\d+)/);
        if (!match) throw new Error(`Malformed READY marker: ${marker}`);
        const state = match[1];
        const index = Number(match[2]);
        const total = Number(match[3]);
        if (total !== EXPECTED_CAPTURE_COUNT || index !== captures.length + 1) {
          throw new Error(`Out-of-order capture marker: ${marker}`);
        }
        if (seenStates.has(state)) throw new Error(`Duplicate capture state: ${state}`);
        seenStates.add(state);
        await page.locator("#canvas").waitFor({ state: "visible" });
        await page.evaluate(
          () => new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve))),
        );
        const file = `${String(index).padStart(3, "0")}_${state}.png`;
        const filename = path.join(options.outputDir, file);
        await page.screenshot({ path: filename, animations: "disabled" });
        const image = await fs.readFile(filename);
        const dimensions = pngDimensions(image);
        if (dimensions.width !== VIEWPORT.width || dimensions.height !== VIEWPORT.height) {
          throw new Error(`Wrong PNG dimensions for ${file}: ${dimensions.width}x${dimensions.height}`);
        }
        captures.push({ index, state, file, sha256: await sha256(filename) });
        await page.locator("#canvas").focus();
        await page.keyboard.press("Enter");
        continue;
      }
      if (marker.startsWith(`${MARKER_PREFIX}COMPLETE`)) {
        const match = marker.match(/count=(\d+)/);
        if (!match || Number(match[1]) !== EXPECTED_CAPTURE_COUNT) {
          throw new Error(`Malformed COMPLETE marker: ${marker}`);
        }
        completed = true;
      }
    }
    if (captures.length !== EXPECTED_CAPTURE_COUNT) {
      throw new Error(`Captured ${captures.length}, expected ${EXPECTED_CAPTURE_COUNT}`);
    }
    if (pageErrors.length > 0) throw new Error(`Page errors:\n${pageErrors.join("\n")}`);
    if (requestFailures.length > 0) {
      throw new Error(`Failed build requests:\n${requestFailures.join("\n")}`);
    }
    const metadata = {
      generatedAt: new Date().toISOString(),
      viewport: VIEWPORT,
      captureCount: captures.length,
      pckSha256,
      htmlSha256,
      browserVersion: browser.version(),
      webgl,
      suiteArgument: SUITE_ARG,
      captures,
    };
    await fs.writeFile(
      path.join(options.outputDir, "manifest.json"),
      `${JSON.stringify(metadata, null, 2)}\n`,
    );
    await fs.writeFile(
      path.join(options.outputDir, "contact-sheet.html"),
      contactSheet(captures, metadata),
    );
    process.stdout.write(
      `Captured ${captures.length} final-build states at ${VIEWPORT.width}x${VIEWPORT.height}.\n` +
        `PCK sha256: ${pckSha256}\nOutput: ${options.outputDir}\n`,
    );
  } finally {
    if (browser) await browser.close();
    await closeServer(server);
  }
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  if (options.help) {
    process.stdout.write(`${usage()}\n`);
    return;
  }
  await ensureInputs(options);
  await captureSuite(options);
}

main().catch((error) => {
  process.stderr.write(`${error instanceof Error ? error.stack : String(error)}\n`);
  process.exitCode = 1;
});
