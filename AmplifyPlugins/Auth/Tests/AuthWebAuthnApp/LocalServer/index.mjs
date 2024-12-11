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

app.post('/uninstall', async (req, res) => {
    console.log("POST /uninstall ")
    const { deviceId } = req.body
    try {
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
    const { deviceId } = req.body
    try {
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
    const { deviceId } = req.body
    try {
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
    const { deviceId } = req.body
    try {
        const cmd = `xcrun simctl spawn ${deviceId} notifyutil -p com.apple.BiometricKit_Sim.fingerTouch.match`
        await run(cmd)
        res.send("Done")
    } catch (error) {
        console.error("Failed to match biometrics", error)
        res.sendStatus(500)
    }
})

app.listen(9294, () => {
    console.log("Simulator server started!")
})
