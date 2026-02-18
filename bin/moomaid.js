#!/usr/bin/env node
import { createRequire } from "node:module";
globalThis.require = createRequire(import.meta.url);
await import("./../_build/js/release/build/cmd/moomaid/moomaid.js");
