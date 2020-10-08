xcodeproj:
	PF_DEVELOP=1 swift run xcodegen

test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.2 \
		bash -c 'make test-swift'

test-macos:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting_macOS \
		-destination platform="macOS" \

test-ios:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting_iOS \
		-destination platform="iOS Simulator,name=iPhone 11 Pro Max,OS=13.3" \

test-swift:
	swift test \
		--enable-pubgrub-resolver \
		--parallel

test-tvos:
	set -o pipefail && \
	xcodebuild test \
		-scheme SnapshotTesting_tvOS \
		-destination platform="tvOS Simulator,name=Apple TV 4K,OS=13.3" \

test-all: test-linux test-macos test-ios

format:
	swift format --in-place --recursive \
		./Package.swift \
		./Sources \
		./Tests/*.swift \
		./Tests/SnapshotTestingTests/*.swift
