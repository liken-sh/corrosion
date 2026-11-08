# The fork's chores, each one command. liken/README.md explains the
# branches these act on. Run them from anywhere: `make -C liken sync`.

.PHONY: sync image release

# Bring main level with upstream and rebase the stack onto it. The
# push of liken rewrites history, which is the one place in the liken
# organization that does; --force-with-lease refuses when someone
# else pushed to liken since the last fetch.
sync:
	git fetch upstream main
	git push origin upstream/main:main
	git rebase main liken
	git push --force-with-lease origin liken

# The image, built from the same bake target that the workflow builds,
# for this machine's platform and tagged :local. The bake file is at
# the repository's root, which is also the build context.
image:
	cd $(CURDIR)/.. && docker buildx bake --load corrosion

# Tag today's next serial and push it, which is the release. The
# serial counts the tags that already carry today's date, so two
# releases in one day are -001 and -002.
release:
	@test "$$(git branch --show-current)" = liken || { echo "release only from the liken branch"; exit 1; }
	@day=$$(date -u +%Y.%m.%d); \
	last=$$(git tag --list "$$day-*" | sort | tail -1); \
	serial=$$(printf '%03d' $$(( $${last##*-} + 1 ))); \
	tag="$$day-$$serial"; \
	git tag "$$tag" && git push origin "$$tag" && echo "released $$tag"
