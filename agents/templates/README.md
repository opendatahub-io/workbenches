# AGENTS File Template Guide

This document describes the structural patterns and conventions used across the `AGENTS.md` and `AGENTS-PATTERNS.md` files in this repository. Use it as a blueprint when creating new agent guidelines for additional modules.

---

## Architecture Overview

The agent guidelines follow a **hierarchical, two-file-per-module** architecture:

```
Root (Global)
├── AGENTS.md                    # Global policies — always applies
│
├── module-a/
│   ├── AGENTS.md                # Module guidelines — extends global
│   └── AGENTS-PATTERNS.md       # Module patterns — detailed code examples
│
├── module-b/
│   ├── AGENTS.md
│   └── AGENTS-PATTERNS.md
│
└── module-b/sub-module/
    ├── AGENTS.md                # Sub-module guidelines — extends parent + global
    └── AGENTS-PATTERNS.md
```

### Design Principles

| Principle | Description |
| --------- | ----------- |
| **Hierarchical** | Global rules are inherited; local rules can only add restrictions, never weaken them |
| **Two-file split** | `AGENTS.md` = rules, boundaries, quick commands; `AGENTS-PATTERNS.md` = code examples, templates |
| **Self-contained** | Each file has a Table of Contents and can be read independently |
| **Cross-linked** | Files link to each other; agents are required to follow links and read referenced files |
| **RFC 2119 severity** | MUST/MUST NOT (blocking), SHOULD/SHOULD NOT (recommended), MAY (optional) |
| **DRY via delegation** | Common rules live in the global file; module files reference them instead of duplicating |

---

## File Naming Conventions

| File | Purpose | Scope |
| ---- | ------- | ----- |
| `AGENTS.md` | Essential rules, commands, and boundaries | One per module/directory |
| `AGENTS-PATTERNS.md` | Detailed code examples, templates, and best practices | One per module (alongside its AGENTS.md) |
| `CLAUDE.md` | Symlink to root `AGENTS.md` for Claude Code compatibility | Root only |

---

## Templates

The following template files are available:

| Template | Purpose |
| -------- | ------- |
| [agents-global.md](./agents-global.md) | Root-level `AGENTS.md` defining universal policies for the entire repository |
| [agents-module.md](./agents-module.md) | Module-level `AGENTS.md` extending the global file with module-specific rules |
| [agents-module-patterns.md](./agents-module-patterns.md) | Module-level `AGENTS-PATTERNS.md` with detailed code examples and templates |

---

## Cross-Cutting Patterns

These patterns appear consistently across all files:

### 1. Frontmatter

Every file starts with YAML frontmatter:

```yaml
---
name: <Descriptive Name>
description: <One-line purpose statement>
---
```

### 2. Persona Block

Every AGENTS.md begins with a persona that tells the agent **who it is**:

```markdown
## Persona

- You specialize in <domain expertise>
- You understand <technical patterns>
- Your output: <quality description>
```

### 3. RFC 2119 Severity

All files use consistent severity keywords:

- **MUST / MUST NOT** — Blocking. No exceptions.
- **SHOULD / SHOULD NOT** — Strong recommendation. Exceptions require justification.
- **MAY** — Optional. Use judgment.

### 4. DO/DON'T Pattern

Code examples consistently use visual indicators:

```markdown
✅ **DO**: <Good practice>
❌ **DON'T**: <Anti-pattern>
```

### 5. Quick Commands at Top

Module files place the most common commands immediately after the persona, before the Table of Contents, so agents see them first.

### 6. Tables for Structured Information

Consistent use of tables for:

- **Key entry points** — "To find... → See..."
- **Reference examples** — "Pattern → Copy from..."
- **Common pitfalls** — "Category → Key Rule → See Patterns"
- **Critical rules** — "Rule → Severity"
- **Key files** — "Purpose → Location"
- **Troubleshooting** — "Issue → Cause → Solution"

### 7. Delegation via Links

Rules and patterns are never duplicated. Instead, files link to:

- The **global AGENTS.md** for shared rules (e.g., Code Cleanliness, Rule Severity)
- The **companion AGENTS-PATTERNS.md** for code examples
- **Other module AGENTS.md files** for out-of-scope responsibilities

### 8. Decision Trees

The global file includes ASCII decision trees for common agent decisions:

- "Can I Make This Change?"
- "When to Escalate to Human?"

### 9. Pre-Task Checklists

Every module AGENTS.md ends with a checklist the agent should verify before starting work.

### 10. Invariants Section

Each module declares its architectural invariants — the non-negotiable truths about that module (e.g., "Frontend consumes backend API only — no direct Kubernetes calls").

---

## When to Split AGENTS-PATTERNS.md

If a patterns file exceeds ~500-600 lines, consider splitting into focused files:

```
module/
├── AGENTS.md
├── AGENTS-PATTERNS.md            # Could split into:
├── PATTERNS-components.md        # UI patterns, context, hooks
├── PATTERNS-testing.md           # Test framework patterns
└── PATTERNS-data.md              # State management, API, errors
```

When splitting, update all cross-references and the module's `AGENTS.md` to link to the new files.
