NAME=draft-muffett-same-origin-onion-certificates

$(NAME).txt: $(NAME).xml
	xml2rfc --text --v3 $(NAME).xml

$(NAME).xml: $(NAME).md
	mmark $(NAME).md >$(NAME).xml
