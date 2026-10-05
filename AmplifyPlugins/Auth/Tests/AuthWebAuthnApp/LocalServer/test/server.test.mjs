// Tests for the simulator server (`index.mjs`), run with `npm test`. Each test starts the server on a port of
// its own, with a fake `xcrun` (`fake-xcrun/xcrun`) first on its PATH, so no simulator is needed: the fake
// records each call and takes as long as the test says.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import * as childProcess from 'node:child_process'
import * as fs from 'node:fs'
import * as http from 'node:http'
import * as os from 'node:os'
import * as path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const serverPath = path.join(here, "..", "index.mjs")
const fakeXcrunDirectory = path.join(here, "fake-xcrun")
const device = "00000000-0000-4000-8000-000000000001"
let nextPort = 19400 + (process.pid % 500)

// Starts the server with `environment` added to its own, and returns once it listens.
const startServer = async (environment = {}) => {
    const port = nextPort++
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), "localserver-test-"))
    const xcrunLog = path.join(directory, "xcrun.log")
    fs.writeFileSync(xcrunLog, "")
    const server = childProcess.spawn(process.execPath, [serverPath], {
        env: {
            ...process.env,
            PATH: `${fakeXcrunDirectory}:${process.env.PATH}`,
            FAKE_XCRUN_LOG: xcrunLog,
            LOCALSERVER_PORT: String(port),
            ...environment
        },
        stdio: ["ignore", "pipe", "pipe"]
    })
    let output = ""
    server.stdout.on("data", (chunk) => { output += chunk })
    server.stderr.on("data", (chunk) => { output += chunk })
    await new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error(`The server did not start: ${output}`)), 10_000)
        server.stdout.on("data", () => {
            if (output.includes("Simulator server started!")) {
                clearTimeout(timer)
                resolve()
            }
        })
        server.on("exit", (code) => reject(new Error(`The server exited (${code}): ${output}`)))
    })
    return {
        port,
        output: () => output,
        // The fake's calls, each as `{ pid, event, args }`, `event` being "start" or "end".
        calls: () => fs.readFileSync(xcrunLog, "utf8").split("\n").filter(Boolean).map((line) => {
            const [pid, event, ...args] = line.split(" ")
            return { pid, event, args: args.join(" ") }
        }),
        isRunning: () => server.exitCode === null && server.signalCode === null,
        stop: () => {
            server.kill("SIGKILL")
            fs.rmSync(directory, { recursive: true, force: true })
        }
    }
}

// POSTs `{ deviceId }` (or `body`) to `requestPath`, and resolves with the status, the body and when it came.
const post = (server, requestPath, body = { deviceId: device }) => new Promise((resolve, reject) => {
    const data = JSON.stringify(body)
    const request = http.request({
        host: "127.0.0.1",
        port: server.port,
        path: requestPath,
        method: "POST",
        headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(data) }
    }, (response) => {
        let text = ""
        response.on("data", (chunk) => { text += chunk })
        response.on("end", () => resolve({ status: response.statusCode, body: text, at: Date.now() }))
    })
    request.on("error", reject)
    request.end(data)
})

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms))

const withServer = (environment, body) => async () => {
    const server = await startServer(environment)
    try {
        await body(server)
    } finally {
        server.stop()
    }
}

test("enroll sets the enrollment state and posts its change from one notifyutil", withServer({}, async (server) => {
    const response = await post(server, "/enroll")
    assert.equal(response.status, 200)
    assert.deepEqual(server.calls().filter((call) => call.event === "start").map((call) => call.args), [
        `simctl spawn ${device} notifyutil -s com.apple.BiometricKit.enrollmentChanged 1 -p com.apple.BiometricKit.enrollmentChanged`
    ])
}))

test("match presents a face and a finger twice, each time from one notifyutil", withServer({}, async (server) => {
    const response = await post(server, "/match")
    assert.equal(response.status, 200)
    const match = `simctl spawn ${device} notifyutil -p com.apple.BiometricKit_Sim.pearl.match -p com.apple.BiometricKit_Sim.fingerTouch.match`
    assert.deepEqual(server.calls().filter((call) => call.event === "start").map((call) => call.args), [match, match])
}))

test("boot and uninstall run their simctl commands", withServer({}, async (server) => {
    assert.equal((await post(server, "/boot")).status, 200)
    assert.equal((await post(server, "/uninstall")).status, 200)
    assert.deepEqual(server.calls().filter((call) => call.event === "start").map((call) => call.args), [
        `simctl bootstatus ${device} -b`,
        `simctl uninstall ${device} com.amazon.aws.amplify.swift.AuthWebAuthnApp`
    ])
}))

