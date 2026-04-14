.PHONY: test

test:
	@failed=0; \
	for f in tests/*/test_*.sh; do \
		echo "=== $$f ==="; \
		if bash "$$f"; then :; else failed=1; fi; \
		echo; \
	done; \
	if [ $$failed -eq 0 ]; then echo "All tests passed."; else echo "Some tests failed."; fi; \
	exit $$failed
