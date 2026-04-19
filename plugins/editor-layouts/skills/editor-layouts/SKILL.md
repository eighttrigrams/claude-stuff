---
name: editor-layouts
description: Knowledge about the save-editor-layout VS Code extension. Use when working with editor layouts, the .editor-layouts.json file, or bookmark management in VS Code.
---

# Editor Layouts

Reference: https://github.com/eighttrigrams/vscode-plugins/tree/main/save-editor-layout

The save-editor-layout VS Code extension saves and restores editor layouts. It persists data to `.editor-layouts.json` in the workspace root.

## JSON Data Structure

The `.editor-layouts.json` file contains an array of layout objects:

```json
[
  {
    "name": "string",
    "timestamp": 0,
    "editors": [
      {
        "path": "relative/to/workspace",
        "name": "filename.ext"
      }
    ],
    "bookmarks": [
      {
        "filePath": "relative/to/workspace",
        "line": 1,
        "timestamp": 0,
        "description": "optional"
      }
    ],
    "description": "optional"
  }
]
```

### Fields

- **name**: Display name of the layout
- **timestamp**: Unix timestamp of when the layout was saved
- **editors**: Array of open editor tabs
  - **path**: File path relative to the workspace root
  - **name**: Basename of the file
- **bookmarks**: Array of bookmarked locations
  - **filePath**: File path relative to the workspace root
  - **line**: 1-indexed line number (internally converted to 0-indexed when loaded)
  - **timestamp**: Unix timestamp of when the bookmark was created
  - **description**: Optional description of the bookmark
- **description**: Optional description of the layout

The extension tracks dirty state by comparing current editor tabs and bookmarks against persisted data, showing visual indicators when changes differ from the saved state. Missing files are tracked separately and can be removed individually from a layout.
