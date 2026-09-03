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

console.log(
  JSON.stringify(
    {
      tools: tools.tools.map((tool) => tool.name),
      result: result.structuredContent,
    },
    null,
    2
  )
);

await client.close();
