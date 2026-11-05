import AVFoundation
import CoreHaptics
import SwiftUI

struct ContentView: View {
    private let lootTable = ["gold_coin", "rubber_duck", "old_boot"]
    private let openDegrees = 150.0
    private let closeDegrees = 10.0

    @State private var chestState: ChestState = .closed
    @State private var loot: String?
    @State private var hingeDegrees: Double = 0
    @State private var hasAwardedLoot = false
    @State private var feedback = ChestFeedback()

    private var openProgress: Double {
        min(max(hingeDegrees / openDegrees, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            let halfHeight = geo.size.height / 2

            ZStack {
                // Deep interior background when chest opens
                Color(red: 0.04, green: 0.03, blue: 0.02)
                    .ignoresSafeArea()

                // Golden treasure glow inside the chest cavity
                RadialGradient(
                    colors: [
                        Color(red: 0.98, green: 0.78, blue: 0.22)
                            .opacity(chestState == .open ? 0.85 : 0.15 + (openProgress * 0.45)),
                        Color(red: 0.45, green: 0.25, blue: 0.04).opacity(0.3),
                        .clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: geo.size.width * 0.85
                )
                .ignoresSafeArea()

                // 50/50 Split Across the iPhone Duo Hinge
                VStack(spacing: 0) {
                    // TOP HALF (Side 1 of Duo): Chest Lid
                    ZStack(alignment: .bottom) {
                        LinearGradient(
                            colors: [
                                Color(red: 0.36, green: 0.20, blue: 0.08),
                                Color(red: 0.24, green: 0.12, blue: 0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        Image(chestState.rawValue)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: halfHeight * 1.6, alignment: .top)
                            .clipped()
                            .opacity(0.85)

                        // Gold rim & latch at the hinge seam
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.65, blue: 0.20))
                            .frame(height: 10)
                    }
                    .frame(width: geo.size.width, height: halfHeight)
                    .clipped()
                    // Lid lifts upward as the physical hinge unfolds
                    .offset(y: -openProgress * (halfHeight * 0.55))
                    .rotation3DEffect(
                        .degrees(openProgress * 65),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .top,
                        perspective: 0.6
                    )

                    // BOTTOM HALF (Side 2 of Duo): Chest Base + Interior Loot
                    ZStack(alignment: .top) {
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.09, blue: 0.03),
                                Color(red: 0.28, green: 0.15, blue: 0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        Image(chestState.rawValue)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: halfHeight * 1.6, alignment: .bottom)
                            .clipped()
                            .opacity(0.85)

                        // Dark interior rim at the hinge line
                        Rectangle()
                            .fill(Color(red: 0.75, green: 0.55, blue: 0.15))
                            .frame(height: 8)

                        // Loot appearing directly INSIDE the chest base
                        lootView
                            .padding(.top, halfHeight * 0.12)
                    }
                    .frame(width: geo.size.width, height: halfHeight)
                    .clipped()
                }
                .ignoresSafeArea()

                // Subtle degree indicator at bottom edge
                VStack {
                    Spacer()
                    Text(String(format: "%.0f°", hingeDegrees))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.bottom, 12)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            feedback.prepare()
            feedback.updateSuspense(degrees: hingeDegrees, isOpen: chestState == .open)
        }
        .onDisappear {
            feedback.stop()
        }
        .onHingeChange { _, context in
            guard let hinge = context.hinge else { return }
            applyHinge(degrees: hinge.angle.degrees)
        }
    }

    private var lootView: some View {
        VStack(spacing: 10) {
            if let loot {
                Image(loot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .shadow(color: Color(red: 0.98, green: 0.82, blue: 0.35).opacity(0.9), radius: 24)
                    .accessibilityHidden(true)

                Text(lootTitle(loot))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.35))
                    .shadow(color: .black.opacity(0.8), radius: 6)
            }
        }
        .scaleEffect(loot == nil ? 0.3 : 1.0)
        .opacity(loot == nil ? 0 : 1)
        .animation(.spring(response: 0.38, dampingFraction: 0.68), value: loot)
        .accessibilityElement(children: .combine)
    }

    private func applyHinge(degrees: Double) {
        hingeDegrees = degrees

        if hasAwardedLoot {
            if degrees < closeDegrees {
                withAnimation(.easeIn(duration: 0.2)) {
                    chestState = .closed
                    loot = nil
                }
                hasAwardedLoot = false
                feedback.updateSuspense(degrees: degrees, isOpen: false)
            } else if degrees >= openDegrees {
                chestState = .open
            } else {
                chestState = .opening
            }
            return
        }

        if degrees >= openDegrees {
            hasAwardedLoot = true
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                chestState = .open
                loot = lootTable.randomElement()
            }
            feedback.playOpen()
        } else if degrees >= closeDegrees {
            chestState = .opening
            feedback.updateSuspense(degrees: degrees, isOpen: false)
        } else {
            chestState = .closed
            loot = nil
            feedback.updateSuspense(degrees: degrees, isOpen: false)
        }
    }

    private func lootTitle(_ id: String) -> String {
        id.split(separator: "_").map(\.capitalized).joined(separator: " ")
    }
}

private enum ChestState: String {
    case closed = "chest_closed"
    case opening = "chest_opening"
    case open = "chest_open"
}

private final class ChestFeedback {
    private var engine: CHHapticEngine?
    private var creakPlayer: AVAudioPlayer?
    private var suspensePlayer: AVAudioPlayer?
    private var didPrepare = false

    func prepare() {
        guard !didPrepare else { return }
        didPrepare = true
        prepareAudio()
        prepareHaptics()
    }

    func updateSuspense(degrees: Double, isOpen: Bool) {
        guard let suspensePlayer else { return }
        if isOpen {
            suspensePlayer.stop()
            return
        }
        let progress = Float(min(max(degrees / 150.0, 0), 1))
        suspensePlayer.volume = 0.25 + (progress * 0.75)
        suspensePlayer.rate = 1.0 + (progress * 0.28)
        if !suspensePlayer.isPlaying {
            suspensePlayer.play()
        }
    }

    func playOpen() {
        suspensePlayer?.stop()
        playCreak()
        playTransient()
    }

    func stop() {
        engine?.stop()
        creakPlayer?.stop()
        suspensePlayer?.stop()
    }

    private func prepareAudio() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)

        if let creakURL = Bundle.main.url(forResource: "chest_creak", withExtension: "wav") {
            creakPlayer = try? AVAudioPlayer(contentsOf: creakURL)
            creakPlayer?.prepareToPlay()
        }

        if let suspenseURL = Bundle.main.url(forResource: "chest_suspense", withExtension: "wav") {
            suspensePlayer = try? AVAudioPlayer(contentsOf: suspenseURL)
            suspensePlayer?.numberOfLoops = -1
            suspensePlayer?.enableRate = true
            suspensePlayer?.volume = 0.25
            suspensePlayer?.prepareToPlay()
        }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard let engine = try? CHHapticEngine() else { return }
        engine.isAutoShutdownEnabled = true
        engine.resetHandler = { [weak engine] in
            try? engine?.start()
        }
        try? engine.start()
        self.engine = engine
    }

    private func playCreak() {
        guard let creakPlayer else { return }
        creakPlayer.currentTime = 0
        creakPlayer.play()
    }

    private func playTransient() {
        guard let engine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []) else { return }
        let hapticPlayer = try? engine.makePlayer(with: pattern)
        try? hapticPlayer?.start(atTime: CHHapticTimeImmediate)
    }
}

#Preview {
    ContentView()
}