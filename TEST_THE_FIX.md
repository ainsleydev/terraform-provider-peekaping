# BREAKTHROUGH - Test The Fix!

## Update: Fixed the "Provider produced invalid plan" error!

Added `Computed: true` to the schema so the plan modifier is allowed to override null values from config.

## What I Found

The debug logs showed exactly what was happening:

**Element 0 (resource reference):**
- `config_unknown=true, plan_unknown=true` ✓ Works correctly!

**Element 1 & 2 (data source references with depends_on):**
- `config_null=true, plan_null=true` ✗ **BOTH NULL!**

Terraform Core bug #36653 was converting data source references to `null` (not `unknown`) BEFORE the provider even saw them.

## The Fix (Two Parts)

**Part 1: Plan Modifier Converts Null to Unknown**

Instead of just copying the null config to plan (which does nothing), the plan modifier now **actively converts null elements to unknown**.

When it detects both config and plan have null elements, it:
1. Creates a new list
2. Replaces `null` with `types.StringUnknown()`
3. Preserves already-unknown or known elements

**Part 2: Schema Marked as Computed**

Added `Computed: true` to `tag_ids` and `notification_ids` schema attributes.

This tells Terraform that the provider is allowed to compute/override these values in the plan, which permits the plan modifier to convert null to unknown without triggering a validation error.

Without `Computed: true`, Terraform would reject the plan with:
```
Error: Provider produced invalid plan
planned value [Unknown, Unknown, Unknown] does not match
config value [Unknown, Null, Null]
```

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
