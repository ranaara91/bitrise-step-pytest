#!/bin/bash

# fail if any commands fails
set -e
# debug log
if [ "${debug}" == "true" ] ; then
    set -x
fi

PYTEST_OPT=""

PYTEST_OPT+=" --ignore=bin --ignore=lib --ignore=include --ignore=selenium"

if [ -n "${junit_file_path}" ] ; then
    PYTEST_OPT+=" --junit-xml=${junit_file_path}"
    envman add --key PYTEST_JUNIT_PATH --value ${junit_file_path}
fi

if [ -n "${pytest_options}" ] ; then
    PYTEST_OPT+=" ${pytest_options}"
fi

#PYTEST_OPT+=" --collect-only"

if [ -n "${files_and_dirs}" ] ; then
    PYTEST_OPT+=" ${files_and_dirs}"
fi

if [ "${virtualenv}" == "true" ] ; then
    pip3 install virtualenv
    virtualenv .
    source ./bin/activate
    pip install -r requirements.txt
fi

if [ "${appium_enabled}" == "true" ] ; then
    APPIUM_PORT="${appium_port}"
    APPIUM_LOG_PATH="${appium_log_path}"

    if [ "${debug}" == "true" ] ; then
        #brew list node > /dev/null || brew install node
        node -v
        #brew list npm > /dev/null || brew install npm
        npm -v

        npm install -g appium-doctor
        appium-doctor
    fi

    # fixes: npm ERR! Cannot read property 'find' of undefined
    npm cache verify
    brew upgrade carthage

    # install and start appium
    npm install -g appium

    # Navigate to appium directory where webdriver agent is located
    cd /usr/local/lib/node_modules/appium/node_modules/appium-webdriveragent/
    # Run the bootstrap script
    bash Scripts/bootstrap.sh -d

    echo "Starting Appium port: ${APPIUM_PORT}, log: ${APPIUM_LOG_PATH}"
    appium --port ${APPIUM_PORT} --log ${APPIUM_LOG_PATH} --log-level debug &
    APPIUM_PID=$!
    #envman add --key APPIUM_PID --value ${APPIUM_PID}
    #trap "kill ${APPIUM_PID}" EXIT
    # TODO: wait till started
    sleep 5
fi

pytest ${PYTEST_OPT}

if [ "${APPIUM_PID}" ] ; then
    echo "Stopping Appium PID: ${APPIUM_PID}"
    kill ${APPIUM_PID}
fi
