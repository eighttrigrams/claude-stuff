---
name: navigate-rhizome-user-interface
description: Use to navigate Rhizome's UI during development
---

# Navigate Rhizome User Interface

This skill helps you navigate and interact with the Rhizome user interface.

## Overview

Rhizome is a Zettelkasten-style note-taking system with a keyboard-driven interface. It consists of contexts (categories/collections) and items (individual notes/entries).

## Prerequisites

The application must run, obviously

## Basic Navigation

### Context Search
- Press `c` to open context search
- Type to filter contexts
- Press `Enter` to select a context
- Press `Escape` to cancel

### Item Search
- Press `i` to open item search (when a context is selected)
- Type to filter items or create new item
- Press `Enter` to select item or create new one
- Press `Escape` to cancel

### Selecting Items
- Click on contexts in the left sidebar
- Click on items in the right panel
- Use keyboard shortcuts for first 5 items (1-5)

### Deselection
- Press `Escape` to deselect current item/context
- Press `Escape` again to go back to previous view

## Creating Content

### Creating Contexts
1. Press `c` to open context search
2. Type the name of new context
3. Press `Enter` to create it

### Creating Items
1. Select a context first
2. Press `i` to open item search
3. Type the name of new item
4. Press `Enter` to create it in the selected context

### Editing Items
- Press `e` to edit selected item
- Press `d` to view/edit description
- Press `Alt+9` to save changes
- Press `Escape` to cancel

## Linking

### Link Item to Current Context
- Select a context
- Press `a` to start linking mode
- Search for and select an item to link

### Crosslinking (Bidirectional)
- Select an item
- Press `Alt+Shift+A`
- Select another item to create bidirectional link
- **Note**: Links created this way do NOT set `show_badge` anymore

### Link Context to Context
- Select a context
- Press `q` to start context linking mode
- Select another context to link

## Importing Files

### Prerequisites
- A "Files" context must exist in the database
- An "Imports" context must exist in the database
- Supported file types: mp3, ogg, m4a, wav, mp4, flv, mov, pdf, tiff, jpg, jpeg, png, webp

### Import Process
1. **Place files in import directory**:
   - Path: `{homefolder}/Downloads/Tracked/`
   - Where `{homefolder}` is defined in `config.edn`
   - Default: `/Users/daniel/Workspace/plurama.eighttrigrams/rhizome.project/rhizome/files/`

2. **Trigger import**:
   - Navigate to "Imports" context (press `c`, type "Imports", press `Enter`)
   - Press `i` to create new item
   - Type "IMPORT" as the title
   - Press `Enter`

3. **What happens**:
   - System scans `{homefolder}/Downloads/Tracked/` directory
   - Each supported file is:
     - Created as a new item (title = filename without extension)
     - Linked to "Imports" context
     - Linked to "Files" context
     - Linked to type-specific context (e.g., "PNGs", "JPEGs", "Image" for images)
     - Moved to appropriate directory:
       - Images → `{homefolder}/Pictures/Tracked/`
       - Audio → `{homefolder}/Music/Tracked/`
       - Video → `{homefolder}/Movies/Tracked/`
       - Documents → `{homefolder}/Documents/Tracked/`

4. **Accessing imported images**:
   - Images can be embedded in descriptions using: `![description](item-id)`
   - Where `item-id` is the numeric ID of the imported image item

### Import Options
You can prefix the import with text to add to all filenames:
- Create item with title "IMPORT prefix-text"
- All files will be renamed with "prefix-text filename"

### Common Issues
- **"no id for Files" error**: The "Files" context doesn't exist in database - create it first
- **Files not importing**: Check that files are in correct directory and have supported extensions
- **Config path wrong**: Ensure `config.edn` has correct `:folders {:homefolder "..."}` path

## Image Transclusion

Once images are imported as items, you can embed them in any item description:

```markdown
Here is an embedded image:
![Alt text](12345)
```

Where `12345` is the ID of the imported image item. The image will be displayed inline in the description.

## Other Shortcuts

- `Delete` - Delete selected item
- `Alt+U` - Upgrade item to context
- `Alt+T` - Unlink selected item from container
- `Alt+B` - Select last context
- `Alt+D` - Edit item in Obsidian
- `s` - Cycle search mode
- `f` - Enter/exit item view

## Search Modes

Press `s` when a context is selected to cycle through:
- **Normal** (0): Most recently touched items first
- **Reverse** (1): Oldest items first
- **0→9** (2): Sorted by `sort_idx` ascending
- **9→0** (3): Sorted by `sort_idx` descending
- **Events** (4): Event-based sorting
- **Added** (5): Most recently added items first
