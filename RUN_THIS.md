# DEBUG INSTRUCTIONS

I've added comprehensive logging to understand why the plan modifier isn't working.

## Run this command:

```bash
./debug_plan.sh
```

This will:
1. Build the provider
2. Run `terraform plan` with WARN-level logging
3. Show ONLY the plan modifier logs (if any)
4. Show the plan output for the monitor resource

## What I need to see:

**If you see modifier logs:**
- When is it called?
- What are the element states (null/unknown)?
- What action does it take?

**If you see NO modifier logs:**
- The modifier isn't being called at all
- This means there's a problem with how it's registered

## Alternative - full debug log:

If the script doesn't work or you want to see everything:

```bash
go build -o terraform-provider-peekaping
TF_LOG=WARN terraform plan 2>&1 | tee full_debug.log
grep "PLAN MODIFIER" full_debug.log
grep "ELEMENT STATE" full_debug.log
grep "MODIFIER ACTION" full_debug.log
```

Share the output with me!
