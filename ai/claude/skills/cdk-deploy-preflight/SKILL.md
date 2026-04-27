---
name: cdk-deploy-preflight
description: Use when running cdk deploy / cdk destroy / aws cloudformation delete-stack in AWS CDK projects. Also use when stacks are in ROLLBACK_COMPLETE / CREATE_FAILED / UPDATE_FAILED states, when redeploying after stack deletion, when refactoring CDK logical IDs, or when seeing AlreadyExists errors during deployment.
---

# CDK Deploy Preflight

## Overview

Verify CloudFormation stack state and orphaned resources before any CDK deployment.

**Why this exists:** Skipping these checks caused production CloudFront / Secrets Manager / OAC infrastructure to be destroyed during a redeploy attempt. CloudFormation rollback deleted live resources because the stack was in `ROLLBACK_COMPLETE` and the deploy proceeded anyway.

## When to Use

- Before any `cdk deploy` or `cdk destroy` command
- Before `aws cloudformation delete-stack`
- After CDK code refactor that changes resource logical IDs
- When seeing `AlreadyExists` errors during deployment
- When a stack is in any non-`COMPLETE` state

## Preflight Workflow

Execute these steps in order. **Stop and report to user if any check fails.**

### Step 1: Check CF stack status

```bash
aws cloudformation describe-stacks --stack-name <StackName> \
  --profile <profile> --query 'Stacks[0].StackStatus' --output text
```

If status is in the NG list below → **STOP**. Report to user with the stack status and proposed recovery. Do not proceed without explicit user approval.

| Status | Risk | Recovery |
|---|---|---|
| `ROLLBACK_COMPLETE` | Re-deploy may delete existing resources | `cdk import` or manual cleanup |
| `CREATE_FAILED` / `UPDATE_FAILED` | Failed change set persists | Check events → fix root cause |
| `UPDATE_ROLLBACK_FAILED` | Rollback also failed | Console "Continue Update Rollback" |
| `UPDATE_ROLLBACK_COMPLETE` | Previous deploy was rolled back | Verify cause before redeploy |

If the stack does not exist → first deploy or fully cleaned, proceed to step 2.

### Step 2: Check for orphaned resources

Resources with `RemovalPolicy: RETAIN`, or resources from CloudFront / OAC / Lambda@Edge, often survive stack deletion. CDK regenerates the same resource names on redeploy and collides with these orphans → `AlreadyExists`.

```bash
# If the stack still exists or was recently deleted
aws cloudformation list-stack-resources --stack-name <StackName> --profile <profile> \
  --query 'StackResourceSummaries[*].{Status:ResourceStatus,Type:ResourceType,Physical:PhysicalResourceId}' \
  --output table
```

`DELETE_SKIPPED` rows indicate AWS-side residue. For deleted stacks, also probe AWS directly for the bucket name pattern, CloudFront distributions tagged with the stack name, and Secrets Manager entries.

If orphans exist → see [references/orphan-recovery.md](references/orphan-recovery.md) for `cdk import` vs manual-delete decision and execution.

### Step 3: Review the diff

```bash
npx cdk diff <StackName> --profile <profile>
```

Pay particular attention to:
- `Replacement` indicators (resource recreated → name change → may break dependents)
- IAM policy changes
- Resource deletions

### Step 4: Confirm with user

Before invoking `cdk deploy`, present to user:
1. Current stack status (or "first deploy")
2. Orphan resource summary (if any) and chosen recovery path
3. Diff highlights
4. Blast radius / estimated time

Wait for explicit approval. Never auto-proceed.

## Common Failure Patterns

| Symptom | Root Cause | Recovery |
|---|---|---|
| `AlreadyExists` for OAC | Orphan OAC after stack delete; CloudFront still references it | references/orphan-recovery.md |
| Rollback deletes Secret | Secret had no `RemovalPolicy: RETAIN` | Recreate via redeploy; retrieve via `secretsmanager get-secret-value` |
| Bucket name collision | `RemovalPolicy.RETAIN` bucket survived | `cdk import` or empty + delete |
| `DELETE_FAILED` on bucket | Non-empty bucket with `RETAIN` | Empty bucket → re-attempt delete |

## Related Controls

- **Hook** `.claude/hooks/check-destructive-bash.sh` — last-resort safety net that blocks `cdk deploy` against `ROLLBACK_COMPLETE` stacks at command-execution time.
- **Rule** `.claude/rules/deployment.md` — concise CF state reference loaded when editing CDK source files.

This skill is the **active workflow**; the hook is the **passive safety net**. Do not skip the skill because the hook will catch it — the hook only fires after you have committed to a command. The skill prevents you from getting there.
