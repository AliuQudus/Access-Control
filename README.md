# Access Manager for Business Central — v1 Scaffold

A plain-language admin tool for assigning, per user: which companies they can
open, which curated "Access Bundle" of permission sets applies in each
company, and which role center they land on. It wraps the native
`Access Control` and `User Personalization` tables rather than replacing
BC's security engine.

## What's in this scaffold

| Object | Purpose |
|---|---|
| `table 50100 "Access Bundle"` | A named group of permission sets (e.g. "Sales Only") |
| `table 50101 "Access Bundle Line"` | The permission sets inside a bundle |
| `table 50102 "User Access Header"` | One row per user: role center + summary |
| `table 50103 "User Access Line"` | Company + bundle pairs for a user |
| `table 50104 "Managed Access Entry"` | Internal bookkeeping: exactly which `Access Control` rows this tool created |
| `codeunit 50100 "Access Sync Mgt."` | Diffs desired state against `Access Control`, grants/revokes accordingly, sets role center |
| `page 50100/50110/50101` | Access Bundle list, card, and lines |
| `page 50102/50112/50103` | User Access list, card, and lines — this is the "list part" from the original ask |
| `page 50104 "Effective Access Overview"` | Read-only view of native `Access Control`, flags which rows this tool manages |
| `permissionset 50100 "ACCESS MGR ADMIN"` | Assign this to whoever administers the tool itself |

## Design decisions baked into v1 (per our discussion)

- **Bundles wrap existing Permission Sets** (System or Tenant scope) rather
  than letting admins hand-pick individual pages/tables. This avoids the
  "page needs its underlying tables too" dependency problem — you're reusing
  permission sets that are already correctly scoped.
- **Per-company bundles**: a user can have a different bundle in each
  company, matching how `Access Control` already works natively.
- **No silent lockdown on install.** Sync only ever touches rows this tool
  created (tracked in `Managed Access Entry`) and only runs when an admin
  explicitly hits "Synchronize." A "lock every existing user down to
  assigned-only access" action is a deliberate v2 feature with its own
  confirmation/preview step — doing this automatically on install is a good
  way to lock an admin out and get the app pulled from AppSource.
- **SUPER / license-based default permission sets are NOT handled yet.** If
  a user has `SUPER` (directly, via a User Group, or via Microsoft 365
  Global Admin sync) or a plan-based default permission set, that access
  stacks on top of whatever this tool grants — permissions in BC are always
  additive. Detecting and flagging this is planned for v2.

## Before you compile

1. **Replace the placeholder GUID and publisher** in `app.json` with your
   own (`id`, `publisher`). Generate a fresh GUID — don't reuse the one in
   this scaffold.
2. **Confirm your object ID range.** 50100–50149 is used here as a
   per-tenant-extension placeholder range. If you're publishing to AppSource
   you'll need a range assigned via Partner Center instead.
3. **Verify these platform object/field names against your target BC
   version's symbols** — they're stable but names/keys can shift slightly
   release to release:
   - `Aggregate Permission Set` (table) — unions System + Tenant permission
     sets for the lookup on `Access Bundle Line."Permission Set ID"`.
   - `All Profile` (table) — unions System + Tenant role center profiles.
   - `Access Control` — check the exact primary key field order before
     relying on the positional `Get()` call in
     `Access Sync Mgt.RevokeAccessControl`. If it doesn't match, switch to
     `SetRange` + `FindFirst` (more verbose but order-independent).
   - `User Personalization` — field names `Profile ID` / `App ID` /
     `User SID` should match, but double check on your version.
4. **Download symbols** in VS Code (`AL: Download Symbols`) before your
   first compile, then build (`Ctrl+Shift+B`).

## Suggested first test

1. Publish to a sandbox.
2. Assign yourself the `ACCESS MGR ADMIN` permission set (plus enough native
   access to not lock yourself out while testing).
3. Create one `Access Bundle` wrapping a narrow native permission set (e.g.
   something read-only) so mistakes are low-risk.
4. Create a `User Access Header` for a throwaway test user, add one line
   (a non-production company + your test bundle), hit **Synchronize Access**,
   then check `Effective Access Overview` to confirm the row appeared and is
   flagged as "Managed by Access Manager."
5. Remove the line, sync again, confirm the row disappears from
   `Access Control`.

## v1.1 addition: Object lines (pick a Page or Table directly)

Each `Access Bundle Line` now has a **Line Type**:
- **Permission Set** (original v1 behavior) — wraps an existing native/tenant permission set as-is.
- **Object** — the admin picks a specific Table or Page ID directly, with simple
  Allow View / Insert / Modify / Delete checkboxes, no permission-set vocabulary
  required.

Under the hood, every Object-type line in a group gets compiled into a single
`Tenant Permission Set` + `Tenant Permission` rows that this tool owns exclusively
(`App ID` = this extension, `Role ID` = the group's Code). That generated set is
then granted via `Access Control` exactly like any wrapped permission set — the
sync logic and `Managed Access Entry` bookkeeping don't need to know the
difference.

**Important limitation, by design, not oversight:** picking a Page does *not*
automatically grant its underlying table(s). There is no reliable, verified AL
API used in this scaffold for resolving "what tables does this page depend on" —
guessing at one risks silently wrong access, which is worse than requiring a
manual step. If an admin adds a Page object line, the UI tooltip reminds them to
also add the relevant Table object line(s) (or start the group from a tested
Microsoft permission set and patch it with Object lines only where something
specific is missing). This mirrors the same "page needs its tables too" issue
flagged in the original permission-set design and is the main thing to test
carefully before rolling a group out to real users.

**Also worth knowing:** the `Tenant Permission` platform table initializes all
five permission fields (`Read`, `Insert`, `Modify`, `Delete`, `Execute`) to `Yes`
by default (`InitValue = Yes` on the real symbol). `EnsureGroupPermissionSet`
explicitly blanks the ones that shouldn't be granted rather than relying on
leaving them untouched — if you ever extend this logic, don't skip that step.

Use the **Rebuild Generated Permission Set** action on the Access Group Card to
compile Object-type lines immediately, without waiting for a user sync — handy
for spot-checking a group's real effective permissions via `Effective
Permissions` (native) before assigning it to anyone.


- Opt-in "lock down all existing users to assigned-only access," with a
  preview of what will change before committing.
- Detection/flagging of `SUPER`, Global-Admin-sync grants, and license-plan
  default permission sets that bypass this tool entirely.
- Building bundles from individual pages/objects rather than only wrapping
  existing permission sets.
- Bulk import/export of assignments.
