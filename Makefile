BUILD_BACKGROUND_TRANSPARENT := transparent
BUILD_OUTPUT_DIR := ./build
FILENAME_SEPERATOR := _
IMAGE_OUTPUT_FILE_PREFIX := naho_logo
IMAGE_RESOLUTIONS := 256
JPG_EXTENSION := jpg
PNG_EXTENSION := png
SVG_FILE_PATH := ./src/logo.svg

# https://imagemagick.org/script/color.php
BUILD_BACKGROUND_COLORS := $(BUILD_BACKGROUND_TRANSPARENT) \
						   aqua \
						   black \
						   blue \
						   fuchsia \
						   gray \
						   green \
						   lime \
						   maroon \
						   navy \
						   olive \
						   purple \
						   red \
						   silver \
						   teal \
						   white \
						   yellow \

.PHONY: all

all: build-images

# Build optimized images in parallel.
build-images: build-svg build-jpg-png

# Build optimized JPG and PNG images in parallel.
build-jpg-png: delete-build-directory create-build-directory
	parallel \
		--halt now,fail=1 \
		' \
			[ {5} = "$(BUILD_BACKGROUND_TRANSPARENT)" ] && \
			[ {6} = "$(JPG_EXTENSION)" ] && \
			exit 0; \
			image_file_path="{2}/{3}$(FILENAME_SEPERATOR){5}$(FILENAME_SEPERATOR){4}x{4}.{6}"; \
			convert \
			-background "{5}" \
			-resize "{4}x" \
			"{1}" \
			"$$image_file_path" && \
			{ \
				if [ {6} = "$(JPG_EXTENSION)" ]; then \
					jpegoptim "$$image_file_path"; \
				elif [ {6} = "$(PNG_EXTENSION)" ]; then \
					optipng "$$image_file_path"; \
				fi \
			} \
		' \
		::: $(SVG_FILE_PATH) \
		::: $(BUILD_OUTPUT_DIR) \
		::: $(IMAGE_OUTPUT_FILE_PREFIX) \
		::: $(IMAGE_RESOLUTIONS) \
		::: $(BUILD_BACKGROUND_COLORS) \
		::: $(JPG_EXTENSION) $(PNG_EXTENSION)

# Create a symbolic link of the SVG file with a proper name in the build
# directory.
build-svg: delete-build-directory create-build-directory
	ln \
		--symbolic "$(realpath $(SVG_FILE_PATH))" \
		"$(BUILD_OUTPUT_DIR)/$(IMAGE_OUTPUT_FILE_PREFIX)$(suffix $(SVG_FILE_PATH))"

# Clean the projects artifacts.
clean: delete-build-directory

# Create the build directory.
create-build-directory:
	mkdir --parents "$(BUILD_OUTPUT_DIR)"

# Remove the build directory and its content.
delete-build-directory:
	rm --recursive --force "$(BUILD_OUTPUT_DIR)"
