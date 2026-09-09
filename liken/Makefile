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

# The image, built the way the workflow builds it, tagged for a
# workstation. The context is the repository, because the Dockerfile
# compiles the tree it sits in.
image:
	docker build --file $(CURDIR)/Dockerfile --tag ghcr.io/liken-sh/corrosion:local $(CURDIR)/..

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
