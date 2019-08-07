NAME=draft-muffett-same-origin-onion-certificates
DIR=text

all: $(DIR)/$(NAME).txt $(DIR)/$(NAME).html

$(DIR)/$(NAME).html: $(DIR)/$(NAME).xml
	( cd $(DIR) && xml2rfc --html --v3 $(NAME).xml )

$(DIR)/$(NAME).txt: $(DIR)/$(NAME).xml
	( cd $(DIR) && xml2rfc --text --v3 $(NAME).xml )

$(DIR)/$(NAME).xml: $(NAME).md
	mmark -markdown $(NAME).md >$(DIR)/$(NAME).basic.md
	mmark -html $(NAME).md >$(DIR)/$(NAME).basic.html
	mmark $(NAME).md >$(DIR)/$(NAME).xml

clean:
	rm -f *~
	rm $(DIR)/*
