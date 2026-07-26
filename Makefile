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
	cp -R ".build/app/Screen Record Cursor.app" "$(HOME)/Applications/"
	@echo "Installed to $(HOME)/Applications/Screen Record Cursor.app"

validate:
	./Scripts/validate-static.sh

clean:
	swift package clean
	rm -rf .build/app
