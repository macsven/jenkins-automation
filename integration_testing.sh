#!/bin/sh
SIMULATORSDK=$1
APPNAME=$2
UIAUTOMATIONPREFIX=$3
UIAUTOMATIONTESTPATH=$4

TESTRESULTSPATH=$UIAUTOMATIONPREFIX/TestResults 

# boolean value for testResults
TESTSUCCESSFUL=false

# build the project especially with Debug-scheme on iOS Simulator to make this build runnable with instruments (make sure architecture i386 is enabled in debug scheme)
xcodebuild -arch i386 -configuration Debug -sdk $SIMULATORSDK clean build

# run Instruments from command line combined with the *.app file and the JavaScript test script. Results for every run in Instruments are stored in $WORKSPACE/TestResults.
# stdout is passed to an log-File just for this command
xcrun instruments -t /Applications/Xcode.app/Contents/Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate $WORKSPACE/build/Debug-iphonesimulator/$APPNAME.app -e UIASCRIPT $UIAUTOMATIONTESTPATH -e UIARESULTSPATH $WORKSPACE/TestResults 1>IntegrationTest.log

# remove all *.trace files because in most cases they are broken and we don't need them (-> garbage), because we have all necessary information in the log-file
rm -r $WORKSPACE/*.trace

# save the date/time at first to be able to compare with the build-time later
NOW=$(date +%d.%m.%y/%T)
# create a nice title including the BuildNumber and the Date (stored in first line of this script)
SUBJECT="Build: "$BUILD_NUMBER
SUBJECT=$SUBJECT" - Date:"
SUBJECT=$SUBJECT$NOW

# locating the active run (latest run)
ACTIVE_RUN=$(ls -1t ${WORKSPACE}/TestResults|grep "Run" -m1)

# transform the resulting PLIST into some nice HTML
xsltproc --stringparam Title "${SUBJECT}" --stringparam ScreenshotPathPrefix "${ACTIVE_RUN}" --stringparam SmileyPathPrefix "/userContent/TestResults/images/" --output "${WORKSPACE}/TestResults/IntegrationTesting.html" ~/UnitTestScripts/integration_test_result_transform.xsl "${WORKSPACE}/TestResults/${ACTIVE_RUN}/Automation Results.plist"

if [ $result -ne 0 ] ; then
    # exit this script with 1 to tell Jenkins that this build didn't complete successfully
    exit 1
fi
# 
exit 0
