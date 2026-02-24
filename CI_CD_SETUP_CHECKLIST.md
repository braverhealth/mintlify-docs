# CI/CD Setup Checklist

This document contains all configuration steps required to enable the automated CI/CD and scheduled workflows for the Braver platform.

## Quick Reference

| Workflow Type | Frequency | Purpose |
|---------------|-----------|---------|
| Scheduled AI Fixes | Tue/Thu | Auto-fix widgetbook, docs, semantics |
| Widgetbook CD | On push/PR | Deploy widgetbook to Netlify |
| Documentation CD | On push/PR | Validate and deploy docs via Mintlify |

---

## 1. GitHub Secrets

Navigate to: **Repository Settings → Secrets and variables → Actions → Secrets**

### Required Secrets

- [ ] **`AUGMENT_SESSION_AUTH`**
  - **Purpose:** Authentication for Augment AI agent in scheduled workflows
  - **How to get:** Contact Augment Code team or retrieve from Augment dashboard
  - **Used by:**
    - `scheduled-widgetbook-use-cases.yaml`
    - `scheduled-flutter-ui-docs.yaml`
    - `scheduled-fix-semantics.yaml`

- [ ] **`NETLIFY_DEPLOY_TOKEN`** *(likely already configured)*
  - **Purpose:** Deploy to Netlify
  - **How to get:** Netlify dashboard → User settings → Applications → Personal access tokens
  - **Used by:**
    - `cd-widgetbook.yaml`
    - All other Netlify deployment workflows

---

## 2. Netlify Configuration

### Widgetbook Site

