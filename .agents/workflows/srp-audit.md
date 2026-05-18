---
description: Structured workflow to analyze directory structures, define exclusive non-overlapping responsibilities, and perform a file-by-file SRP compliance audit.
---

# Workflow: /srp-audit

This workflow provides instructions for the agent to systematically audit a target directory (usually `lib/`) for Single-Responsibility Principle (SRP) compliance. It is executed in two core phases: first mapping exclusive, non-overlapping directory responsibilities, and then auditing individual files to ensure their internal code content matches their directory's assigned responsibility.

## Core Mandates

When executing this workflow, adhere to the following strict principles:
1. **Zero-Overlap Isolation**: Every directory and layer must have a single, exclusive, and unambiguous job. Identify any shared concerns or architectural leaks.
2. **Exclusion Validation**: For every directory mapped, you must explicitly state what that layer does *not* do. This acts as a logical barrier to prevent future scope creep.
3. **Evidence-Based Line Audits**: When auditing files, you must inspect exact line numbers and code structures to prove compliance. Never assume compliance.
4. **Clickable References**: All directories, files, and line ranges mentioned in the reports must use fully qualified markdown file links (using `file://` URIs) so they are clickable and navigable in the IDE.

---

## Execution Steps

### Step 1: Directory Tree Ingestion & SRP Mapping
- **Task**: Discover the folder structure of the target directory and map exclusive layer responsibilities.
- **Action**:
  - Run a recursive directory search or tree analysis to identify all subdirectories and key structural layers.
  - Group related directories into logical semantic architectural layers (e.g., Root Entrypoint, Domain State, Business Logic, Presentation, Infrastructure, Generated FFI).
  - For each architectural layer and subdirectory, determine its **single non-overlapping responsibility**.
  - Document the high-level layer hierarchy using one or more Mermaid `graph TD` diagrams to visually demonstrate the control flow and boundaries.

### Step 2: Draft the Exclusive Responsibilities Report (Part 1)
- **Task**: Produce the first half of the report detailing the directory responsibilities.
- **Format Requirements**:
  - **Header**: `# [Project Name] [target_dir] Exclusive Directory Responsibilities`
  - **Introductory Statement**: Briefly state that the directory structure is built on a strict Single-Responsibility Principle (SRP) where every folder has a single, exclusive job with no overlapping concerns.
  - **Visual Hierarchy Diagram**: Render your Mermaid graphs showing layer flow.
  - **Layer Breakdown Section (`## 📂 Exclusive Layer Responsibilities`)**:
    - For each identified layer/directory, create a numbered section with a clickable absolute file link to that folder.
    - Define an **Exclusive Responsibility** block detailing the folder's core job.
    - Provide bullet points of representative file paths (clickable) and their specific roles.
    - Create a distinct **Exclusion** section detailing exactly what concern is **not** handled by this layer (e.g., what it does not paint, store, or process).

### Step 3: Surgical File-Level SRP Code Audit
- **Task**: Inspect specific code content in key files to verify their alignment with directory boundaries.
- **Action**:
  - Select a representative set of files (e.g., widgets, state stores, interaction controllers, mathematical utilities) across the mapped directories.
  - For each selected file, read and inspect its actual source code (identifying specific line ranges, methods, and patterns).
  - Investigate the following critical boundary questions:
    - Does the UI layer contain any business logic, data mutations, coordinate math, or database calls?
    - Does the interaction/gesture engine contain painting logic or state stores?
    - Does the data store contain user interface painting or raw viewport positioning?
    - Does the presentation models layer contain generated FFI boilerplate or rendering routines?

### Step 4: Draft the Surgical SRP Audit Report (Part 2)
- **Task**: Produce the second half of the report presenting the audit findings.
- **Format Requirements**:
  - **Header**: `## 🔍 Surgical SRP Audit Report`
  - **Audited Files Breakdown Section (`### 📋 Audit Findings by Directory`)**:
    - Group or list the inspected files numerically.
    - For each file, include a sub-heading with a clickable file link.
    - Define its **Role** (what the file does within the layer).
    - Create an **Inspection Results** list detailing specific lines of code (with clickable line ranges like `#L45-L53`) that demonstrate boundary compliance or violation.
    - Conclude the file audit card with an **SRP Assessment** block using clear compliance status tags (e.g., `**PERFECT COMPLIANCE**` or `**VIOLATION DETECTED**`) along with a professional architectural justification.
  - **Conclusion Section (`### 🛡️ Conclusion of the Audit`)**:
    - Provide a definitive summary of the overall codebase health based on the audit.
    - Highlight any architectural leaks that were discovered and suggest actionable refactoring recommendations.
