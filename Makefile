install:
	fish -c "fisher install ./"

dependencies:
	fish -c "fisher install jorgebucaran/fishtape"

generate:
	fish generate.fish

test:
	fish -c "fishtape tests/*.fish"
