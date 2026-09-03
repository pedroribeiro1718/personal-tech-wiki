# Pinned working versions

Captured on 2026-09-03 from the working RTX 5090 setup.

| Component | Pinned version |
| --- | --- |
| SGLang image | `lmsysorg/sglang:qwen38-27b@sha256:febfb971c7352570fc445c466ebd6ffc9d896024958e544a60f2137fd85856b1` |
| SGLang build | commit `c4271c3fe1262fc2adbd162c33b25de5255251c5` |
| Main model | `gittensor-model-hub/Qwen3.8-27B-NVFP4-RTX5090` revision `b8ca3826548c9a7735642feb05c3c473f1fede1f` |
| DFlash draft model | `gittensor-model-hub/Qwen3.8-27B-DSpark-NVFP4` revision `eba1ac5a66c74902eaa95a4000a7c5eda96d8e95` |
| Flash Attention kernel cache | `kernels-community/sgl-flash-attn3` revision `93df65eb57c95b1dc149194bca5216a9b91568a0` |
| SearXNG image | `searxng/searxng:latest@sha256:8486daaebc65adacfe434be38b991cf90da92d3fd80ae9f0ab1409ba65664e28` |
| SearXNG application | `2026.9.2-05cd77f71` |
| DeepSeek Harness | `@deepseek-ai/dsh@0.1.1-rc.2` |
| Harness MCP client | `@deepseek-ai/dsh-mcp-client@0.1.1-rc.2` |
| MCP SDK | `@modelcontextprotocol/sdk@2.0.0` |
| Zod | `4.5.4` |

Image and model pins are deliberate. Update them only after testing; otherwise a
fresh installation could silently behave differently from this one.
