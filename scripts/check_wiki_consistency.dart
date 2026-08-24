// ignore_for_file: avoid_print

// ──────────────────────────────────────────────────────────────────────────────
// WIKI CONSISTENCY CHECKER
// ──────────────────────────────────────────────────────────────────────────────
//
// Validates cross-file consistency of docs/wiki/. Designed for both human
// developers and AI agents to run after editing wiki pages.
//
// ── AGENT USAGE ──────────────────────────────────────────────────────────────
//
// 1. BEFORE editing any wiki file, run:
//      dart scripts/check_wiki_consistency.dart --json
//    Parse the JSON output. If hasIssues is true, fix existing issues first.
//
// 2. AFTER editing wiki files, run:
//      dart scripts/check_wiki_consistency.dart
//    Exit code 0 = clean, 1 = issues found. Must be 0 before committing.
//
// 3. To auto-fix common issues (missing INDEX entries, description drift):
//      dart scripts/check_wiki_consistency.dart --fix
//    Always review the diff after --fix.
//
// 4. When creating a new wiki page:
//    a. Write the page following kebab-case naming
//    b. Run --fix to add it to INDEX.md automatically
//    c. Add cross-references from related pages (see concept table below)
//    d. Run the checker again to verify
//
// 5. When renaming a heading:
//    a. Update the heading in the file
//    b. Grep for old #anchor references: grep(pattern='#old-anchor', path='docs/wiki', include='*.md')
//    c. Update all inbound links
//    d. Run the checker to verify
//
// ── EXIT CODES ───────────────────────────────────────────────────────────────
//
//   0  All checks passed
//   1  One or more issues found (broken links, orphans, conflicts, etc.)
//
// ── OUTPUT FORMATS ───────────────────────────────────────────────────────────
//
//   Default:   Human-readable report with sections
//   --json:    Machine-readable JSON (see ConsistencyResult.toJson)
//
// ── FLAGS ────────────────────────────────────────────────────────────────────
//
//   --json     Output results as JSON
//   --check    Check only, never auto-fix (default behavior)
//   --fix      Auto-fix: add missing INDEX entries, fix description drift,
//              add concept cross-references
//
// ── WHAT IT CHECKS ───────────────────────────────────────────────────────────
//
//   1. BROKEN LINKS
//      Every [text](target.md) resolves to an existing file.
//      Heading-only links (#anchor) are checked separately.
//
//   2. ORPHAN PAGES
//      Every .md file (except INDEX.md) is linked from at least one other
//      page OR appears in INDEX.md. Unlinked pages are orphans.
//
//   3. INDEX.MD COMPLETENESS
//      All wiki pages must be listed in INDEX.md. INDEX.md must not contain
//      links to nonexistent files.
//
//   4. CONFLICTING FACTS
//      Numerical claims (node types, commands, modules, states, etc.) must
//      be identical across all files. Code block content is excluded.
//      Tracked claims: node types, commands, command files, mutation modules,
//      FSM states, interaction states, paint layers, routing algorithms,
//      path shapers, composers, force implementations.
//
//   5. DESCRIPTION DRIFT
//      Link text in INDEX.md should match the actual # Heading of the
//      target page. Uses Jaccard similarity with 0.6 threshold.
//
//   6. MISSING ANCHORS
//      Links to file.md#heading must target an existing heading.
//      Anchors are derived: lowercase, spaces→hyphens, strip non-alphanumeric.
//
//   7. CONCEPT GAPS
//      When a key concept is mentioned in a file, that file should link to
//      the concept's canonical definition page. See concept table below.
//
// ── CONCEPT REGISTRY ─────────────────────────────────────────────────────────
//
// These concepts have canonical definition pages. When mentioning them in
// wiki files, link to the canonical page on first mention:
//
//   Concept                  Canonical Page
//   ───────────────────────  ──────────────────────────────────────
//   UiNode                   modules/graph/node-types.md
//   GraphApi                 modules/graph/store.md
//   GraphCommand             modules/graph/commands.md
//   GraphSyncEngine          modules/graph/store.md
//   InteractionEngine        modules/graph/interaction-engine.md
//   GraphCanvas              modules/graph/canvas.md
//   AppHandle                ffi/README.md
//   Repository               backend/persistence.md
//   GraphService             backend/services.md
//   RelationEngine           backend/relation-engine.md
//   LayoutEngine             backend/layout-engine.md
//   SymmetricEntityPatch     backend/domain.md
//   GraphEvent               ffi/README.md
//   SurrealDB                backend/persistence.md
//   FRB                      ffi/README.md
//   .cent                    backend/format.md
//   OptArea                  backend/layout-engine.md
//   ContainerNode            modules/graph/node-types.md
//   FrameNode                modules/graph/node-types.md
//   CommandQueueProcessor    modules/graph/commands.md
//   ValueNotifier            modules/graph/store.md
//   StreamSink               ffi/README.md
//
// ── CROSS-REFERENCE RULES ────────────────────────────────────────────────────
//
//   - Use RELATIVE paths from the current file's directory
//   - Use ../ to go up directories (e.g., ../../design/shaders.md)
//   - Never use absolute paths (docs/wiki/backend/...)
//   - Link on first mention of a concept, not every mention
//   - Keep link text matching the target page's # Heading
//
// ── FILE NAMING ──────────────────────────────────────────────────────────────
//
//   - kebab-case.md (e.g., relation-engine.md)
//   - README.md for module index pages
//   - Match filename to concept name
//
// ── INTEGRATION WITH AGENT WORKFLOWS ────────────────────────────────────────
//
//   This script is part of the wiki-consistency skill. Agents should:
//
//   1. Load the skill before editing wiki:
//        read_file(.agents/skills/documentation/wiki-consistency/SKILL.md)
//
//   2. Follow the documenter workflow for post-change updates:
//        read_file(.agents/workflows/documenter.md)
//
//   3. Run this script as the final validation step in both workflows.
//
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

