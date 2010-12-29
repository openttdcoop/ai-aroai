# Configuration
AI_NAME = AroAI
AI_VERSION = 1.1.1(r96)
# End of configuration

FILES = COPYING *.nut *.txt
NAME_VERSION = $(AI_NAME)-$(AI_VERSION)
TAR_NAME = $(NAME_VERSION).tar

all: 	Makefile $(FILES)
	@echo "Packaging $(NAME_VERSION)..."
	@mkdir "$(AI_NAME)"
	@cp $(FILES) "$(AI_NAME)"
	@tar -cf "$(TAR_NAME)" "$(AI_NAME)"
	@rm -r "$(AI_NAME)"
	@echo "Done!"
