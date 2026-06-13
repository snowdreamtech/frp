#!/usr/bin/env bash

# Universal IDE Adapter Compiler for Spec Kit (V2)
#
# Automatically synchronizes .specify/commands/ to various AI IDE environments.
# Features:
# - Idempotent updates (only writes if changed)
# - Orphan cleanup (deletes proxies if source command was removed)
# - Universal injection (auto-appends global pointers for Cline, Roo, Windsurf, Trae, Copilot)

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

COMMANDS_DIR="$REPO_ROOT/.specify/commands"
AGENT_WORKFLOWS_DIR="$REPO_ROOT/.agent/workflows"
CURSOR_RULES_DIR="$REPO_ROOT/.cursor/rules"

# Ensure target directories exist
mkdir -p "$AGENT_WORKFLOWS_DIR"

# Step 0: Global Cleanup of Legacy/Broken Symlinks
# The v1 script used symlinks which break when repositories are cloned or directories move.
# Find and delete all speckit*.md and snowdreamtech*.md symlinks in any top-level hidden directory to start fresh.
find "$REPO_ROOT" -maxdepth 3 -type l \( -name "speckit*.md" -o -name "snowdreamtech*.md" \) -path "$REPO_ROOT/.*" -delete 2>/dev/null || true

# Step 1: Collect Active Commands (macOS Bash 3.2 compatible string array)
ACTIVE_COMMANDS_STRING=" "

if [[ -d "$COMMANDS_DIR" ]]; then
    for cmd_file in "$COMMANDS_DIR"/*.md; do
        [[ -f "$cmd_file" ]] || continue
        base_name="${cmd_file##*/}"
        ACTIVE_COMMANDS_STRING="${ACTIVE_COMMANDS_STRING}${base_name} "
    done
fi

# Helper function to check if command is active
is_active_command() {
    local cmd_to_check="$1"
    if [[ "$ACTIVE_COMMANDS_STRING" == *" ${cmd_to_check} "* ]]; then
        return 0
    else
        return 1
    fi
}

# Helper function for idempotent writes
write_idempotent() {
    local target_file="$1"
    local content="$2"
    
    # If target is a symlink, remove it first
    if [[ -L "$target_file" ]]; then
        rm -f "$target_file"
    fi
    
    # If file exists, read it entirely into a variable for fast comparison
    if [[ -f "$target_file" ]]; then
        local existing_content
        existing_content="$(< "$target_file")"
        if [[ "$existing_content" == "$content" ]]; then
            return 0
        fi
    fi
    
    # Write the new content
    echo "$content" > "$target_file"
}