const wikiDir = 'docs/wiki';

String normPath(String path) {
  var normalized = p.normalize(path).replaceAll(r'\', '/');
  if (normalized.length >= 2 && normalized[1] == ':') {
    normalized = normalized[0].toLowerCase() + normalized.substring(1);
  }
  return normalized;
}

void main(List<String> arguments) {
  final jsonOutput = arguments.contains('--json');
  final fixMode = arguments.contains('--fix');
  final checkOnly = arguments.contains('--check');
  final syncIndexMode =
      arguments.contains('--sync-index') || arguments.contains('--generate-index');

  if (syncIndexMode) {
    print('=== Smart Index Synchronization ===\n');
    final generator = SmartIndexGenerator();
    generator.syncIndex();
    print('\nINDEX.md synchronized successfully with smart page synopses.');
    return;
  }

  final checker = WikiConsistencyChecker();
  final result = checker.run();

  if (jsonOutput) {
    print(jsonEncode(result.toJson()));
  } else {
    result.printReport();
  }

  if (fixMode && result.hasIssues) {
    final fixer = WikiFixer(result);
    fixer.fix();
  }

  if (checkOnly || !fixMode) {
    exit(result.hasIssues ? 1 : 0);
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class ConsistencyResult {
  final List<BrokenLink> brokenLinks;
  final List<OrphanPage> orphanPages;
  final List<IndexIssue> indexIssues;
  final List<FactConflict> factConflicts;
  final List<DescriptionDrift> descriptionDrifts;
  final List<MissingAnchor> missingAnchors;
  final List<ConceptGap> conceptGaps;
  final List<CodebaseRotIssue> codebaseRotIssues;
  final int filesScanned;
  final int linksChecked;

  ConsistencyResult({
    required this.brokenLinks,
    required this.orphanPages,
    required this.indexIssues,
    required this.factConflicts,
    required this.descriptionDrifts,
    required this.missingAnchors,
    required this.conceptGaps,
    required this.codebaseRotIssues,
    required this.filesScanned,
    required this.linksChecked,
  });

  bool get hasIssues => brokenLinks.isNotEmpty ||
      orphanPages.isNotEmpty ||
      indexIssues.isNotEmpty ||
      factConflicts.isNotEmpty ||
      descriptionDrifts.isNotEmpty ||
      missingAnchors.isNotEmpty ||
      conceptGaps.isNotEmpty ||
      codebaseRotIssues.isNotEmpty;

  int get issueCount => brokenLinks.length +
      orphanPages.length +
      indexIssues.length +
      factConflicts.length +
      descriptionDrifts.length +
      missingAnchors.length +
      conceptGaps.length +
      codebaseRotIssues.length;

  Map<String, dynamic> toJson() => {
        'hasIssues': hasIssues,
        'issueCount': issueCount,
        'filesScanned': filesScanned,
        'linksChecked': linksChecked,
        'brokenLinks': brokenLinks.map((e) => e.toJson()).toList(),
        'orphanPages': orphanPages.map((e) => e.toJson()).toList(),
        'indexIssues': indexIssues.map((e) => e.toJson()).toList(),
        'factConflicts': factConflicts.map((e) => e.toJson()).toList(),
        'descriptionDrifts': descriptionDrifts.map((e) => e.toJson()).toList(),
        'missingAnchors': missingAnchors.map((e) => e.toJson()).toList(),
        'conceptGaps': conceptGaps.map((e) => e.toJson()).toList(),
        'codebaseRotIssues': codebaseRotIssues.map((e) => e.toJson()).toList(),
      };

  void printReport() {
    _printSection('Link Validation', brokenLinks.map((e) => '  ${e.source} → ${e.target}').toList(),
        emptyMsg: 'All links valid ($linksChecked total)');

    _printSection('Orphan Pages', orphanPages.map((e) => '  ${e.path} — ${e.reason}').toList(),
        emptyMsg: 'No orphan pages');

    _printSection('INDEX.md Issues', indexIssues.map((e) => '  ${e.message}').toList(),
        emptyMsg: 'INDEX.md is consistent');

    _printSection('Conflicting Facts', factConflicts.expand((e) => [
      '  ${e.claim}',
      ...e.occurrences.map((o) => '    ${o.file}: "${o.context}"'),
    ]).toList(), emptyMsg: 'No conflicting facts');

    _printSection('Description Drift', descriptionDrifts.map((e) =>
        '  ${e.target}\n    index: "${e.indexDesc}"\n    actual: "${e.actualHeading}"').toList(),
        emptyMsg: 'No description drift');

    _printSection('Missing Anchors', missingAnchors.map((e) =>
        '  ${e.source} → ${e.target} (anchor: #${e.anchor})').toList(),
        emptyMsg: 'All heading anchors valid');

    _printSection('Concept Gaps', conceptGaps.map((e) =>
        '  ${e.file}: "${e.concept}" not linked to its definition in ${e.definitionFile}').toList(),
        emptyMsg: 'All concept references linked');

    _printSection('Codebase Path References', codebaseRotIssues.map((e) =>
        '  ${e.wikiFile}:${e.line} → "${e.referencedPath}" (${e.reason})').toList(),
        emptyMsg: 'All referenced codebase files and directories exist');

    print('=== Summary ===');
    print('  Files: $filesScanned | Links: $linksChecked | Issues: $issueCount');
  }

  void _printSection(String title, List<String> lines, {required String emptyMsg}) {
    print('=== $title ===\n');
    if (lines.isEmpty) {
      print('  $emptyMsg\n');
    } else {
      for (final line in lines) {
        print(line);
      }
      print('');
    }
  }
}

class BrokenLink {
  final String source;
  final String target;
  final int line;
  BrokenLink(this.source, this.target, this.line);
  Map<String, dynamic> toJson() => {'source': source, 'target': target, 'line': line};
}

class OrphanPage {
  final String path;
  final String reason;
  OrphanPage(this.path, this.reason);
  Map<String, dynamic> toJson() => {'path': path, 'reason': reason};
}

class IndexIssue {
  final String message;
  IndexIssue(this.message);
  Map<String, dynamic> toJson() => {'message': message};
}

class FactConflict {
  final String claim;
  final List<FactOccurrence> occurrences;
  FactConflict(this.claim, this.occurrences);
  Map<String, dynamic> toJson() => {'claim': claim, 'occurrences': occurrences.map((e) => e.toJson()).toList()};
}

class FactOccurrence {
  final String file;
  final String value;
  final String context;
  FactOccurrence(this.file, this.value, this.context);
  Map<String, dynamic> toJson() => {'file': file, 'value': value, 'context': context};
}

class DescriptionDrift {
  final String target;
  final String indexDesc;
  final String actualHeading;
  DescriptionDrift(this.target, this.indexDesc, this.actualHeading);
  Map<String, dynamic> toJson() => {'target': target, 'indexDesc': indexDesc, 'actualHeading': actualHeading};
}

class MissingAnchor {
  final String source;
  final String target;
  final String anchor;
  MissingAnchor(this.source, this.target, this.anchor);
  Map<String, dynamic> toJson() => {'source': source, 'target': target, 'anchor': anchor};
}

class ConceptGap {
  final String file;
  final String concept;
  final String definitionFile;
  ConceptGap(this.file, this.concept, this.definitionFile);
  Map<String, dynamic> toJson() => {'file': file, 'concept': concept, 'definitionFile': definitionFile};
}

class CodebaseRotIssue {
  final String wikiFile;
  final String referencedPath;
  final int line;
  final String reason;

  CodebaseRotIssue({
    required this.wikiFile,
    required this.referencedPath,
    required this.line,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'wikiFile': wikiFile,
    'referencedPath': referencedPath,
    'line': line,
    'reason': reason,
  };
}

// ─── Link Extraction ─────────────────────────────────────────────────────────

class MarkdownLink {
  final String text;
  final String target;
  final int line;
  final bool isExternal;
  MarkdownLink(this.text, this.target, this.line, this.isExternal);
}

List<MarkdownLink> extractLinks(String content, String sourcePath) {
  final links = <MarkdownLink>[];
  final regex = RegExp(r'\[([^\]]*)\]\(([^)]+)\)');
  var lineNum = 0;
  for (final line in content.split('\n')) {
    lineNum++;
    for (final m in regex.allMatches(line)) {
      final target = m.group(2)!;
      final isExt = target.startsWith('http://') || target.startsWith('https://');
      links.add(MarkdownLink(m.group(1)!, target, lineNum, isExt));
    }
  }
  return links;
}

String resolveTarget(String sourcePath, String target) {
  // Handle heading-only links (same file)
  if (target.startsWith('#')) return sourcePath;
  final decodedTarget = Uri.decodeComponent(target);
  final sourceDir = p.dirname(sourcePath);
  return p.canonicalize(p.join(sourceDir, decodedTarget.split('#').first));
}

// ─── Concept Registry ────────────────────────────────────────────────────────

/// Tracks where key concepts are defined and referenced across the wiki.
class ConceptRegistry {
  /// concept name → file where it's defined (the "canonical" page)
  final definitions = <String, String>{};

  /// concept name → files that mention it
  final references = <String, Set<String>>{};

  /// Well-known concepts and their canonical definition pages
  static const knownConcepts = {
    'UiNode': 'modules/graph/node-types.md',
    'GraphApi': 'modules/graph/store.md',
    'GraphCommand': 'modules/graph/commands.md',
    'GraphSyncEngine': 'modules/graph/store.md',
    'InteractionEngine': 'modules/graph/interaction-engine.md',
    'GraphCanvas': 'modules/graph/canvas.md',
    'AppHandle': 'ffi/README.md',
    'Repository': 'backend/persistence.md',
    'GraphService': 'backend/services.md',
    'RelationEngine': 'backend/relation-engine.md',
    'LayoutEngine': 'backend/layout-engine.md',
    'SymmetricEntityPatch': 'backend/domain.md',
    'GraphEvent': 'ffi/README.md',
    'SurrealDB': 'backend/persistence.md',
    'FRB': 'ffi/README.md',
    'Flutter Rust Bridge': 'ffi/README.md',
    '.cent': 'backend/format.md',
    'OptArea': 'backend/layout-engine.md',
    'ContainerNode': 'modules/graph/node-types.md',
    'FrameNode': 'modules/graph/node-types.md',
    'CommandQueueProcessor': 'modules/graph/commands.md',
    'ValueNotifier': 'modules/graph/store.md',
    'StreamSink': 'ffi/README.md',
  };

  void scan(String relativePath, String content) {
    for (final entry in knownConcepts.entries) {
      if (content.contains(RegExp(r'\b' + RegExp.escape(entry.key) + r'\b'))) {
        references.putIfAbsent(entry.key, () => {}).add(relativePath);
        if (entry.value == relativePath) {
          definitions[entry.key] = relativePath;
        }
      }
    }
  }

  /// Find concepts mentioned in [file] that aren't linked to their definition page.
  List<ConceptGap> findGaps(String file, Set<String> linkedTargets) {
    final gaps = <ConceptGap>[];
    for (final entry in references.entries) {
      if (!entry.value.contains(file)) continue;
      final defFile = knownConcepts[entry.key];
      if (defFile == null || defFile == file) continue;

      // Check if this file links to the definition page
      final normalizedDef = normPath(p.canonicalize(p.join(wikiDir, defFile)));
      final fileAlreadyLinks = linkedTargets.any((t) => t == normalizedDef);
      if (!fileAlreadyLinks) {
        gaps.add(ConceptGap(file, entry.key, defFile));
      }
    }
    return gaps;
  }
}

// ─── Main Checker ────────────────────────────────────────────────────────────

class WikiConsistencyChecker {
  final conceptRegistry = ConceptRegistry();

  ConsistencyResult run() {
    final wikiPath = Directory(wikiDir);
    if (!wikiPath.existsSync()) {
      print('Error: $wikiDir not found.');
      exit(1);
    }

    final mdFiles = <File>[];
    for (final entity in wikiPath.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        mdFiles.add(entity);
      }
    }

    final allWikiFiles = mdFiles
        .map((f) => normPath(p.canonicalize(f.path)))
        .toList();

    // Pass 1: Extract links, scan concepts
    final linksByFile = <String, List<MarkdownLink>>{};
    final linkedFiles = <String>{};
    final fileContents = <String, String>{};

    for (final file in mdFiles) {
      final rel = normPath(p.relative(file.path, from: wikiDir));
      final content = file.readAsStringSync();
      fileContents[rel] = content;
      final links = extractLinks(content, file.path);
      linksByFile[rel] = links;

      for (final link in links) {
        if (link.isExternal) continue;
        final resolved = resolveTarget(file.path, link.target);
        linkedFiles.add(normPath(resolved));
      }

      conceptRegistry.scan(rel, content);
    }

    // Run all checks
    final brokenLinks = _checkBrokenLinks(linksByFile);
    final orphanPages = _checkOrphans(allWikiFiles, linkedFiles);
    final indexIssues = _checkIndex(allWikiFiles);
    final factConflicts = _checkFacts(fileContents);
    final descriptionDrifts = _checkDrifts();
    final missingAnchors = _checkAnchors(linksByFile, fileContents);
    final conceptGaps = _checkConceptGaps(fileContents, linkedFiles);
    final codebaseRotIssues = _checkCodebasePaths(fileContents);

    return ConsistencyResult(
      brokenLinks: brokenLinks,
      orphanPages: orphanPages,
      indexIssues: indexIssues,
      factConflicts: factConflicts,
      descriptionDrifts: descriptionDrifts,
      missingAnchors: missingAnchors,
      conceptGaps: conceptGaps,
      codebaseRotIssues: codebaseRotIssues,
      filesScanned: mdFiles.length,
      linksChecked: linksByFile.values.fold(0, (s, l) => s + l.length),
    );
  }

  List<BrokenLink> _checkBrokenLinks(Map<String, List<MarkdownLink>> linksByFile) {
    final issues = <BrokenLink>[];
    for (final entry in linksByFile.entries) {
      final sourceFile = p.absolute(p.join(wikiDir, entry.key));
      for (final link in entry.value) {
        if (link.isExternal || link.target.startsWith('#')) continue;
        final resolved = resolveTarget(sourceFile, link.target);
        if (!File(resolved).existsSync()) {
          issues.add(BrokenLink(entry.key, link.target, link.line));
        }
      }
    }
    return issues;
  }

  List<OrphanPage> _checkOrphans(List<String> allFiles, Set<String> linkedFiles) {
    final indexTargets = _getIndexTargets();
    final orphans = <OrphanPage>[];
    for (final file in allFiles) {
      final short = normPath(p.relative(file, from: normPath(p.canonicalize(wikiDir))));
      if (short.toLowerCase() == 'index.md') continue;
      final isLinked = linkedFiles.contains(file);
      final inIndex = indexTargets.contains(file);
      if (!isLinked && !inIndex) {
        orphans.add(OrphanPage(short, 'not linked from any page or INDEX.md'));
      }
    }
    return orphans;
  }

  Set<String> _getIndexTargets({List<IndexIssue>? issues}) {
    final indexFile = File(p.join(wikiDir, 'INDEX.md'));
    if (!indexFile.existsSync()) return {};
    final content = indexFile.readAsStringSync();
    final targets = <String>{};
    for (final link in extractLinks(content, indexFile.path)) {
      if (link.isExternal) continue;
      final resolved = resolveTarget(indexFile.path, link.target);
      if (issues != null && !File(resolved).existsSync()) {
        issues.add(IndexIssue('Broken link: ${link.target}'));
      }
      targets.add(normPath(resolved));
    }
    return targets;
  }

  List<IndexIssue> _checkIndex(List<String> allFiles) {
    final issues = <IndexIssue>[];
    final indexFile = File(p.join(wikiDir, 'INDEX.md'));
    if (!indexFile.existsSync()) {
      issues.add(IndexIssue('INDEX.md not found'));
      return issues;
    }

    final targets = _getIndexTargets(issues: issues);

    for (final file in allFiles) {
      final short = normPath(p.relative(file, from: normPath(p.canonicalize(wikiDir))));
      if (short.toLowerCase() == 'index.md') continue;
      if (!targets.contains(file)) {
        issues.add(IndexIssue('Missing from INDEX: $short'));
      }
    }
    return issues;
  }

  List<FactConflict> _checkFacts(Map<String, String> fileContents) {
    final facts = <String, List<FactOccurrence>>{};
    final patterns = [
      [RegExp(r'(\d+)\s+node\s+types?', caseSensitive: false), 'node types'],
      [RegExp(r'(\d+)\s+commands?\s+files?', caseSensitive: false), 'command files'],
      [RegExp(r'(\d+)\s+commands?(?!\s+files?)', caseSensitive: false), 'commands'],
      [RegExp(r'(\d+)\s+mutation\s+modules?', caseSensitive: false), 'mutation modules'],
      [RegExp(r'(\d+)\s+FSM\s+states?', caseSensitive: false), 'FSM states'],
      [RegExp(r'(\d+)\s+interaction\s+states?', caseSensitive: false), 'interaction states'],
      [RegExp(r'(\d+)\s+paint\s+layers?', caseSensitive: false), 'paint layers'],
      [RegExp(r'(\d+)\s+routing\s+algorithms?', caseSensitive: false), 'routing algorithms'],
      [RegExp(r'(\d+)\s+path\s+shap(?:ing|ers?)', caseSensitive: false), 'path shapers'],
      [RegExp(r'(\d+)\s+composer', caseSensitive: false), 'composers'],
      [RegExp(r'(\d+)\s+force\s+implementations?', caseSensitive: false), 'force implementations'],
    ];

    for (final entry in fileContents.entries) {
      var inCodeBlock = false;
      for (final line in entry.value.split('\n')) {
        if (line.trimLeft().startsWith('```')) {
          inCodeBlock = !inCodeBlock;
          continue;
        }
        if (inCodeBlock) continue;

        for (final pair in patterns) {
          final regex = pair[0] as RegExp;
          final key = pair[1] as String;
          for (final m in regex.allMatches(line)) {
            facts.putIfAbsent(key, () => []).add(
              FactOccurrence(entry.key, m.group(1)!, line.trim()),
            );
          }
        }
      }
    }

    final conflicts = <FactConflict>[];
    for (final entry in facts.entries) {
      final values = entry.value.map((o) => o.value).toSet();
      if (values.length > 1) {
        conflicts.add(FactConflict(entry.key, entry.value));
      }
    }
    return conflicts;
  }

  List<DescriptionDrift> _checkDrifts() {
    final drifts = <DescriptionDrift>[];
    final seen = <String>{};
    final indexFile = File(p.join(wikiDir, 'INDEX.md'));
    if (!indexFile.existsSync()) return drifts;

    final content = indexFile.readAsStringSync();
    final headingRegex = RegExp(r'^#\s+(.+)', multiLine: true);

    for (final link in extractLinks(content, indexFile.path)) {
      if (link.isExternal) continue;
      final resolved = resolveTarget(indexFile.path, link.target);
      if (!p.isWithin(p.canonicalize(wikiDir), resolved)) continue;
      final file = File(resolved);
      if (!file.existsSync()) continue;

      final match = headingRegex.firstMatch(file.readAsStringSync());
      if (match == null) continue;

      final actual = match.group(1)!;
      final normIdx = link.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final normAct = actual.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (normIdx == normAct) continue;
      if (normAct.contains(normIdx) || normIdx.contains(normAct)) continue;

      // Jaccard similarity on character sets
      final a = normIdx.split('').toSet();
      final b = normAct.split('').toSet();
      final jaccard = a.intersection(b).length / a.union(b).length;
      if (jaccard > 0.6) continue;

      if (seen.add(link.target)) {
        drifts.add(DescriptionDrift(link.target, link.text, actual));
      }
    }
    return drifts;
  }

  List<MissingAnchor> _checkAnchors(
    Map<String, List<MarkdownLink>> linksByFile,
    Map<String, String> fileContents,
  ) {
    final issues = <MissingAnchor>[];

    for (final entry in linksByFile.entries) {
      final sourceFile = p.absolute(p.join(wikiDir, entry.key));
      for (final link in entry.value) {
        if (link.isExternal || !link.target.contains('#')) continue;

        final parts = link.target.split('#');
        final anchor = parts[1];
        final filePart = parts.isEmpty ? '' : parts[0];

        // Determine which file to search
        String targetFile;
        if (filePart.isEmpty) {
          targetFile = sourceFile;
        } else {
          targetFile = resolveTarget(sourceFile, filePart);
        }

        if (!File(targetFile).existsSync()) continue;

        final content = File(targetFile).readAsStringSync();
        // Convert heading to anchor: lowercase, spaces to hyphens, strip non-alphanumeric
        final headings = RegExp(r'^#{1,6}\s+(.+)', multiLine: true)
            .allMatches(content)
            .map((m) => m.group(1)!)
            .map((h) => h.toLowerCase()
                .replaceAll(RegExp(r'[^\w\s-]'), '')
                .replaceAll(RegExp(r'\s+'), '-'))
            .toSet();

        if (!headings.contains(anchor.toLowerCase())) {
          issues.add(MissingAnchor(entry.key, link.target, anchor));
        }
      }
    }
    return issues;
  }

  List<ConceptGap> _checkConceptGaps(Map<String, String> fileContents, Set<String> linkedFiles) {
    final gaps = <ConceptGap>[];
    for (final entry in fileContents.entries) {
      final fileGaps = conceptRegistry.findGaps(entry.key, linkedFiles);
      gaps.addAll(fileGaps);
    }
    return gaps;
  }

  List<CodebaseRotIssue> _checkCodebasePaths(Map<String, String> fileContents) {
    final issues = <CodebaseRotIssue>[];
    final pathRegex = RegExp(
      r'`((?:lib|rust|packages|scripts|assets|integration_test|test|docs)/[^`\s*#?]+)`',
    );

    for (final entry in fileContents.entries) {
      final wikiFile = entry.key;
      final lines = entry.value.split('\n');

      for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
        final line = lines[lineIdx];
        if (line.trim().startsWith('```')) continue;

        for (final match in pathRegex.allMatches(line)) {
          var rawPath = match.group(1)!;

          // Strip line number or anchor suffixes
          rawPath = rawPath.replaceAll(RegExp(r'[:#]L?\d+.*$'), '').trim();

          // Strip trailing punctuation
          while (rawPath.endsWith('.') || rawPath.endsWith(',') || rawPath.endsWith(';')) {
            rawPath = rawPath.substring(0, rawPath.length - 1);
          }

          // Skip generic path wildcards / patterns
          if (rawPath.contains('*') || rawPath.contains('<') || rawPath.contains('{')) {
            continue;
          }

          final normalized = normPath(p.normalize(rawPath));
          if (!File(normalized).existsSync() && !Directory(normalized).existsSync()) {
            issues.add(CodebaseRotIssue(
              wikiFile: wikiFile,
              referencedPath: rawPath,
              line: lineIdx + 1,
              reason: 'Referenced codebase path not found',
            ));
          }
        }
      }
    }
    return issues;
  }
}

// ─── Smart Index Generator ───────────────────────────────────────────────────

class PageMetadata {
  final String title;
  final String description;

  PageMetadata({required this.title, required this.description});
}

class SmartIndexGenerator {
  static PageMetadata extractMetadata(File file) {
    if (!file.existsSync()) {
      final base = p
          .basenameWithoutExtension(file.path)
          .replaceAll('-', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
          .join(' ');
      return PageMetadata(title: base, description: '');
    }

    final content = file.readAsStringSync();
    final lines = content.split('\n');

    String title = '';
    String description = '';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (title.isEmpty && line.startsWith('# ')) {
        title = line.substring(2).trim();
        continue;
      }

      if (title.isNotEmpty && description.isEmpty) {
        if (line.isEmpty ||
            line.startsWith('>') ||
            line.startsWith('---') ||
            line.startsWith('#') ||
            line.startsWith('```') ||
            line.startsWith('|') ||
            line.startsWith('- ')) {
          continue;
        }

        var para = line;
        var j = i + 1;
        while (j < lines.length &&
            lines[j].trim().isNotEmpty &&
            !lines[j].trim().startsWith('#') &&
            !lines[j].trim().startsWith('```') &&
            !lines[j].trim().startsWith('|') &&
            !lines[j].trim().startsWith('---')) {
          para += ' ${lines[j].trim()}';
          j++;
        }

        para = para
            .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
            .replaceAll(RegExp(r'[*_`#]'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        if (para.length > 120) {
          final cutoff = para.lastIndexOf(' ', 117);
          para = '${cutoff != -1 ? para.substring(0, cutoff) : para.substring(0, 117)}...';
        }
        description = para;
        break;
      }
    }

    if (title.isEmpty) {
      title = p
          .basenameWithoutExtension(file.path)
          .replaceAll('-', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
          .join(' ');
    }

    return PageMetadata(title: title, description: description);
  }

  void syncIndex() {
    final indexFile = File(p.join(wikiDir, 'INDEX.md'));
    if (!indexFile.existsSync()) {
      print('Error: INDEX.md not found at ${indexFile.path}');
      return;
    }

    var content = indexFile.readAsStringSync();
    final allWikiFiles = Directory(wikiDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .map((f) => normPath(f.path))
        .toList();

    final wikiCanonical = normPath(p.canonicalize(wikiDir));

    // Map files to sections
    final sectionHeaders = {
      'architecture': '## Architecture',
      'modules': '## Flutter Modules (`lib/`)',
      'backend': '## Rust Backend (`rust/src/`)',
      'ffi': '## FFI Bridge',
      'guides': '## Developer Guides',
      'design': '## Design & Specs',
    };

    int updatedCount = 0;
    int addedCount = 0;

    for (final filePath in allWikiFiles) {
      final short = normPath(p.relative(filePath, from: wikiCanonical));
      if (short.toLowerCase() == 'index.md') continue;

      final meta = extractMetadata(File(filePath));
      final linkPattern = RegExp(r'\[([^\]]+)\]\(' + RegExp.escape(short) + r'\)');

      if (linkPattern.hasMatch(content)) {
        // Check for title drift
        final match = linkPattern.firstMatch(content)!;
        final currentTitle = match.group(1)!;
        if (currentTitle != meta.title && meta.title.isNotEmpty) {
          content = content.replaceAll(
            '[$currentTitle]($short)',
            '[${meta.title}]($short)',
          );
          print('  Updated title for $short: "$currentTitle" → "${meta.title}"');
          updatedCount++;
        }
      } else {
        // Missing from index! Find appropriate section
        final parts = short.split('/');
        final sectionKey = parts.length > 1 ? parts[0] : '';
        final header = sectionHeaders[sectionKey];

        if (header != null && content.contains(header)) {
          final sectionStart = content.indexOf(header);
          final nextSection = content.indexOf('\n## ', sectionStart + header.length);
          final insertPos = nextSection != -1 ? nextSection : content.length;

          final desc = meta.description.isNotEmpty ? meta.description : 'Module documentation';
          final newRow = '| [${meta.title}]($short) | $desc |\n';

          content = '${content.substring(0, insertPos)}$newRow${content.substring(insertPos)}';
          print('  Added $short under $header with synopsis: "$desc"');
          addedCount++;
        }
      }
    }

    indexFile.writeAsStringSync(content);
    print('  Summary: $addedCount added, $updatedCount updated.');
  }
}

// ─── Auto-Fixer ──────────────────────────────────────────────────────────────

class WikiFixer {
  final ConsistencyResult result;
  WikiFixer(this.result);

  void fix() {
    print('\n=== Auto-fix ===\n');

    final indexGenerator = SmartIndexGenerator();
    indexGenerator.syncIndex();

    if (result.conceptGaps.isNotEmpty) {
      _fixConceptGaps();
    }
  }

  void _fixConceptGaps() {
    // Group gaps by file
    final byFile = <String, List<ConceptGap>>{};
    for (final gap in result.conceptGaps) {
      byFile.putIfAbsent(gap.file, () => []).add(gap);
    }

    for (final entry in byFile.entries) {
      final filePath = p.join(wikiDir, entry.key);
      var content = File(filePath).readAsStringSync();

      for (final gap in entry.value) {
        // Find lines mentioning the concept without a link
        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains(RegExp(r'\b' + RegExp.escape(gap.concept) + r'\b'))) {
            // Check if it's already linked
            if (!lines[i].contains('](${gap.definitionFile})') &&
                !lines[i].contains('](${p.basename(gap.definitionFile)}))')) {
              // Add a note at end of file about the concept reference
              final note = '\n> **See also**: [${gap.concept}](${gap.definitionFile})\n';
              if (!content.contains(note.trim())) {
                content = content.trimRight() + note;
                print('  Added cross-reference to ${gap.concept} in ${entry.key}');
              }
            }
            break;
          }
        }
      }

      File(filePath).writeAsStringSync(content);
    }
  }
}
