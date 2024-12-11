import SwiftUI

struct ContentView: View {
    @State private var phoneNumber: String = UserDefaults.standard.string(forKey: "userPhoneNumber") ?? ""
    @State private var message: String = ""
    @State private var isLoading: Bool = false

    private var apiURL: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let url = dict["API_URL"] as? String else {
            fatalError("API_URL not found in Secrets.plist")
        }
        return url
    }

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                HStack {
                    Text("🇺🇸")
                        .font(.largeTitle)
                        .padding(.leading)
                    TextField("(555) 555-5555", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .cornerRadius(20)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .onChange(of: phoneNumber, initial: false) { oldValue, newValue in
                            phoneNumber = formatPhoneNumber(newValue)
                            UserDefaults.standard.set(phoneNumber, forKey: "userPhoneNumber")
                        }
                        .padding(.trailing)
                }
                .frame(maxWidth: .infinity)

                if isLoading {
                    ProgressView("CALLING...")
                        .foregroundColor(.white)
                } else {
                    Button(action: makeApiCall) {
                        Text("GET ME OUT OF HERE!")
                            .font(.title2)
                            .bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .cornerRadius(20)
                    }
                    .padding(.horizontal)
                }

                if !message.isEmpty {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
        }
    }

    func makeApiCall() {
        guard !phoneNumber.isEmpty else {
            message = "Please enter a valid phone number."
            return
        }

        isLoading = true
        let fullPhoneNumber = "+1" + phoneNumber.filter { $0.isNumber }
        let encodedPhoneNumber = fullPhoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fullPhoneNumber

        guard let url = URL(string: "\(apiURL)?phone_number=\(encodedPhoneNumber)") else {
            message = "Invalid API URL."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    message = "Error: \(error.localizedDescription)"
                    return
                }

                guard let data = data else {
                    message = "No response data received."
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let responseMessage = jsonResponse["message"] as? String {
                        message = responseMessage
                    } else {
                        message = "Unexpected response format."
                    }
                } catch {
                    message = "Failed to parse response."
                }
            }
        }.resume()
    }

    func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }

        var formatted = ""
        let count = digits.count

        if count > 0 {
            formatted.append("(")
        }
        if count >= 1 {
            let start = digits.startIndex
            let end = digits.index(start, offsetBy: min(3, count))
            formatted.append(contentsOf: digits[start..<end])
        }
        if count >= 4 {
            let middleStart = digits.index(digits.startIndex, offsetBy: 3)
            let middleEnd = digits.index(middleStart, offsetBy: min(3, count - 3))
            formatted.append(") ")
            formatted.append(contentsOf: digits[middleStart..<middleEnd])
        }
        if count >= 7 {
            let lastStart = digits.index(digits.startIndex, offsetBy: 6)
            let lastEnd = digits.index(lastStart, offsetBy: min(4, count - 6))
            formatted.append("-")
            formatted.append(contentsOf: digits[lastStart..<lastEnd])
        }

        return String(formatted.prefix(14))
    }
}
