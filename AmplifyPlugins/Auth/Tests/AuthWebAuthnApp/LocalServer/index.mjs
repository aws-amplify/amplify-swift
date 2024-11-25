import express from 'express'
import * as childProcess from 'node:child_process'

const app = express()
app.use(express.json())

const bundleId = "com.amazon.aws.amplify.swift.AuthWebAuthnApp"

const run = (cmd) => {
    return new Promise((resolve, reject) => {
        childProcess.exec(cmd, (error, stdout, stderror) => {
            if (error) {
                console.warn("Failed to execute cmd:", cmd)
                reject(stderror)
            } else {
                resolve(stdout)
            }
        })
    })
}

const getDeviceId = async () => {
    const cmd = `xcrun simctl list | grep "iPhone" | grep "Booted" | awk -F '[()]' '{print $2}' | uniq`
    try {
        const deviceId = await run(cmd)
        return deviceId.trim()
    } catch (error) {
        console.error("Failed to retrieve deviceId", error)
        throw new Error("Failed to retrieve deviceId")
    }
}

app.post('/uninstall', async (req, res) => {
    console.log("POST /uninstall ")
    try {
        const deviceId = await getDeviceId()
        const cmd = `xcrun simctl uninstall ${deviceId} ${bundleId}`
        await run(cmd)
        res.send("Done")
    } catch (error) {
        console.error("Failed to uninstall app", error)
        res.sendStatus(500)
    }
})

app.post('/boot', async (req, res) => {
    console.log("POST /boot ")
    try {
        const deviceId = await getDeviceId()
        const cmd = `xcrun simctl bootstatus ${deviceId} -b`
        await run(cmd)
        res.send("Done")
    } catch (error) {
        console.error("Failed to boot the device", error)
        res.sendStatus(500)
    }
})

app.post('/enroll', async (req, res) => {
    console.log("POST /enroll ")
    try {
        const deviceId = await getDeviceId()
        const cmd = `xcrun simctl spawn ${deviceId} notifyutil -s com.apple.BiometricKit.enrollmentChanged '1' && xcrun simctl spawn ${deviceId} notifyutil -p com.apple.BiometricKit.enrollmentChanged`
        await run(cmd)
        res.send("Done")
    } catch (error) {
        console.error("Failed to enroll biometrics in the device", error)
        res.sendStatus(500)
    }
})

app.post('/match', async (req, res) => {
    console.log("POST /match ")
    try {
        const deviceId = await getDeviceId()
        const cmd = `xcrun simctl spawn ${deviceId} notifyutil -p com.apple.BiometricKit_Sim.fingerTouch.match`
        await run(cmd)
        res.send("Done")
    } catch (error) {
        console.error("Failed to match biometrics in the device", error)
        res.sendStatus(500)
    }
})

export default app