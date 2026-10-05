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

// A positive number from the environment, which only this server's tests set (`test/`), else `fallback`.
const fromEnvironment = (name, fallback) => {
    const value = Number(process.env[name])
    return Number.isFinite(value) && value > 0 ? value : fallback
}

// Each request's work is a job, which runs its `simctl` commands for one simulator, and every job is
// time-bounded. On a loaded CI runner a fresh simulator has taken 17 s to run one `simctl spawn`, and this
// process's own timers have fired 10 to 35 s late. Killing such a command when its request's time ran out,
// and starting it again on the UI test's retry, only stacked new commands onto the busy simulator: none
// finished, and the test failed (run 37338053976). So a job is not tied to the request that started it:
//  - a request waits at most `requestWaitMs` for its job, then answers HTTP 500 "Timed out …" while the job
//    goes on. The UI tests retry that answer 2 s later, and the retry waits for the same job. The wait is
//    well inside the tests' 20 s request timeout, so the answer arrives even when this process runs late;
//  - a request for an action that a job of its simulator is already running, or waiting to run, joins that
//    job instead of starting another: two `/boot`s run one `bootstatus`, a `/match` sent again presents the
//    face once;
//  - one simulator's jobs run one at a time, in the order they came, so its commands never overlap;
//  - a job ends at its own limit, `jobLimitMs` (`bootLimitMs` for `/boot`): its command is then killed, and
//    every request waiting for it answers "Timed out …". The UI tests send a request at most 3 times, about
//    49 s of waiting here, which covers a whole job of `jobLimitMs`. A longer `/boot` goes on for the next
//    request to join.
const requestWaitMs = fromEnvironment("LOCALSERVER_REQUEST_WAIT_MS", 15_000)
const jobLimitMs = fromEnvironment("LOCALSERVER_JOB_LIMIT_MS", 45_000)
const bootLimitMs = fromEnvironment("LOCALSERVER_BOOT_LIMIT_MS", 120_000)
const port = fromEnvironment("LOCALSERVER_PORT", 9294)

class CommandTimeoutError extends Error {}

// CI uploads this server's output when a WebAuthn UI test fails, from a public repository. So it logs only
// request paths, the commands it runs (their one variable argument is a validated simulator UDID), how long
// they took, and simctl's own error text: never a request body, and nothing about the test's user or backend.
const log = (...items) => console.log(new Date().toISOString(), ...items)
const logError = (...items) => console.error(new Date().toISOString(), ...items)

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms))

// Run a command without invoking a shell. Arguments are passed as an array so
// user-supplied values (e.g. deviceId) are never interpreted by /bin/sh,
// preventing command injection.
//
// `deadline` is the end of the job's time (a `Date.now()` value), and the command gets all that is left of
// it. With nothing left it is not started. When the time runs out, the command's whole process group is
// killed, and the promise rejects with a `CommandTimeoutError`: xcrun may run simctl as its child or exec it in
// place, and killing the group stops it either way. `spawn`, not `execFile`: only `spawn` takes `detached`,
// which puts the command in a process group of its own. A failed command's error is logged here, once.
const run = (file, args, deadline) => {
    const command = [file, ...args].join(" ")
    if (deadline - Date.now() <= 0) {
        const message = `Timed out: the job's time was used up before ${command}`
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
        // Set from the deadline after the spawn, which can itself take a while on a loaded runner.
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
            const message = `Timed out after ${Date.now() - started} ms: ${command}`
            logError(message)
            reject(new CommandTimeoutError(message))
        }, Math.max(0, deadline - Date.now()))
        child.on("error", (error) => finish(error))
        child.on("close", (code, signal) => finish(code === 0 ? null : new Error(`exit ${code ?? signal}`)))
    })
}

// Per simulator: `queue`, which settles once its last job has ended (the next one starts then), and `jobs`, its
// running or waiting job for each action, which a request for that action joins.
const simulators = new Map()

