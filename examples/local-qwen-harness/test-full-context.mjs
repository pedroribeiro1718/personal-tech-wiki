#!/usr/bin/env node

const baseUrl = process.env.QWEN_FULL_URL ?? "http://127.0.0.1:30001";
const model = process.env.QWEN_FULL_MODEL ?? "qwen3.8-27b-full";
const requestedTokens = Number.parseInt(process.argv[2] ?? "250000", 10);

if (!Number.isInteger(requestedTokens) || requestedTokens < 1000 || requestedTokens > 255000) {
  console.error("Usage: test-full-context.mjs [content-tokens: 1000..255000]");
  process.exit(2);
}

const codes = {
  start: "START-8E4C1A",
  middle: "MIDDLE-37B9D2",
  end: "END-C615F0",
};

function fillerLine(index) {
  let value = (BigInt(index) * 0x9e3779b97f4a7c15n + 0x6a09e667f3bcc909n) & 0xffffffffffffffffn;
  return `Archive row ${index.toString().padStart(7, "0")}: ${value.toString(16).padStart(16, "0")} contains ordinary calibration prose.\n`;
}

function makePrompt(lineCount) {
  const split = Math.floor(lineCount / 2);
  const parts = [
    `Remember this exact start code: ${codes.start}.\n`,
  ];
  for (let i = 0; i < split; i += 1) parts.push(fillerLine(i));
  parts.push(`Remember this exact middle code: ${codes.middle}.\n`);
  for (let i = split; i < lineCount; i += 1) parts.push(fillerLine(i));
  parts.push(
    `Remember this exact end code: ${codes.end}.\n`,
    "Return the start, middle, and end codes in that order, separated by one space. Return nothing else.",
  );
  return parts.join("");
}

async function post(path, body) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${path} returned HTTP ${response.status}: ${text.slice(0, 1000)}`);
  return JSON.parse(text);
}

async function tokenCount(prompt) {
  const result = await post("/tokenize", { model, prompt, add_special_tokens: false });
  if (Number.isInteger(result.count)) return result.count;
  if (Array.isArray(result.tokens)) return result.tokens.length;
  throw new Error(`/tokenize returned no token count: ${JSON.stringify(result).slice(0, 1000)}`);
}

let lines = Math.max(100, Math.floor(requestedTokens / 14));
let prompt = "";
let count = 0;
for (let attempt = 0; attempt < 5; attempt += 1) {
  prompt = makePrompt(lines);
  count = await tokenCount(prompt);
  const error = requestedTokens - count;
  if (Math.abs(error) <= 32 || error < 0) break;
  lines = Math.max(1, Math.floor(lines * requestedTokens / count));
}
while (count > requestedTokens && lines > 1) {
  lines = Math.max(1, lines - Math.ceil((count - requestedTokens) / 10));
  prompt = makePrompt(lines);
  count = await tokenCount(prompt);
}

console.log(`Submitting ${count.toLocaleString()} content tokens to ${model} at ${baseUrl} ...`);
const started = performance.now();
const completion = await post("/v1/chat/completions", {
  model,
  messages: [{ role: "user", content: prompt }],
  max_tokens: 128,
  temperature: 0,
  chat_template_kwargs: { enable_thinking: false, preserve_thinking: false },
});
const elapsedSeconds = (performance.now() - started) / 1000;
const answer = completion.choices?.[0]?.message?.content?.trim() ?? "";
const expected = `${codes.start} ${codes.middle} ${codes.end}`;

console.log(`Prompt tokens reported by server: ${completion.usage?.prompt_tokens ?? "unknown"}`);
console.log(`Elapsed: ${elapsedSeconds.toFixed(1)} s`);
console.log(`Answer: ${answer}`);
if (answer !== expected) {
  console.error(`FAIL: expected exactly: ${expected}`);
  process.exit(1);
}
console.log("PASS: all three needles were retrieved in order.");
