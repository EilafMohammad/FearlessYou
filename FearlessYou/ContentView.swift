import SwiftUI

struct ContentView: View {
    @State private var isChallengePopupVisible = false
    @State private var selectedChallenge: String = ""
    @State private var coins = 0
    @State private var completedChallenges = Set<Int>()
    @EnvironmentObject var storyStore: StoryStore

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                HStack {
                    Image("coinLogo")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("\(coins) Coins")
                        .font(.callout)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)

                Text("FearlessYou - 30 Days of Rejection")
                    .font(.title)
                    .bold()

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(), count: 3), spacing: 5) {
                        ForEach(1..<31) { day in
                            ChallengeBox(day: day, onTap: {
                                if !isChallengeAccepted(day: day) {
                                    selectedChallenge = "Challenge \(day): \(challenges[day - 1])"
                                    isChallengePopupVisible.toggle()
                                }
                            })
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            .sheet(isPresented: $isChallengePopupVisible) {
                ChallengePopup(challengeText: selectedChallenge, coins: $coins, completedChallenges: $completedChallenges)
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
        }
    }

    func isChallengeAccepted(day: Int) -> Bool {
        return completedChallenges.contains(day)
    }
}

struct ChallengeBox: View {
    let day: Int
    let onTap: () -> Void

    @State private var showChallengeConfirmation = false

    var body: some View {
        Button(action: {
            showChallengeConfirmation.toggle()
        }) {
            VStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue)
                    .frame(width: 110, height: 110)
                    .overlay(
                        Text("\(day)")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .alert(isPresented: $showChallengeConfirmation) {
            Alert(
                title: Text("Are you ready for today's challenge?"),
                primaryButton: .default(Text("Yes"), action: onTap),
                secondaryButton: .cancel()
            )
        }
    }
}

struct ChallengePopup: View {
    let challengeText: String
    @Binding var coins: Int
    @Binding var completedChallenges: Set<Int>
    @State private var isAccepted = false
    @State private var showCountdown = false
    @State private var remainingTime = 24 * 60 * 60
    @State private var showNoCoinsAlert = false
    @State private var isChallengeComplete = false
    @State private var showFeedbackPopup = false
    @State private var selectedFeeling: String = ""
    @State private var feedbackText: String = ""