# Helper function to inject global pointers into IDE-specific system prompts
ensure_global_pointer() {
    local target_file="$1"
    local content="
> **Spec Kit AI IDE Integration**
> This project uses Spec Kit. 
> CRITICAL: If you need to execute workflows or commands, refer to the files in \`.agent/workflows/\`.
> CRITICAL: For project governance and rules, refer to \`.agent/rules/00-index.md\`.
"
    
    # Check if the directory containing the target file exists (e.g. .github/)
    local dir_path="$(dirname "$target_file")"
    if [[ "$dir_path" != "." ]] && [[ ! -d "$REPO_ROOT/$dir_path" ]]; then
        return 0 # Skip if the IDE directory like .github doesn't exist
    fi

    local full_path="$REPO_ROOT/$target_file"
    
    # If the file doesn't exist, just create it
    if [[ ! -f "$full_path" ]]; then
        echo "$content" > "$full_path"
        return 0
    fi
    
    # If it exists, append only if our specific pointer string isn't present
    if ! grep -q "Spec Kit AI IDE Integration" "$full_path"; then
        echo "$content" >> "$full_path"
    fi
}

# Step 2: Generate Files & Clean Orphans for Generic Agents (.agent/workflows/)
if [[ -d "$COMMANDS_DIR" ]]; then
    for cmd_file in "$COMMANDS_DIR"/*.md; do
        [[ -f "$cmd_file" ]] || continue
        base_name="${cmd_file##*/}"
        content="---
description: Proxy for $base_name
---

## Execute Command

Please read \`.specify/commands/$base_name\` and execute its instructions exactly."
        
        write_idempotent "$AGENT_WORKFLOWS_DIR/$base_name" "$content"
    done
fi

# Clean Orphans in .agent/workflows/
for existing_file in "$AGENT_WORKFLOWS_DIR"/*.md; do
    [[ -f "$existing_file" ]] || continue
    base_name="${existing_file##*/}"
    if ! is_active_command "$base_name"; then
        rm -f "$existing_file"
    fi
done

# Step 3: Generate Files & Clean Orphans for Cursor (.cursor/rules/)
if [[ -d "$REPO_ROOT/.cursor" ]]; then
    mkdir -p "$CURSOR_RULES_DIR"
    
    # Generate
    if [[ -d "$COMMANDS_DIR" ]]; then
        for cmd_file in "$COMMANDS_DIR"/*.md; do
            [[ -f "$cmd_file" ]] || continue
            base_name="${cmd_file##*/}"
            cmd_id="${base_name%.md}"
            content="---
description: Proxy for the ${cmd_id} workflow
globs: *
---

# Speckit Workflow: ${cmd_id}

When the user asks to run \`/${cmd_id}\`, you MUST read \`.specify/commands/${base_name}\` and follow its instructions exactly."
            
            write_idempotent "$CURSOR_RULES_DIR/speckit_${cmd_id}.mdc" "$content"
        done
    fi
    
    # Clean Orphans in .cursor/rules/
    for existing_file in "$CURSOR_RULES_DIR"/speckit_*.mdc; do
        [[ -f "$existing_file" ]] || continue
        # Extract original base_name from speckit_*.mdc
        filename="${existing_file##*/}"
        cmd_id="${filename#speckit_}"
        cmd_id="${cmd_id%.mdc}"
        base_name="${cmd_id}.md"
        
        if ! is_active_command "$base_name"; then
            rm -f "$existing_file"
        fi
    done
fi

# Step 4: Generate Files & Clean Orphans for All Other AI IDEs
# Dynamically find any hidden directory starting with '.' containing a 'workflows', 'commands', or 'prompts' subdirectory.

if [[ -d "$COMMANDS_DIR" ]]; then
    while IFS= read -r -d '' target_dir; do
        # Skip directories we already handle natively or ignore
        if [[ "$target_dir" == *".specify"* ]] || [[ "$target_dir" == *".cursor"* ]] || [[ "$target_dir" == *".agent"* ]] || [[ "$target_dir" == *".git/"* ]] || [[ "$target_dir" == *".github"* ]]; then
            continue
        fi
        
        # 1. Delete old broken symlinks for speckit files
        find "$target_dir" -type l -name "speckit*.md" -delete 2>/dev/null || true
        
        # 2. Generate proxy files
        for cmd_file in "$COMMANDS_DIR"/*.md; do
            [[ -f "$cmd_file" ]] || continue
            base_name="${cmd_file##*/}"
            content="---
description: Proxy for $base_name
---

## Execute Command

Please read \`.specify/commands/$base_name\` and execute its instructions exactly."
            
            write_idempotent "$target_dir/$base_name" "$content"
        done
        
        # 3. Clean Orphans in this directory
        for existing_file in "$target_dir"/speckit*.md "$target_dir"/snowdreamtech*.md; do
            [[ -f "$existing_file" ]] || continue
            base_name="${existing_file##*/}"
            if ! is_active_command "$base_name"; then
                rm -f "$existing_file"
            fi
        done
    done < <(find "$REPO_ROOT" -maxdepth 2 -type d \( -name "workflows" -o -name "commands" -o -name "prompts" \) -path "$REPO_ROOT/.*" -print0)
fi

# Step 5: Inject Global Pointers for other mainstream AI IDEs
ensure_global_pointer ".clinerules"
ensure_global_pointer ".roo-rules"
ensure_global_pointer ".windsurfrules"
ensure_global_pointer ".traerules"
ensure_global_pointer ".github/copilot-instructions.md"

echo -e "\033[0;32m✓ [Spec Kit] IDE adapters synchronized successfully.\033[0m"
exit 0
