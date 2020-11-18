#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

cd $BUILD_SOURCESDIRECTORY/build/wasm-uitest-binaries

npm i chromedriver@84.0.1
npm i puppeteer@5.1.0

export UNO_UITEST_TARGETURI=http://localhost:8000
export UNO_UITEST_DRIVERPATH_CHROME=$BUILD_SOURCESDIRECTORY/build/wasm-uitest-binaries/node_modules/chromedriver/lib/chromedriver
export UNO_UITEST_CHROME_BINARY_PATH=$BUILD_SOURCESDIRECTORY/build/wasm-uitest-binaries/node_modules/puppeteer/.local-chromium/linux-768783/chrome-linux/chrome
export UNO_UITEST_SCREENSHOT_PATH=$BUILD_ARTIFACTSTAGINGDIRECTORY/screenshots/wasm-automated
export UNO_UITEST_PLATFORM=Browser

mkdir -p $UNO_UITEST_SCREENSHOT_PATH

## The python server serves the current working directory, and may be changed by the nunit runner
bash -c "cd $BUILD_SOURCESDIRECTORY/build/wasm-uitest-binaries/site; python server.py &"

export UNO_ORIGINAL_TEST_RESULTS=$BUILD_SOURCESDIRECTORY/build/TestResult-original.xml
export UNO_TESTS_FAILED_LIST=$BUILD_SOURCESDIRECTORY/build/uitests-failure-results/failed-tests-wasm-automated-chromium.txt

export TEST_FILTERS="namespace != 'SamplesApp.UITests.Snap'"

if [ -f "$UNO_TESTS_FAILED_LIST" ]; then
    export UNO_TESTS_NUNIT_FILTER="--testlist "$UNO_TESTS_FAILED_LIST""
else
    export UNO_TESTS_NUNIT_FILTER="--where \"$TEST_FILTERS\""
fi

export NUNIT_VERSION=3.11.1
mono nuget/NuGet.exe install NUnit.ConsoleRunner -Version $NUNIT_VERSION

mono $BUILD_SOURCESDIRECTORY/build/NUnit.ConsoleRunner.$NUNIT_VERSION/tools/nunit3-console.exe \
	--trace=Verbose \
    --result=$UNO_ORIGINAL_TEST_RESULTS \
    $UNO_TESTS_NUNIT_FILTER \
    $BUILD_SOURCESDIRECTORY/build/wasm-uitest-binaries/test-bin/SamplesApp.UITests.dll

pushd $BUILD_SOURCESDIRECTORY/src/Uno.NUnitTransformTool
dotnet run list-failed $UNO_ORIGINAL_TEST_RESULTS $UNO_TESTS_FAILED_LIST
popd