    var body: some View {
        VStack {
            Text(challengeText)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            if isAccepted || showCountdown {
                if showCountdown {
                    Text("Once you're in, you're never out")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()

                    Text(formatTime(remainingTime))
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()

                    Button(action: {
                        if isChallengeComplete {
                            showChallengeAlreadySubmittedAlert()
                        } else {
                            submitChallenge()
                            showFeedbackPopup.toggle()
                        }
                    }) {
                        Text("Submit Challenge")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            } else {
                HStack {
                    Button(action: {
                        acceptChallenge()
                    }) {
                        Text("Accept Challenge")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .disabled(isAccepted)

                    Button(action: {
                        rejectChallenge()
                    }) {
                        Text("Reject Challenge")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
            }

            if showNoCoinsAlert {
                Text("You already don't have coins to deduct. You can't move to the next challenge unless you submit this.")
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()
        }
        .onDisappear {
            saveEarnedCoinsChallenges()
        }
        .sheet(isPresented: $showFeedbackPopup) {
            FeedbackPopupView(
                isPresented: $showFeedbackPopup,
                selectedFeeling: $selectedFeeling,
                feedbackText: $feedbackText
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .padding()
    }

    private func showChallengeAlreadySubmittedAlert() {
        print("Challenge Already Submitted")
    }

    private func submitChallenge() {
        guard !isChallengeComplete else {
            return
        }

        let challengeNumber = extractChallengeNumber(from: challengeText)
        if !completedChallenges.contains(challengeNumber) {
            coins += 1
            completedChallenges.insert(challengeNumber)
            isChallengeComplete = true
        }
    }

    private func acceptChallenge() {
        isAccepted.toggle()
        showCountdown = true
        startTimer()
    }

    private func rejectChallenge() {
        if coins > 0 {
            coins -= 1
        } else {
            showNoCoinsAlert = true
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopTimer()
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }

    private func stopTimer() {
        showCountdown = false
    }

    private func extractChallengeNumber(from challengeText: String) -> Int {
        guard let range = challengeText.range(of: "\\d+", options: .regularExpression),
              let number = Int(challengeText[range]) else {
            return 0
        }
        return number
    }

    private func loadEarnedCoinsChallenges() {
        if let savedEarnedCoinsChallenges = UserDefaults.standard.array(forKey: "EarnedCoinsChallenges") as? [Int] {
            completedChallenges = Set(savedEarnedCoinsChallenges)
        }
    }

    private func saveEarnedCoinsChallenges() {
        let savedEarnedCoinsChallenges = Array(completedChallenges)
        UserDefaults.standard.set(savedEarnedCoinsChallenges, forKey: "EarnedCoinsChallenges")
    }
}

struct FeedbackPopupView: View {
    @Binding var isPresented: Bool
    @Binding var selectedFeeling: String
    @Binding var feedbackText: String

    var body: some View {
        VStack {
            Text("How do you feel after the challenge?")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding()

            HStack {
                FeelingButton(feeling: "Proud", selectedFeeling: $selectedFeeling)
                FeelingButton(feeling: "Scared", selectedFeeling: $selectedFeeling)
                FeelingButton(feeling: "Numb", selectedFeeling: $selectedFeeling)
            }
            .padding()

            Text("Share your story regarding this challenge")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .padding()

            // Add border to the TextEditor
            TextEditor(text: $feedbackText)
                .frame(height: 100)
                .padding()
                .background(Color.white) // Set the background color to white to make the border visible
                .cornerRadius(8) // Adjust the corner radius as needed
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))

            Button(action: {
                // Handle the submission of the feedback
                // You can add your logic here
                isPresented = false
            }) {
                Text("Submit")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}


struct FeelingButton: View {
    let feeling: String
    @Binding var selectedFeeling: String

    var body: some View {
        Button(action: {
            selectedFeeling = feeling
        }) {
            RoundedRectangle(cornerRadius: 15)
                .fill(selectedFeeling == feeling ? Color.blue : Color.gray)
                .frame(width: 80, height: 40)
                .overlay(
                    Text(feeling)
                        .foregroundColor(.white)
                        .font(.headline)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .padding(.horizontal)
    }
}

let challenges = [
    "Compliment a stranger on their outfit",
    "Ask a stranger for directions to a place you already know",
    "Strike up a conversation with someone waiting in line",
    "Participate in group activities that involve collaboration and interaction",
    "Share your thoughts and ideas in a group discussion",
    "Attend a social event and introduce yourself to someone new",
    "Express your opinion on a topic during a meeting",
    "Invite someone to join you for a meal or coffee",
    "Offer help to someone in need without expecting anything in return",
    "Apologize to someone you may have wronged or hurt",
    "Engage in a physical activity or sport with others",
    "Start a conversation with a coworker you haven't talked to much",
    "Visit a local place or event and interact with people there",
    "Attend a networking event and make meaningful connections",
    "Join a club or group with shared interests",
    "Take on a leadership role in a team project or activity",
    "Organize a small get-together with friends or colleagues",
    "Initiate a conversation with someone you admire",
    "Collaborate on a creative project with others",
    "Share a personal story or experience with someone",
    "Express gratitude to someone who has made a positive impact",
    "Attend a workshop or seminar and actively participate",
    "Join an online community and engage in discussions",
    "Take on a challenge outside your comfort zone",
    "Host a gathering or party for friends and acquaintances",
    "Participate in a public speaking event or presentation",
    "Connect with someone from a different background or culture",
    "Volunteer for a cause or organization in your community",
    "Reflect on your fears and identify opportunities for growth"
]


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 12 Pro")
    }
}
