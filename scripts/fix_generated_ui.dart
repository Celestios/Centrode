"""
Quick fix for graph_node.ui.dart generated file.
Updates UUID patterns to work with RawUuid.
"""
import re
from pathlib import Path

FILE = Path(__file__).parent.parent / "lib" / "features" / "graph" / "models" / "graph_node.ui.dart"

content = FILE.read_text()

# Fix toRust(): UuidValue.fromString(id) -> UuidValue.fromString(id.toUuidString())
content = content.replace('UuidValue.fromString(id)', 'UuidValue.fromString(id.toUuidString())')

# Fix fromRust(): id: node.id.key.uuid -> id: RawUuid.fromString(node.id.key.uuid)
content = content.replace('id: node.id.key.uuid', 'id: RawUuid.fromString(node.id.key.uuid)')

# Fix copyWith(): String? id, -> RawUuid? id,
content = content.replace('String? id,', 'RawUuid? id,')

FILE.write_text(content)
print(f"Fixed {FILE}")
