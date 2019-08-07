NAME=draft-muffett-same-origin-onion-certificates

all: $(NAME).txt $(NAME).html

$(NAME).html: $(NAME).xml
	xml2rfc --html --v3 $(NAME).xml

$(NAME).txt: $(NAME).xml
	xml2rfc --text --v3 $(NAME).xml

$(NAME).xml: $(NAME).md
	mmark $(NAME).md >$(NAME).xml

clean:
	rm -f *~
