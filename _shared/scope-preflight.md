# Scope Pre-flight — Shared Protocol

Used by skills that perform bulk file edits. Read this file when you are about to modify multiple files or take an action whose blast radius is unclear from the user's request.

## Trigger

Run this gate when **either** condition holds:
- The proposed change touches **3 or more files**.
- The user request matches one of the verbs: `audit`, `refactor`, `normalize`, `sweep`, `propagate`, `extract`, `rename`.

## File-list confirmation

Before editing, present the proposed file list:

> I'm about to modify N files:
> - `<path 1>`
> - `<path 2>`
> - ...
>
> Proceed?

Wait for explicit user confirmation. Partial feedback or silence is not approval.

## Refusal

If the user does not confirm, do not edit any of the listed files. Reply:

> Holding off — please clarify which files are in scope.

Re-prompt with a narrowed list when the user provides scope.
