import express from 'express'
import * as childProcess from 'node:child_process'

const app = express()
app.use(express.json())

const bundleId = "com.amazon.aws.amplify.swift.AuthWebAuthnApp"

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

app.post('/enroll', async (req, res) => {
    console.log("POST /enroll ")
    const { deviceId } = req.body
    if (!isValidDeviceId(deviceId)) {
        return res.status(400).send("Invalid deviceId")
    }
    try {
        await run("xcrun", ["simctl", "spawn", deviceId, "notifyutil", "-s", "com.apple.BiometricKit.enrollmentChanged", "1"])
        await run("xcrun", ["simctl", "spawn", deviceId, "notifyutil", "-p", "com.apple.BiometricKit.enrollmentChanged"])
        res.send("Done")
    } catch (error) {
        console.error("Failed to enroll biometrics in the device", error)
        res.sendStatus(500)
    }
})


app.post('/match', async (req, res) => {
    console.log("POST /match ")
    const { deviceId } = req.body
    if (!isValidDeviceId(deviceId)) {
        return res.status(400).send("Invalid deviceId")
    }
    try {
        await run("xcrun", ["simctl", "spawn", deviceId, "notifyutil", "-p", "com.apple.BiometricKit_Sim.fingerTouch.match"])
        res.send("Done")
    } catch (error) {
        console.error("Failed to match biometrics", error)
        res.sendStatus(500)
    }
})

app.listen(9294, () => {
    console.log("Simulator server started!")
})
