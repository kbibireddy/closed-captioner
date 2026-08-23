import Foundation

setbuf(stdout, nil)

let radio = RadioPeer()
radio.start()

print("Turn the radio ON in Closed Captioner (top right) to connect.")
print("This process sends nothing until you type a line and press Enter.")
print("Incoming messages print as [name] text  HH:mm:ss")
print("Ctrl+C to stop.")

DispatchQueue.global(qos: .userInitiated).async {
    while let line = readLine(strippingNewline: true) {
        radio.send(line)
    }
}

RunLoop.main.run()
