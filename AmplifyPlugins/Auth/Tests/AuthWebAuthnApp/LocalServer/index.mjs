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

// Every command is time-bounded. A hung `simctl` (seen on CI runners) used to hold its request until the UI
// test's own 20 s request timeout fired, with nothing in this log to say why. Now the request answers HTTP 500
// with a "Timed out" message instead, so the test's retries see a fast, explained failure. A request's commands
// share one budget, shorter than the test's 20 s timeout, so the answer always arrives before it; any one
// command may use all that is left of it, so a slow command that still finishes in time succeeds.
const requestBudgetMs = 18_000

class CommandTimeoutError extends Error {}

// CI uploads this server's output when a WebAuthn UI test fails, from a public repository. So it logs only
// request paths, the commands it runs (their one variable argument is a validated simulator UDID), how long
// they took, and simctl's own error text: never a request body, and nothing about the test's user or backend.
const log = (...items) => console.log(new Date().toISOString(), ...items)
const logError = (...items) => console.error(new Date().toISOString(), ...items)

// Run a command without invoking a shell. Arguments are passed as an array so
// user-supplied values (e.g. deviceId) are never interpreted by /bin/sh,
// preventing command injection.
//
// `deadline` is the end of the request's budget (a `Date.now()` value), and the command gets all that is left
// of it. With nothing left it is not started. When the time runs out, the command's whole process group is
// killed, and the promise rejects with a `CommandTimeoutError`: xcrun may run simctl as its child or exec it in
// place, and killing the group stops it either way. `spawn`, not `execFile`: only `spawn` takes `detached`,
// which puts the command in a process group of its own. A failed command's error is logged here, once.
const run = (file, args, deadline) => {
    const timeoutMs = deadline - Date.now()
    const command = [file, ...args].join(" ")
    if (timeoutMs <= 0) {
        const message = `Timed out: the request's ${requestBudgetMs} ms were used up before ${command}`
        logError(message)
        return Promise.reject(new CommandTimeoutError(message))
    }
    const started = Date.now()
    return new Promise((resolve, reject) => {
        let settled = false
        let stdout = ""
        let stderror = ""
        const child = childProcess.spawn(file, args, { detached: true, stdio: ["ignore", "pipe", "pipe"] })
        child.stdout.on("data", (chunk) => { stdout += chunk })
        child.stderr.on("data", (chunk) => { stderror += chunk })
        const finish = (error) => {
            clearTimeout(timer)
            if (settled) {
                return
            }
            settled = true
            if (error) {
                logError(`Failed after ${Date.now() - started} ms:`, command, stderror || error)
                reject(stderror || error)
            } else {
                log(`Done in ${Date.now() - started} ms:`, command)
                resolve(stdout)
            }
        }
        const timer = setTimeout(() => {
            if (settled) {
                return
            }
            settled = true
            try {
                process.kill(-child.pid, "SIGKILL")
            } catch {
                child.kill("SIGKILL")
            }
            const message = `Timed out after ${timeoutMs} ms: ${command}`
            logError(message)
            reject(new CommandTimeoutError(message))
        }, timeoutMs)
        child.on("error", (error) => finish(error))
        child.on("close", (code, signal) => finish(code === 0 ? null : new Error(`exit ${code ?? signal}`)))
    })
}

// Answers a failed request: HTTP 500 either way, with the time-out's message as the body when a command hung.
// `run` has already logged the command's error, so this logs only which request failed.
const fail = (res, description, error) => {
    if (error instanceof CommandTimeoutError) {
        logError(`Failed to ${description}: timed out`)
        res.status(500).send(error.message)
    } else {
        logError(`Failed to ${description}`)
        res.sendStatus(500)
    }
}

const requestDeadline = () => Date.now() + requestBudgetMs

app.post('/uninstall', async (req, res) => {
    log("POST /uninstall")
    const { deviceId } = req.body
    if (!isValidDeviceId(deviceId)) {
        return res.status(400).send("Invalid deviceId")
    }
    const deadline = requestDeadline()
    try {
        await run("xcrun", ["simctl", "uninstall", deviceId, bundleId], deadline)
        res.send("Done")
    } catch (error) {
        fail(res, "uninstall the app", error)
    }
})

app.post('/boot', async (req, res) => {
    log("POST /boot")
    const { deviceId } = req.body
    if (!isValidDeviceId(deviceId)) {
        return res.status(400).send("Invalid deviceId")
    }
    const deadline = requestDeadline()
    try {
        await run("xcrun", ["simctl", "bootstatus", deviceId, "-b"], deadline)
        res.send("Done")
    } catch (error) {
        fail(res, "boot the device", error)
    }
})

app.post('/enroll', async (req, res) => {
    log("POST /enroll")
    const { deviceId } = req.body
    if (!isValidDeviceId(deviceId)) {
        return res.status(400).send("Invalid deviceId")
    }
    const deadline = requestDeadline()
    try {
        await run("xcrun", ["simctl", "spawn", deviceId, "notifyutil", "-s", "com.apple.BiometricKit.enrollmentChanged", "1"], deadline)
        await run("xcrun", ["simctl", "spawn", deviceId, "notifyutil", "-p", "com.apple.BiometricKit.enrollmentChanged"], deadline)
        res.send("Done")
    } catch (error) {
        fail(res, "enroll biometrics in the device", error)
    }
})


app.post('/match', async (req, res) => {
    log("POST /match")
    const { deviceId } = req.body
    if (!isValidDeviceId(deviceId)) {
        return res.status(400).send("Invalid deviceId")
    }
    const deadline = requestDeadline()
    try {
        await new Promise(resolve => setTimeout(resolve, 1000))
        await run("xcrun", ["simctl", "spawn", deviceId, "notifyutil", "-p", "com.apple.BiometricKit_Sim.pearl.match"], deadline)
        await run("xcrun", ["simctl", "spawn", deviceId, "notifyutil", "-p", "com.apple.BiometricKit_Sim.fingerTouch.match"], deadline)
        await new Promise(resolve => setTimeout(resolve, 500))
        await run("xcrun", ["simctl", "spawn", deviceId, "notifyutil", "-p", "com.apple.BiometricKit_Sim.pearl.match"], deadline)
        await run("xcrun", ["simctl", "spawn", deviceId, "notifyutil", "-p", "com.apple.BiometricKit_Sim.fingerTouch.match"], deadline)
        res.send("Done")
    } catch (error) {
        fail(res, "match biometrics", error)
    }
})

// Replaces Express's default error handler, which logs the error's stack: for a body that is not JSON, that
// message quotes part of the body. Same status, and only the error's type is logged.
app.use((error, req, res, next) => {
    logError(`Rejected ${req.method} ${req.path}:`, error.type ?? error.name)
    res.sendStatus(error.status ?? 500)
})

app.listen(9294, () => {
    log("Simulator server started!")
})
