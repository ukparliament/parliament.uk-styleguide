.PHONY: install clean serve build

# Common variables
SRC_FOLDER=src
PUBLIC_FOLDER=_public
JAVASCRIPTS_LOC=src/javascripts
STYLESHEETS_LOC=src/stylesheets
IMAGES_LOC=src/images
REPORTS_FOLDER=reports

# Node module variables
NODE_MODULES=./node_modules
PUGIN=$(NODE_MODULES)/parliamentuk-pugin
ESLINT=$(PUGIN)/node_modules/.bin/eslint
NODE_SASS=$(PUGIN)/node_modules/.bin/node-sass
POSTCSS=$(PUGIN)/node_modules/.bin/postcss
UGLIFY_JS=$(PUGIN)/node_modules/.bin/uglifyjs
IMAGEMIN=$(PUGIN)/node_modules/.bin/imagemin
ONCHANGE=$(PUGIN)/node_modules/.bin/onchange
PUG=$(PUGIN)/node_modules/.bin/pug

# AWS S3 bucket to deploy to
# TODO: move "pdswebops" to an environment variable that GoCD will pickup
S3_BUCKET = s3://ukpds.pugin-website

# Installs npm packages
install:
	@npm i
	make install -C $(PUGIN)

# Deletes the public folder
clean:
	@rm -rf $(PUBLIC_FOLDER)

# Runs tests on javascript files
lint:
	@$(ESLINT) $(JAVASCRIPTS_LOC)

# Compiles sass to css
css:
	@mkdir -p $(PUBLIC_FOLDER)/stylesheets
	@$(NODE_SASS) --output-style compressed -o $(PUBLIC_FOLDER)/stylesheets $(PUGIN)/$(STYLESHEETS_LOC)
	@$(NODE_SASS) --output-style compressed -o $(PUBLIC_FOLDER)/stylesheets $(STYLESHEETS_LOC)
	@$(POSTCSS) -u autoprefixer -r $(PUBLIC_FOLDER)/stylesheets/*

# Minifies javascript files
js:
	@mkdir -p $(PUBLIC_FOLDER)/javascripts
	@$(UGLIFY_JS) $(PUGIN)/$(JAVASCRIPTS_LOC)/*.js -m -o $(PUBLIC_FOLDER)/javascripts/main.js
	@$(UGLIFY_JS) $(JAVASCRIPTS_LOC)/*.js -m -o $(PUBLIC_FOLDER)/javascripts/overrides.js

# Minifies images
images:
	@$(IMAGEMIN) $(PUGIN)/$(IMAGES_LOC)/* -o $(PUBLIC_FOLDER)/images
	@$(IMAGEMIN) $(IMAGES_LOC)/* -o $(PUBLIC_FOLDER)/images

# Outputs pug files to html within public folder
templates:
	@$(PUG) $(SRC_FOLDER)/templates -P --out $(PUBLIC_FOLDER)/templates

# Launches a local server
serve: clean build
	@node server.js

# Watches project files for changes
watch:
	@node $(PUGIN)/scripts/watch.js $(STYLESHEETS_LOC)=css $(JAVASCRIPTS_LOC)=js $(IMAGES_LOC)=images $(SRC_FOLDER)/layouts=templates $(SRC_FOLDER)/elements=templates $(SRC_FOLDER)/components=templates $(SRC_FOLDER)/templates=templates

# Runs accessibility testing
test:
	@mkdir -p $(REPORTS_FOLDER)
	@rm -rf $(REPORTS_FOLDER)/*
	@node $(PUGIN)/scripts/pa11y.js

# Builds application
build: lint css js images templates

deploytos3: build
#	aws s3 cp --acl=public-read ./index.html $(S3_BUCKET)