// The job running, or waiting to run, `action` on `deviceId`; with none, a new one, queued, that runs
// `work(deadline)` with `limitMs` from its start. The promise settles when `work` ends.
const job = (deviceId, action, limitMs, work) => {
    let simulator = simulators.get(deviceId)
    if (!simulator) {
        simulator = { queue: Promise.resolve(), jobs: new Map() }
        simulators.set(deviceId, simulator)
    }
    const current = simulator.jobs.get(action)
    if (current) {
        log(`POST ${action} joins the one already running or waiting`)
        return current
    }
    const promise = simulator.queue.then(() => work(Date.now() + limitMs))
    simulator.jobs.set(action, promise)
    const ended = () => {
        if (simulator.jobs.get(action) === promise) {
            simulator.jobs.delete(action)
        }
    }
    simulator.queue = promise.then(ended, ended)
    return promise
}

// Answers a request once its job has ended, or after `requestWaitMs` while the job goes on: HTTP 200 "Done";
// HTTP 500 with a "Timed out …" body when the job is still running or reached its limit; HTTP 500 alone when
// its command failed. `run` has already logged the command's error, so this logs only which request failed.
const answer = async (res, description, promise) => {
    let timer
    const waited = new Promise(resolve => { timer = setTimeout(() => resolve("waited"), requestWaitMs) })
    try {
        if (await Promise.race([promise.then(() => "done"), waited]) === "done") {
            res.send("Done")
        } else {
            logError(`Failed to ${description}: still running after ${requestWaitMs} ms`)
            res.status(500).send(`Timed out: still running after ${requestWaitMs} ms; a retry waits for it`)
        }
    } catch (error) {
        if (error instanceof CommandTimeoutError) {
            logError(`Failed to ${description}: timed out`)
            res.status(500).send(error.message)
        } else {
            logError(`Failed to ${description}`)
            res.sendStatus(500)
        }
    } finally {
        clearTimeout(timer)
    }
}

// Validates the request's simulator, then answers with the job for `path` on it (`job`, `answer`).
const route = (path, description, limitMs, work) => {
    app.post(path, async (req, res) => {
        log(`POST ${path}`)
        const { deviceId } = req.body ?? {}
        if (!isValidDeviceId(deviceId)) {
            return res.status(400).send("Invalid deviceId")
        }
        await answer(res, description, job(deviceId, path, limitMs, (deadline) => work(deviceId, deadline)))
    })
}

const spawnInSimulator = (deviceId, args, deadline) => run("xcrun", ["simctl", "spawn", deviceId, ...args], deadline)

route("/uninstall", "uninstall the app", jobLimitMs, (deviceId, deadline) =>
    run("xcrun", ["simctl", "uninstall", deviceId, bundleId], deadline))

route("/boot", "boot the device", bootLimitMs, (deviceId, deadline) =>
    run("xcrun", ["simctl", "bootstatus", deviceId, "-b"], deadline))

// `notifyutil` runs its commands in order, so one process sets the enrollment state, then posts its change.
route("/enroll", "enroll biometrics in the device", jobLimitMs, (deviceId, deadline) =>
    spawnInSimulator(deviceId, [
        "notifyutil",
        "-s", "com.apple.BiometricKit.enrollmentChanged", "1",
        "-p", "com.apple.BiometricKit.enrollmentChanged"
    ], deadline))

// Presents a matching face and finger, then again half a second later, each time from one `notifyutil`: one
// `simctl spawn` where there were two, which is what a busy simulator is slow to run. Once the first is
// presented, the job succeeds even if the second does not finish in its time.
route("/match", "match biometrics", jobLimitMs, async (deviceId, deadline) => {
    const match = [
        "notifyutil",
        "-p", "com.apple.BiometricKit_Sim.pearl.match",
        "-p", "com.apple.BiometricKit_Sim.fingerTouch.match"
    ]
    await sleep(1000)
    await spawnInSimulator(deviceId, match, deadline)
    await sleep(500)
    try {
        await spawnInSimulator(deviceId, match, deadline)
    } catch (error) {
        if (!(error instanceof CommandTimeoutError)) {
            throw error
        }
        log("The face was presented once: the second one timed out")
    }
})

// Replaces Express's default error handler, which logs the error's stack: for a body that is not JSON, that
// message quotes part of the body. Same status, and only the error's type is logged.
app.use((error, req, res, next) => {
    logError(`Rejected ${req.method} ${req.path}:`, error.type ?? error.name)
    res.sendStatus(error.status ?? 500)
})

app.listen(port, () => {
    log("Simulator server started!")
})
