# Configuration
AI_NAME = AroAI
AI_VERSION = 1.1.0(r72)
# End of configuration

FILES = *.nut *.txt 
FILES2 = COPYING *.nut *.txt
NAME_VERSION = $(AI_NAME)-$(AI_VERSION)
TAR_NAME = $(NAME_VERSION).tar
TAR_NAME2 = $(NAME_VERSION)f.tar

all: bananas forum

bananas: Makefile $(FILES)
	@mkdir "$(AI_NAME)"
	@cp $(FILES) "$(AI_NAME)"
	@tar -cf "$(TAR_NAME)" "$(AI_NAME)"
	@rm -r "$(AI_NAME)"
	
forum:  Makefile $(FILES2)
	@mkdir "$(AI_NAME)"
	@cp $(FILES2) "$(AI_NAME)"
	@tar -cf "$(TAR_NAME2)" "$(AI_NAME)"
	@rm -r "$(AI_NAME)"
