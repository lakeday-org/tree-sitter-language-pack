import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";

const source = await readFile(new URL("../../plugin/.ai-rulez/opencode/index.js", import.meta.url), "utf8");

test("should_use_the_v2_setup_contract_and_register_bundled_content", async () => {
  assert.equal(source.includes("@opencode-ai/plugin"), false);
  const { default: plugin } = await import("../../plugin/.opencode/plugins/tree-sitter-language-pack.js");
  const output = { tools: [], skills: [], mcp: {} };
  await plugin.setup({
    tool: { transform: (fn) => fn({ add: (tool) => output.tools.push(tool) }) },
    skill: { transform: (fn) => fn({ get: () => undefined, add: (skill) => output.skills.push(skill) }) },
    command: { transform: (fn) => fn({ add: () => {} }) },
    agent: { transform: (fn) => fn({ update: () => {} }) },
    mcp: {
      transform: (fn) =>
        fn({
          set: (name, config) => {
            output.mcp[name] = config;
          },
        }),
    },
  });
  assert.equal(output.tools.length, 3);
  assert.equal(output.skills.length, 7);
  assert.deepEqual(Object.keys(output.mcp), ["tree-sitter-language-pack"]);
});
