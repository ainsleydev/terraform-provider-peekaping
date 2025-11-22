# Debug Test Instructions

## Prerequisites
1. Make sure you have the Production and WebKit tags already created in your Peekaping account
2. Set your API key: `export PEEKAPING_API_KEY="your-api-key"`

## Build and Test

### 1. Build the provider
```bash
go build -o terraform-provider-peekaping
```

### 2. Install locally (choose your OS)

**Linux/Mac:**
```bash
# Create local plugin directory
mkdir -p ~/.terraform.d/plugins/registry.terraform.io/tafaust/peekaping/99.0.0/linux_amd64/

# Copy the binary
cp terraform-provider-peekaping ~/.terraform.d/plugins/registry.terraform.io/tafaust/peekaping/99.0.0/linux_amd64/terraform-provider-peekaping_v99.0.0
```

**Or use dev_overrides** (easier):
Create `~/.terraformrc`:
```hcl
provider_installation {
  dev_overrides {
    "tafaust/peekaping" = "/home/user/terraform-provider-peekaping"
  }
  direct {}
}
```

### 3. Initialize Terraform
```bash
cd /home/user/terraform-provider-peekaping
terraform init
```

### 4. Run plan with DEBUG logging
```bash
TF_LOG=DEBUG terraform plan 2>&1 | tee plan_debug.log
```

### 5. Filter for our plan modifier logs
```bash
# See if the plan modifier is being called
grep -E "(Examining list elements|Element state|Config is null|Plan is null|Preserving unknown|Detected null)" plan_debug.log

# See all tag_ids related logs
grep -i "tag_ids" plan_debug.log | head -50

# See the actual plan modifier execution
grep -A 10 "preserveUnknownFromConfigModifier" plan_debug.log
```

## What to Look For

### Expected Plan Output (BROKEN):
```
tag_ids = [
    "16936f2f-...",  # Known
  + null,            # ← WRONG! Should be (known after apply)
  + null,            # ← WRONG! Should be (known after apply)
]
```

### What We Need From Debug Logs:

**Question 1:** Is the plan modifier being called?
- Look for: "Examining list elements"
- If YES → Go to Question 2
- If NO → The modifier isn't registered properly

**Question 2:** What does ConfigValue contain?
- Look for: "Element state" logs with index 0, 1, 2
- Check if `config_unknown: true` or `config_null: true`

**Question 3:** What does PlanValue contain?
- Look for same logs
- Check if `plan_unknown: true` or `plan_null: true`

## Share These Results

Please share:
1. The plan output (what does tag_ids show?)
2. The grep results from step 5 above
3. Any WARNING logs from the modifier

Example command to get everything we need:
```bash
echo "=== PLAN OUTPUT ==="
terraform plan 2>&1 | grep -A 5 "tag_ids"

echo -e "\n=== MODIFIER LOGS ==="
TF_LOG=DEBUG terraform plan 2>&1 | grep -E "(Examining list elements|Element state|Preserving unknown|Detected null)"

echo -e "\n=== CONFIG/PLAN STATE ==="
TF_LOG=DEBUG terraform plan 2>&1 | grep "Element state"
```

## Cleanup
```bash
# Remove test resources if created
terraform destroy

# Remove test files
rm test.tf DEBUG_TEST.md
```
