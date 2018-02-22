.PHONY: install
MAKEFLAGS += --silent
install:
	cp "$(CURDIR)" "/opt/mkres" || { echo "Installation failed"; exit 1; }; \
	chmod 755 "/usr/local/bin" || { echo "Unable to set permissions"; exit 1; };\
	ln -s "/opt/mkres/mkres" "/usr/local/bin/mkres"
	echo "The mkres utility is now installed as $$(which mkres)"; \
	echo "To remove, run sudo make remove, or simply delete the file."
remove:
	rm "/usr/local/bin/mkres" || { echo "Could not uninstall mkres. Is it installed?"; exit 1; }; \
	echo "The mkres utility is now uninstalled"
