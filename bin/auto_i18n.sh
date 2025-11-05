#!/bin/bash
set -e
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Auto I18n Pipeline                                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

DRY_RUN=""
[[ "$1" == "--dry-run" ]] && DRY_RUN="--dry-run" && echo "🔍 DRY RUN MODE\n"

echo "📝 Step 1/3: Extracting..."
lua bin/extract_hardcoded_text.lua
echo ""

echo "🤖 Step 2/3: Translating..."
lua bin/auto_translate.lua
echo ""

echo "🔧 Step 3/3: Applying..."
lua bin/apply_translations.lua $DRY_RUN

if [ -z "$DRY_RUN" ]; then
    echo "📦 Committing..."
    git add .auto-i18n-cache/ && git commit -m "chore: Auto-i18n cache" || true
    git add views/ static/ && git commit -m "feat: Apply auto-translations" || true
    git add locales/ && git commit -m "feat: Update locales" || true
    echo ""
    echo "✅ Committed to branch: $(git branch --show-current)"
    echo ""
    git log --oneline -3
fi

echo ""
echo "Next: Review changes and push"
echo ""
