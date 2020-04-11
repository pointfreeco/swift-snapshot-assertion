xcodeproj:
	PF_DEVELOP=1 swift run xcodegen

test-linux:
	docker build --tag snapshot-testing . \
		&& docker run --rm snapshot-testing

test-macos:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting_macOS \
		-destination platform="macOS" \

test-ios:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting_iOS \
		-destination platform="iOS Simulator,name=iPhone 11 Pro Max,OS=13.2.2" \

test-swift:
	swift test

test-tvos:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting_tvOS \
		-destination platform="tvOS Simulator,name=Apple TV 4K,OS=13.2" \

test-all: test-linux test-macos test-ios