- [ ] **Create Netlify site for Widgetbook**
  1. Go to [Netlify Dashboard](https://app.netlify.com)
  2. Click "Add new site" → "Deploy manually" (we deploy via GitHub Actions)
  3. Name the site (e.g., `braver-widgetbook`)
  4. Copy the **Site ID** from Site settings → General → Site details

- [ ] **Update workflow with Site ID**
  - File: `.github/workflows/cd-widgetbook.yaml`
  - Replace `NETLIFY_SITE_ID_PLACEHOLDER` with the actual Site ID (2 places)
  
  ```yaml
  # Line ~43 and ~53
  netlify_project: your-actual-site-id-here
  ```

- [ ] **Configure custom domain** (optional)
  - Netlify → Site settings → Domain management
  - Add custom domain: `widgetbook.braver.health`

---

## 3. Mintlify Documentation

- [ ] **Connect repository to Mintlify**
  1. Go to [Mintlify Dashboard](https://mintlify.com/dashboard)
  2. Click "Add documentation"
  3. Connect the `braverhealth/platform` repository
  4. Set source path: `dart/libraries/flutter_ui/docs`
  5. Configure deployment branch: `main`

- [ ] **Configure custom domain** (optional)
  - Mintlify dashboard → Settings → Custom domain
  - Add domain: `docs.braver.health` (or similar)

---

## 4. Verification Checklist

### Test Scheduled Workflows

Each workflow can be manually triggered for testing:

- [ ] **Test Widgetbook Use Cases workflow**
  ```
  GitHub → Actions → "Scheduled Widgetbook Use Cases Update" → Run workflow
  ```

- [ ] **Test Flutter UI Docs workflow**
  ```
  GitHub → Actions → "Scheduled Flutter UI Documentation Update" → Run workflow
  ```

- [ ] **Test Semantics Fix workflow**
  ```
  GitHub → Actions → "Scheduled Semantic Labels & Debug Keys Fix" → Run workflow
  ```

### Test CD Workflows

- [ ] **Test Widgetbook CD**
  - Create a PR with changes to `dart/apps/widgetbook/`
  - Verify preview deployment comment appears on PR
  - Merge PR and verify production deployment

- [ ] **Test Documentation CD**
  - Create a PR with changes to `dart/libraries/flutter_ui/docs/`
  - Verify validation comment appears on PR
  - Merge PR and verify Mintlify auto-deploys

---

## 5. Workflow Schedule Reference

All scheduled workflows run on **Tuesdays and Thursdays** at staggered times (UTC):

| Time (UTC) | Workflow | Branch Prefix |
|------------|----------|---------------|
| 10:00 | Widgetbook Use Cases | `auggie-ui-fix/widgetbook-use-cases` |
| 11:00 | Flutter UI Docs | `auggie-ui-fix/flutter-ui-docs` |
| 12:00 | Semantic Labels & Keys | `auggie-ui-fix/semantics` |

---

## 6. CLI Commands Available

These commands can be run locally (no CI setup required):

```bash
# Fix semantic labels and debug keys
braver ai:fix-semantics [files...]

# Fix design token violations
braver ai:fix-design-tokens [files...]

# Extract reusable widgets
braver ai:fix-ui-refactor [files...]

# Generate widgetbook use cases
braver ai:fix-widgetbook-use-cases [files...]

# Update flutter_ui documentation
braver ai:fix-flutter-ui-docs [files...]
```

**Common options:**
- `--print` - Print output instead of writing files
- `--quiet` - Only show final assistant message
- `--base-branch <branch>` - Diff against specified branch to find changed files

---

## 7. Files Reference

### Workflow Files

| File | Purpose |
|------|---------|
| `.github/workflows/reusable-auggie-fix.yaml` | Shared template for all scheduled AI fixes |
| `.github/workflows/scheduled-widgetbook-use-cases.yaml` | Auto-generate widgetbook use cases |
| `.github/workflows/scheduled-flutter-ui-docs.yaml` | Auto-update documentation |
| `.github/workflows/scheduled-fix-semantics.yaml` | Auto-fix semantic labels |
| `.github/workflows/cd-widgetbook.yaml` | Deploy widgetbook to Netlify |
| `.github/workflows/cd-flutter-ui-docs.yaml` | Validate and deploy documentation |

### Instruction Files

| File | Purpose |
|------|---------|
| `dart/libraries/flutter_ui/WIDGETBOOK_USE_CASES_INSTRUCTIONS.md` | Guide for creating widgetbook use cases |
| `dart/libraries/flutter_ui/DOCS_UPDATE_INSTRUCTIONS.md` | Guide for updating documentation |
| `dart/libraries/flutter_domain_ui/FIX_SEMANTICS_INSTRUCTIONS.md` | Guide for semantic labels/keys |
| `dart/libraries/flutter_ui/FIX_DESIGN_TOKENS_INSTRUCTIONS.md` | Guide for design token fixes |
| `dart/libraries/flutter_ui/UI_REFACTOR_INSTRUCTIONS.md` | Guide for widget extraction |
| `dart/libraries/flutter_ui/CHECK_DESIGN_TOKENS_INSTRUCTIONS.md` | Design token detection rules |

---

## 8. Troubleshooting

### Scheduled workflow not creating PRs

1. Check `AUGMENT_SESSION_AUTH` secret is configured
2. Verify workflow ran: Actions → Select workflow → Check run history
3. Check if there were relevant file changes since last merged PR

### Widgetbook deployment failing

1. Verify `NETLIFY_DEPLOY_TOKEN` secret exists
2. Verify Site ID is correctly set in workflow (not placeholder)
3. Check build logs for Flutter/Dart errors

### Documentation validation failing

1. Run locally: `cd dart/libraries/flutter_ui/docs && npx mintlify validate`
2. Check for missing pages referenced in `mint.json`
3. Verify MDX syntax is valid

### Preview comments not appearing on PRs

1. Verify workflow has `write` permission for issues/PRs
2. Check Actions logs for GitHub API errors
3. Ensure `GITHUB_TOKEN` has sufficient permissions

---

## 9. Maintenance

### Updating Augment AI

When Augment releases a new version of the GitHub Action:

```yaml
# In reusable-auggie-fix.yaml, update:
uses: augmentcode/augment-agent@v0.1.3  # ← Update version
```

### Adding New Scheduled AI Fixes

1. Create instruction file: `YOUR_INSTRUCTIONS.md`
2. Create caller workflow using the reusable template:

```yaml
name: Scheduled Your Fix

on:
  schedule:
    - cron: "0 13 * * 2,4"  # Pick a time slot
  workflow_dispatch:

jobs:
  your-fix:
    uses: ./.github/workflows/reusable-auggie-fix.yaml
    with:
      branch_name: auggie-ui-fix/your-fix
      target_paths: "dart/path/to/monitor"
      instruction_file: path/to/YOUR_INSTRUCTIONS.md
      pr_title: "fix: your fix description"
      pr_emoji: "🔧"
    secrets:
      AUGMENT_SESSION_AUTH: ${{ secrets.AUGMENT_SESSION_AUTH }}
```

