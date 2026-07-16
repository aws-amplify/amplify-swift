import express from 'express'
import * as childProcess from 'node:child_process'

const app = express()
app.use(express.json())

const bundleId = "com.aws.amplify.notification.PushNotificationHostApp"

// Simulator device identifiers are either a UUID (UDID) or the literal "booted".
// Validating up front rejects any value that could be used to smuggle shell
// metacharacters into the commands below.
const deviceIdPattern = /^([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}|booted)$/

const isValidDeviceId = (deviceId) => typeof deviceId === "string" && deviceIdPattern.test(deviceId)

// Run a command without invoking a shell. Arguments are passed as an array so
// user-supplied values (e.g. deviceId) are never interpreted by /bin/sh,
// preventing command injection.
const run = (file, args) => {
    return new Promise((resolve, reject) => {
        childProcess.execFile(file, args, (error, stdout, stderror) => {
            if (error) {
                console.warn("Failed to execute:", file, args)
                reject(stderror)
            } else {
                resolve(stdout)
            }
        })
    })
}

// Run a command without a shell and feed the given string to its stdin.
// Used in place of `echo '<json>' | xcrun simctl push ... -` so the payload
// never passes through a shell.
const runWithStdin = (file, args, input) => {
    return new Promise((resolve, reject) => {
        const child = childProcess.execFile(file, args, (error, stdout, stderror) => {
            if (error) {
                console.warn("Failed to execute:", file, args)
                reject(stderror)
            } else {
                resolve(stdout)
            }
        })
        child.stdin.end(input)
    })
}

/**
 * Trigger a new push notification.
 * Run `xcrun simctl push ...` command under the hood
 */
app.post("/notifications", async (req, res) => {
    console.log("POST /notifications")
    const {
        notification: {
            title,
            subtitle,
            body
        },
        data,
        deviceId
    } = req.body

    if (!isValidDeviceId(deviceId)) {
        return res.status(400).send("Invalid deviceId")
    }

    const apns = {
        aps: {
            alert: {
                title,
                subtitle,
                body,
            }
        },
        data: data ?? {}
    }
    try {
        // Read the payload from stdin ("-") rather than interpolating it into a
        // shell pipeline.
        await runWithStdin("xcrun", ["simctl", "push", deviceId, bundleId, "-"], JSON.stringify(apns))
        res.send("Done")
    } catch (error) {
        console.log("Failed to trigger notification", error)
        res.sendStatus(500)
    }

})

app.post('/uninstall', async (req, res) => {
    console.log("POST /uninstall ")
    const { deviceId } = req.body
    if (!isValidDeviceId(deviceId)) {
        return res.status(400).send("Invalid deviceId")
    }
    try {
        await run("xcrun", ["simctl", "uninstall", deviceId, bundleId])
        res.send("Done")
    } catch (error) {
        console.error("Failed to uninstall app", error)
        res.sendStatus(500)
    }
})

app.post('/boot', async (req, res) => {
    console.log("POST /boot ")
    const { deviceId } = req.body
    if (!isValidDeviceId(deviceId)) {
        return res.status(400).send("Invalid deviceId")
    }
    try {
        await run("xcrun", ["simctl", "bootstatus", deviceId, "-b"])
        res.send("Done")
    } catch (error) {
        console.error("Failed to boot the device", error)
        res.sendStatus(500)
    }
})

app.listen(9293, () => {
    console.log("Starting server")
})
