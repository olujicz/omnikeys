import AppKit

// `OmniKeys --render out.png [--settings file] [--config file] [--width 1440]` draws the sheet and exits.
if let options = RenderOptions(arguments: CommandLine.arguments) {
    exit(SheetRenderer.render(options) ? 0 : 1)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
