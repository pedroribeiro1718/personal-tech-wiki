# Pinned working versions

Captured on 2026-09-03 from the working RTX 5090 setup.

| Component | Pinned version |
| --- | --- |
| SGLang image | `lmsysorg/sglang:qwen38-27b@sha256:febfb971c7352570fc445c466ebd6ffc9d896024958e544a60f2137fd85856b1` |
| SGLang build | commit `c4271c3fe1262fc2adbd162c33b25de5255251c5` |
| SGLang source model | `gittensor-model-hub/Qwen3.8-27B-NVFP4-RTX5090` revision `b8ca3826548c9a7735642feb05c3c473f1fede1f` |
| DFlash draft model | `gittensor-model-hub/Qwen3.8-27B-DSpark-NVFP4` revision `eba1ac5a66c74902eaa95a4000a7c5eda96d8e95` |
| Flash Attention kernel cache | `kernels-community/sgl-flash-attn3` revision `93df65eb57c95b1dc149194bca5216a9b91568a0` |
| vLLM/EXL3 image | `voipmonitor/vllm@sha256:820181fbbc975cd5291c411cda9771d58fecee1636d916f508f47230df20592b` |
| EXL3 source model | `malaiwah/Qwen3.8-27B-EXL3-K5K6-context` revision `6362d06d351de1e3e4356a9e104682c423f23651` |
| vLLM/EXL3 runtime overlays | `malaiwah/qwen38-27b-exl3` commit `8558b8ca3bba028f852f4b53167b79b4cd552f93`; four file hashes are enforced by `local-ai` |
| NInfer source | `Neroued/ninfer` commit `a140e7ae82a11ed2f370a4d8f2cc16268a3790b8` |
| NInfer model artifact | `neroued/Qwen3.8-27B-nvfp4-NInfer` revision `204e3d92c30d9d05f3300d2f52e443ad1edf6ddf`; `qwen3_8_27b_nvfp4.ninfer`, 21,492,695,040 bytes, SHA-256 `bb3360522a06e136e0367f5703414d26272b7285c8a6ab6194135c17dbd81b32` |
| NInfer CUDA build base | `nvidia/cuda:13.1.2-devel-ubuntu24.04@sha256:952e42d23230610a2714c8484f38e9c934ed68e6f9c9c7fac62dcd5f98858a6e` |
| NInfer CUDA runtime base | `nvidia/cuda:13.1.2-runtime-ubuntu24.04@sha256:f0a6b69a753c1718da17e0d8864cd15c559960c6b68d4045c2d4d2bad0e6a87f` |
| SearXNG image | `searxng/searxng:latest@sha256:8486daaebc65adacfe434be38b991cf90da92d3fd80ae9f0ab1409ba65664e28` |
| SearXNG application | `2026.9.2-05cd77f71` |
| DeepSeek Harness | `@deepseek-ai/dsh@0.1.1-rc.2` |
| Harness MCP client | `@deepseek-ai/dsh-mcp-client@0.1.1-rc.2` |
| Harness Markdown/Mermaid renderer | `dsh-better-markdown@0.1.2` (bundles Mermaid `11.16.1`) |
| Local SearXNG MCP adapter | `1.1.0` |
| MCP SDK | `@modelcontextprotocol/sdk@2.0.0` |
| Zod | `4.5.4` |

Image and model pins are deliberate. Update them only after testing; otherwise a
fresh installation could silently behave differently from this one.
