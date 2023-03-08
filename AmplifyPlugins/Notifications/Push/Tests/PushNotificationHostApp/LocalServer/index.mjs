import express from 'express'
import * as childProcess from 'node:child_process'

const app = express()
app.use(express.json())

const bundleId = "com.aws.amplify.notification.PushNotificationHostApp"

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
        const cmd = `echo '${JSON.stringify(apns)}' | xcrun simctl --set testing push ${deviceId} ${bundleId} -`
        await run(cmd)
        res.send("Done")
    } catch (error) {
        console.log("Failed to trigger notification", error)
        res.sendStatus(500)
    }

})

app.post('/uninstall', async (req, res) => {
    console.log("POST /uninstall ")
    const { deviceId } = req.body
    try {
        const cmd = `xcrun simctl --set testing uninstall ${deviceId} ${bundleId}`
        await run(cmd)
        res.send("Done")
    } catch (error) {
        console.error("Failed to uninstall app", error)
        res.sendStatus(500)
    }
})

app.listen(9293, () => {
    console.log("Starting server")
})
