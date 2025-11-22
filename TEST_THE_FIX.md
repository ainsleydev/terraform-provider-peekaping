# BREAKTHROUGH - Test The Fix!

## What I Found

The debug logs showed exactly what was happening:

**Element 0 (resource reference):**
- `config_unknown=true, plan_unknown=true` ✓ Works correctly!

**Element 1 & 2 (data source references with depends_on):**
- `config_null=true, plan_null=true` ✗ **BOTH NULL!**

Terraform Core bug #36653 was converting data source references to `null` (not `unknown`) BEFORE the provider even saw them.

## The Fix

Instead of just copying the null config to plan (which does nothing), the plan modifier now **actively converts null elements to unknown**.

When it detects both config and plan have null elements, it:
1. Creates a new list
2. Replaces `null` with `types.StringUnknown()`
3. Preserves already-unknown or known elements

## Test It

```bash
cd /home/user/terraform-provider-peekaping
git pull origin claude/continue-debugging-0131nYvyL9nB9WRfGwxVA7VM
go build -o terraform-provider-peekaping
terraform plan
```

## What You Should See

### BEFORE (broken):
```
+ tag_ids = [
    + (known after apply),
    + null,              ← WRONG!
    + null,              ← WRONG!
  ]
```

### AFTER (fixed):
```
+ tag_ids = [
    + (known after apply),
    + (known after apply),  ← FIXED!
    + (known after apply),  ← FIXED!
  ]
```

## Then Try Apply

```bash
terraform apply
```

It should complete successfully without the "Provider produced inconsistent final plan" error!

## Debug Logs to Verify

```bash
TF_LOG=WARN terraform plan 2>&1 | grep "MODIFIER ACTION"
```

You should see:
```
MODIFIER ACTION: Converting null elements to unknown (BUG #36653)
```

This confirms the modifier is actively fixing the nulls!
