pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io

QtObject {
    id: commandRunner
    property var jobs: ({})
    function run(key, argv, timeoutMs, callback, stream) {
        if (jobs[key] || !Array.isArray(argv) || !argv.length ||
                !argv.every(a => typeof a === "string") || !(timeoutMs > 0)) return false
        const job = processFactory.createObject(commandRunner, {
            jobKey: key, command: argv, limit: timeoutMs, done: callback, streaming: stream || null
        }) as Process
        jobs[key] = job
        job.running = true
        return true
    }
    function cancel(key) { if (jobs[key]) jobs[key].stop() }
    property Component processFactory: Component {
        Process {
            id: task
            required property string jobKey
            required property int limit
            required property var done
            property var streaming: null
            property bool finished: false
            property bool timedOut: false
            property string output: ""
            property string errors: ""
            property Timer deadline: Timer {
                interval: task.limit; running: task.running
                onTriggered: { task.timedOut = true; task.signal(9); task.finish(-1) }
            }
            stdout: SplitParser {
                onRead: data => {
                    if (task.streaming) task.streaming(data)
                    else task.output += data + "\n"
                }
            }
            stderr: SplitParser { onRead: data => task.errors += data + "\n" }
            onExited: (code, status) => finish(status === 0 ? code : -1)
            onRunningChanged: if (!running && !finished) failure.start()
            property Timer failure: Timer { interval: 1; onTriggered: task.finish(-1) }
            function stop() { signal(9); finish(-1) }
            function finish(code) {
                if (finished) return
                finished = true
                delete commandRunner.jobs[jobKey]
                done(output, code, timedOut ? "Command timed out" : errors)
                destroy()
            }
        }
    }
}
