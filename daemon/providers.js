// daemon/providers.js
"use strict";
// ---------------------------------------------------------------------------
// Per-agent model/provider routing — the office's "swappable brain".
//
// The agent runtime is Codex CLI (`codex exec --json`): it owns the agentic loop,
// tools, sessions, and project work. Older provider entries are retained as
// UI/registry metadata for existing installs, but Codex is the default engine.
//
//   • Anthropic-format providers (direct: true)  → ANTHROPIC_BASE_URL straight at
//     their Anthropic-compatible endpoint. No proxy.
//   • OpenAI-format providers   (needsProxy: true) → ANTHROPIC_BASE_URL at a local
//     LiteLLM gateway that translates Anthropic <-> OpenAI (wired in P3).
//
// FAIL-OPEN: an unconfigured, unknown, or "codex" provider returns empty
// overrides, so the spawn remains a plain Codex CLI run.
// ---------------------------------------------------------------------------

// Catalog. `baseUrl` filled only where the endpoint is confirmed; the rest are
// supplied via reg.providerConfig[id].baseUrl (verified per-provider in P2).
// `models` is a hint list for the settings UI — any string is accepted.
const PROVIDERS = {
  codex: {
    label: "Codex CLI", format: "codex", direct: true, baseUrl: null,
    models: ["", "gpt-5", "gpt-5-codex", "o4-mini"],
  },
  claude: {
    label: "Claude · Anthropic", format: "anthropic", direct: true, baseUrl: null,
    models: ["", "opus", "sonnet", "haiku",
             "claude-opus-4-8", "claude-sonnet-4-6", "claude-haiku-4-5"],
  },
  glm: {
    label: "GLM · Z.AI", format: "anthropic", direct: true,
    baseUrl: "https://api.z.ai/api/anthropic",          // confirmed (Z.AI docs)
    models: ["glm-4.6", "glm-4.5"],
  },
  deepseek: {
    label: "DeepSeek", format: "anthropic", direct: true,
    baseUrl: "https://api.deepseek.com/anthropic",        // confirmed (DeepSeek docs)
    models: ["deepseek-v4-pro", "deepseek-v4-flash"],     // chat/reasoner deprecated 2026-07-24
  },
  qwen: {
    label: "Qwen · Alibaba", format: "anthropic", direct: true,
    // confirmed (Alibaba Model Studio docs). International endpoint; mainland-China
    // is https://dashscope.aliyuncs.com/apps/anthropic — set reg.providerConfig.qwen.baseUrl.
    baseUrl: "https://dashscope-intl.aliyuncs.com/apps/anthropic",
    models: ["qwen3-coder-plus", "qwen3-coder-next", "qwen3-coder-flash"],
  },
  minimax: {
    label: "MiniMax", format: "anthropic", direct: true,
    // confirmed (MiniMax docs). International endpoint; mainland-China is
    // https://api.minimaxi.com/anthropic (extra "i") — set reg.providerConfig.minimax.baseUrl.
    baseUrl: "https://api.minimax.io/anthropic",
    models: ["MiniMax-M3"],
  },
  openai: {
    label: "OpenAI", format: "openai", needsProxy: true, baseUrl: null,
    models: ["gpt-4o", "gpt-4o-mini"],
  },
  gemini: {
    label: "Gemini", format: "openai", needsProxy: true, baseUrl: null,
    models: ["gemini-2.5-flash", "gemini-2.5-pro"],
  },
  openrouter: {
    label: "OpenRouter", format: "openai", needsProxy: true, baseUrl: null,
    models: ["openai/gpt-4o", "anthropic/claude-sonnet-4-6", "deepseek/deepseek-chat"],
  },
  nvidia: {
    label: "NVIDIA build", format: "openai", needsProxy: true, baseUrl: null,
    models: ["meta/llama-3.3-70b-instruct", "deepseek-ai/deepseek-v3"],
  },
};

const DEFAULT_LITELLM = "http://127.0.0.1:4000";

// resolve(provider, model, reg) -> { ok, env, modelArgs, reason }
//   env       : object spread into the child's env
//   modelArgs : [] or ["-m", "<id>"] translated by the Codex adapter
//   reg.providerConfig = {
//     glm:      { token, baseUrl?, model? },
//     deepseek: { token, baseUrl?, model? },
//     litellm:  { baseUrl?, token? },          // for openai/gemini
//     ...
//   }
function resolve(provider, model, reg = {}, opts = {}) {
  const out = { ok: true, env: {}, modelArgs: [], reason: "codex-default" };
  const pConf = (reg && reg.providerConfig) || {};

  // Default brain: plain Codex. Optional explicit model only.
  if (!provider || provider === "codex") {
    if (model) out.modelArgs = ["-m", String(model)];
    return out;
  }

  const spec = PROVIDERS[provider];
  const pc = pConf[provider] || {};
  // "anthropic" (claude talks straight to the endpoint) or "openai" (via the
  // built-in proxy). Built-ins read it from the catalog; CUSTOM providers store
  // their kind/baseUrl/token in providerConfig[id].
  const kind = spec ? spec.format : pc.kind;
  if (!kind) return { ok: false, env: {}, modelArgs: [], reason: "unknown-provider" };

  let baseUrl, token;
  if (kind === "openai") {
    // Needs translation. openai/gemini may use an explicit LiteLLM gateway; everyone
    // else (openrouter/nvidia/custom) uses the daemon's built-in proxy, which resolves
    // the real upstream + key from providerConfig (proxy.js → upstreamFor).
    const builtinPair = provider === "openai" || provider === "gemini";
    const lc = pConf.litellm;
    const liteUrl = builtinPair && ((lc && lc.baseUrl) || reg.litellmUrl);
    if (liteUrl) {
      baseUrl = liteUrl;
      token = (lc && lc.token) || pc.token || "litellm";
    } else if (opts.proxyBase) {
      const mainKey = provider === "openai" ? (reg.apiKeys || {}).OPENAI_API_KEY
                    : provider === "gemini" ? (reg.apiKeys || {}).GEMINI_API_KEY : null;
      if (!pc.token && !mainKey) {
        return { ok: false, env: {}, modelArgs: [], reason: "key-not-set" };
      }
      baseUrl = `${opts.proxyBase}/proxy/${provider}`;
      token = "office";   // the proxy injects the real key; this value is ignored
    } else {
      return { ok: false, env: {}, modelArgs: [], reason: "no-proxy-available" };
    }
  } else {
    // anthropic-kind: direct.
    baseUrl = pc.baseUrl || (spec && spec.baseUrl);
    token = pc.token;
    if (!baseUrl || !token) {
      return { ok: false, env: {}, modelArgs: [], reason: "not-configured" };
    }
  }

  out.env = { ANTHROPIC_BASE_URL: baseUrl, ANTHROPIC_AUTH_TOKEN: token };
  let m = pc.model || model;
  if (!m && kind === "openai") {
    m = provider === "openai" ? "gpt-4o-mini" : provider === "gemini" ? "gemini-2.5-flash" : "";
  }
  if (m) out.modelArgs = ["--model", String(m)];
  out.reason = provider;
  return out;
}

module.exports = { PROVIDERS, DEFAULT_LITELLM, resolve };
