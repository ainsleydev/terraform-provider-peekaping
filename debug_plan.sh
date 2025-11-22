#!/bin/bash
set -e

echo "Building provider..."
go build -o terraform-provider-peekaping

echo ""
echo "Running terraform plan with DEBUG logging..."
echo "Looking for PLAN MODIFIER logs..."
echo ""

TF_LOG=WARN terraform plan 2>&1 | grep -E "(===== PLAN MODIFIER|ELEMENT STATE|MODIFIER ACTION)" || echo "NO MODIFIER LOGS FOUND!"

echo ""
echo "=========================="
echo "Full plan output:"
echo "=========================="
terraform plan 2>&1 | grep -A 15 "peekaping_monitor.test"