test("a device that is neither a UDID nor \"booted\" is refused, with nothing run", withServer({}, async (server) => {
    for (const deviceId of ["booted; rm -rf /", "../x", 42, undefined]) {
        const response = await post(server, "/boot", { deviceId })
        assert.equal(response.status, 400)
    }
    assert.equal((await post(server, "/match", { deviceId: "booted" })).status, 200)
    assert.equal(server.calls().filter((call) => call.event === "start").length, 2)
}))

test("a failed command answers HTTP 500 without a time-out, so the tests do not retry it", withServer({
    FAKE_XCRUN_EXIT_UNINSTALL: "3"
}, async (server) => {
    const response = await post(server, "/uninstall")
    assert.equal(response.status, 500)
    assert.ok(!response.body.startsWith("Timed out"), response.body)
}))

test("a slow job answers \"Timed out\" when the request's wait ends, goes on, and a retry gets its result", withServer({
    LOCALSERVER_REQUEST_WAIT_MS: "1000",
    FAKE_XCRUN_SLEEP_BOOTSTATUS: "1.6"
}, async (server) => {
    const started = Date.now()
    const first = await post(server, "/boot")
    assert.equal(first.status, 500)
    assert.match(first.body, /^Timed out: still running/)
    assert.ok(first.at - started < 2000, `answered after ${first.at - started} ms`)
    // The UI tests' retry, while the first job still runs: it waits for that job and runs no command.
    const retry = await post(server, "/boot")
    assert.equal(retry.status, 200)
    const calls = server.calls()
    assert.equal(calls.filter((call) => call.event === "start").length, 1)
    assert.equal(calls.filter((call) => call.event === "end").length, 1)
}))

test("requests for an action already running on the simulator join it", withServer({
    FAKE_XCRUN_SLEEP_SPAWN: "1"
}, async (server) => {
    const responses = await Promise.all([post(server, "/match"), sleep(200).then(() => post(server, "/match"))])
    assert.deepEqual(responses.map((response) => response.status), [200, 200])
    assert.equal(server.calls().filter((call) => call.event === "start").length, 2, "one job: its two posts")
}))

test("a simulator's jobs run one at a time, in order", withServer({
    FAKE_XCRUN_SLEEP_BOOTSTATUS: "1"
}, async (server) => {
    const responses = await Promise.all([post(server, "/boot"), sleep(100).then(() => post(server, "/enroll"))])
    assert.deepEqual(responses.map((response) => response.status), [200, 200])
    const calls = server.calls()
    assert.deepEqual(calls.map((call) => `${call.event} ${call.args.split(" ")[1]}`), [
        "start bootstatus", "end bootstatus", "start spawn", "end spawn"
    ])
}))

test("different simulators' jobs do not wait for each other", withServer({
    FAKE_XCRUN_SLEEP_BOOTSTATUS: "1.5"
}, async (server) => {
    const other = "00000000-0000-4000-8000-000000000002"
    const boot = post(server, "/boot")
    await sleep(100)
    const enroll = await post(server, "/enroll", { deviceId: other })
    assert.equal(enroll.status, 200)
    assert.equal(server.calls().filter((call) => call.event === "end").length, 1, "the enroll ended first")
    assert.equal((await boot).status, 200)
}))

test("a job is killed at its limit, its requests answer \"Timed out\", and the next request starts anew", withServer({
    LOCALSERVER_REQUEST_WAIT_MS: "3000",
    LOCALSERVER_JOB_LIMIT_MS: "800",
    FAKE_XCRUN_SLEEP_UNINSTALL: "5",
    FAKE_XCRUN_SLOW_FIRST: "1"
}, async (server) => {
    const first = await post(server, "/uninstall")
    assert.equal(first.status, 500)
    assert.match(first.body, /^Timed out after \d+ ms: xcrun simctl uninstall/)
    const second = await post(server, "/uninstall")
    assert.equal(second.status, 200)
    await sleep(300)
    const calls = server.calls()
    const firstPid = calls[0].pid
    assert.ok(!calls.some((call) => call.pid === firstPid && call.event === "end"), "the killed command never ended")
    assert.equal(calls.filter((call) => call.event === "start").length, 2)
}))

test("a job that reaches its limit after its request was answered does not stop the server", withServer({
    LOCALSERVER_REQUEST_WAIT_MS: "300",
    LOCALSERVER_JOB_LIMIT_MS: "800",
    FAKE_XCRUN_SLEEP_UNINSTALL: "5"
}, async (server) => {
    const first = await post(server, "/uninstall")
    assert.match(first.body, /^Timed out: still running/)
    await sleep(1200)
    assert.ok(server.isRunning(), server.output())
    assert.equal((await post(server, "/boot")).status, 200)
}))
