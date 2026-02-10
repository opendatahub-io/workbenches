---
name: <Module Name> Agent
description: Guidelines for AI agents working on the <module description>.
---

# <Module Name> Module - Agent Guidelines

You are an expert <domain> engineer for <Project Name>.

This file extends the global [AGENTS.md](../../AGENTS.md) with <module>-specific guidance.

## Persona

- You specialize in <module-specific expertise>
- You understand <module-specific patterns and frameworks>
- Your output: <description of expected output quality>

> **Note:** This document uses [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119)
> keywords (MUST, SHOULD, MAY). See [Rule Severity](../../AGENTS.md#rule-severity)
> for definitions.

## Quick Commands

```bash
# Most common development commands for this module
<command1>    # Description
<command2>    # Description
<command3>    # Description
```

## Table of Contents

- [Scope of Responsibility](#scope-of-responsibility)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Generated Code](#generated-code)
- [Development Commands](#development-commands)
- [Code Conventions](#code-conventions)
- [Common Pitfalls Summary](#common-pitfalls-summary)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)
- [Out of Scope](#out-of-scope)
- [Quick Reference](#quick-reference)

**For detailed patterns and examples, see [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md).**

---

## Scope of Responsibility

Agents may:

- <Permitted module actions>

Agents **MUST NOT**:

- <Prohibited module actions>

### <Module> Invariants

- <Key architectural invariants for this module>

---

## Technology Stack

- **Language**: <language and version>
- **Framework**: <framework and version>
- **Testing**: <test framework>

---

## Project Structure

```
module/
├── dir-a/              # Description
├── dir-b/              # Description
└── dir-c/              # Description
```

**Key entry points:**

| To find...     | See...              |
| -------------- | ------------------- |
| Main entry     | `path/to/entry`     |
| Config         | `path/to/config`    |
| Key component  | `path/to/component` |

**Reference examples (copy these patterns):**

| Pattern        | Copy from...        |
| -------------- | ------------------- |
| Common pattern | `path/to/example`   |
| Another        | `path/to/example2`  |

---

## Generated Code

**Never manually modify:**

- `path/to/generated/` — Description of what is generated

To regenerate:

```bash
<regeneration command>
```

---

## Development Commands

See [Quick Commands](#quick-commands) at the top of this file for common commands.

**Additional options:**

```bash
<additional useful commands>
```

---

## Code Conventions

- <Module-specific conventions>
- <Naming, structure, and style rules>

### <Critical Convention Name> (CRITICAL)

<Description of the most important convention for this module>

> **See [AGENTS-PATTERNS.md - <Section>](./AGENTS-PATTERNS.md#section-anchor)**
> for examples.

### Code Cleanliness

> **See [Global AGENTS.md - Code Cleanliness](../../AGENTS.md#code-cleanliness)**
> for the full rules on TODOs, FIXMEs, and skipped tests.

---

## Common Pitfalls Summary

| Category       | Key Rule                            | See Patterns                                                |
| -------------- | ----------------------------------- | ----------------------------------------------------------- |
| **Category 1** | Brief rule description              | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#section-anchor)  |
| **Category 2** | Brief rule description              | [AGENTS-PATTERNS.md](./AGENTS-PATTERNS.md#section-anchor)  |

---

## Common Tasks

### Task 1: <e.g., Adding a new feature unit>

1. Step one
2. Step two
3. Step three

### Task 2: <e.g., Adding a new test>

1. Step one
2. Step two

---

## Troubleshooting

### Common Issues

| Issue               | Cause              | Solution                |
| ------------------- | ------------------ | ----------------------- |
| **Problem**         | Root cause         | How to fix              |
| **Another problem** | Root cause         | How to fix              |

### Debugging Tips

```bash
# Useful debugging commands
<command>
```

---

## Out of Scope

The following are handled by other modules and **MUST NOT** be modified in
<module> changes:

- <Responsibility> (belongs to [other module](../other/AGENTS.md))
- <Responsibility> (belongs to [other module](../other/AGENTS.md#section))

---

## Quick Reference

### Critical Rules

| Rule                               | Severity   |
| ---------------------------------- | ---------- |
| Never <prohibited action>          | MUST NOT   |
| Always <required action>           | MUST       |
| Prefer <recommended action>        | SHOULD     |

### Key Files

| Purpose      | Location          |
| ------------ | ----------------- |
| Main code    | `path/to/code`    |
| Tests        | `path/to/tests`   |
| Config       | `path/to/config`  |

### <Primary Pattern> Template

> **See [AGENTS-PATTERNS.md - <Template Name>](./AGENTS-PATTERNS.md#template-anchor)**
> for the full template.

### Pre-Task Checklist

- [ ] Read existing patterns in `path/to/code`
- [ ] Check if change requires human approval
- [ ] Verify generated files are up to date
- [ ] Plan for required tests
- [ ] Run relevant linters/checks
