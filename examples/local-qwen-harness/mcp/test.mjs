import { fileURLToPath } from "node:url";
import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

const cwd = fileURLToPath(new URL(".", import.meta.url));
const transport = new StdioClientTransport({
  command: process.execPath,
  args: ["server.mjs"],
  cwd,
  stderr: "pipe",
});

transport.stderr?.on("data", (chunk) => {
  process.stderr.write(chunk);
});

const client = new Client({
  name: "searxng-adapter-smoke-test",
  version: "1.0.0",
});

await client.connect(transport);

const tools = await client.listTools();
if (!tools.tools.some((tool) => tool.name === "web_search")) {
  throw new Error("web_search was not registered");
}
if (!tools.tools.some((tool) => tool.name === "fetch_page")) {
  throw new Error("fetch_page was not registered");
}

const result = await client.callTool({
  name: "web_search",
  arguments: {
    queries: JSON.stringify([
      "SearXNG documentation",
      "SearXNG MCP search",
    ]),
    max_results: 5,
  },
});

if (result.isError) {
  throw new Error(JSON.stringify(result.content));
}

const pageResult = await client.callTool({
  name: "fetch_page",
  arguments: {
    url: "https://example.com/",
    max_chars: 2000,
  },
});
if (pageResult.isError || !pageResult.structuredContent?.text) {
  throw new Error(`Public page snapshot failed: ${JSON.stringify(pageResult.content)}`);
}

const blockedResult = await client.callTool({
  name: "fetch_page",
  arguments: {
    url: "http://127.0.0.1/",
  },
});
if (!blockedResult.isError) {
  throw new Error("fetch_page did not reject a loopback URL");
}
if (!blockedResult.content?.[0]?.text?.includes("non-public network address")) {
  throw new Error(`Unexpected loopback rejection: ${JSON.stringify(blockedResult.content)}`);
}

console.log(
  JSON.stringify(
    {
      tools: tools.tools.map((tool) => tool.name),
      search: result.structuredContent,
      page: {
        final_url: pageResult.structuredContent.final_url,
        title: pageResult.structuredContent.title,
        text: pageResult.structuredContent.text,
      },
      blocked_page: blockedResult.content,
    },
    null,
    2
  )
);

await client.close();
