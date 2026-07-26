.PHONY: test app verify install clean validate

test:
	swift test

app:
	./Scripts/build-app.sh

verify: app
	./Scripts/verify-app.sh

install: verify
	mkdir -p "$(HOME)/Applications"
	rm -rf "$(HOME)/Applications/Screen Record Cursor.app"
	rm -rf "$(HOME)/Applications/Screen Recording Cursor.app"
	cp -R ".build/app/Screen Recording Cursor.app" "$(HOME)/Applications/"
	@echo "Installed to $(HOME)/Applications/Screen Recording Cursor.app"

validate:
	./Scripts/validate-static.sh

clean:
	swift package clean
	rm -rf .build/app
