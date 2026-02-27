# Planning Files Management

This directory tracks planning-with-files (PWF) artifacts for SRED R&D documentation and knowledge transfer.

## Purpose

PWF files capture the exploration, decision-making, and learning process during complex tasks. These artifacts are valuable for:
- SRED claims documentation
- Knowledge transfer to downstream projects
- Understanding the evolution of approaches
- Learning from past explorations

## Directory Structure

```
planning/
  active/           ← Current work-in-progress PWF files
    task_plan.md
    findings.md
    progress.md
  archive/          ← Completed issues, preserved for reference
    YYYY-MM-issue-N-description/
      task_plan.md
      findings.md
      progress.md
      README.md     (optional: outcome summary)
```

## Workflow

### Starting New Issue Work

```bash
# In your worktree
cd planning/active

# Create fresh PWF files or resume existing
# - task_plan.md: Goals, milestones, phased tasks
# - findings.md: Technical analysis, discoveries
# - progress.md: Session log with commits
```

### Completing Issue Work

```bash
# Archive the planning files with descriptive name
mv planning/active planning/archive/YYYY-MM-issue-N-description

# Optional: Add outcome README
cat > planning/archive/YYYY-MM-issue-N-description/README.md << 'EOF'
## Outcome
Brief summary of what was accomplished and key learnings.

Closed by: #PR-number
EOF

# Commit the archive
git add planning/archive/YYYY-MM-issue-N-description
git commit -m "Archive planning files for issue #N"

# Update CLAUDE.md with key learnings (consolidated knowledge)
# Create fresh active/ for next issue
mkdir -p planning/active
```

### Working in Multiple Worktrees

Each worktree branch has its own `planning/active/` state:

```bash
# Worktree 1 (issue #13)
~/repo/example-repo-wt-13/planning/active/
  ← PWF files for issue #13 work

# Worktree 2 (issue #14)
~/repo/example-repo-wt-14/planning/active/
  ← PWF files for issue #14 work (different branch)
```

When both branches merge to main, their archives coexist:
```
planning/archive/
  2026-01-issue-13-interpolation/
  2026-01-issue-14-arrow-lakes/
```

## CLAUDE.md vs PWF Files

**CLAUDE.md** (repo root):
- Stable, committed knowledge base
- Project-wide patterns and context
- Reference documentation
- Merged frequently from main to feature branches

**PWF files** (planning/active/):
- Ephemeral exploration and decision-making
- Issue-specific planning state
- Raw research notes
- Archived when issue completes, key learnings → CLAUDE.md

## Searching Archived Planning

```bash
# Find all mentions of "quadratic" across planning history
rg "quadratic" planning/

# View planning for specific issue
ls planning/archive/2026-01-issue-13-*/

# Compare approaches across issues
diff planning/archive/2026-01-issue-9-*/findings.md \
     planning/archive/2026-01-issue-13-*/findings.md
```

## For SRED Claims

Reference archived planning directories in SRED documentation:
```
See planning/archive/YYYY-MM-issue-N-description/ for:
- Exploration of [technical uncertainty]
- Comparison of [approach A] vs [approach B]
- Decision rationale for implementation approach
```

## Git History

Archived planning files are committed, providing full history:
```bash
# See evolution of archived planning
git log -- planning/archive/YYYY-MM-issue-N-description/

# View planning at specific point in time
git show abc123:planning/archive/YYYY-MM-issue-N-description/findings.md
```
