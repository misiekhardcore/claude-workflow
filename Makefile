.PHONY: changelog

changelog:
	sed -i '/^## \[Unreleased\]/,/^## \[/{/^## \[Unreleased\]/d;/^## \[/!d}' CHANGELOG.md
	npx git-cliff --unreleased --prepend CHANGELOG.md
