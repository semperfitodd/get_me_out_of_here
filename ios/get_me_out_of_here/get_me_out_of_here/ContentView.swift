import SwiftUI

struct ContentView: View {
    @State private var phoneNumber: String = UserDefaults.standard.string(forKey: "userPhoneNumber") ?? ""
    @State private var customMessage: String = ""
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

    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["API_KEY"] as? String else {
            fatalError("API_KEY not found in Secrets.plist")
        }
        return key
    }

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                HStack {
                    Text("🇺🇸")
                        .font(.largeTitle)
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
                }
                .frame(maxWidth: .infinity, maxHeight: 60)

                if isLoading {
                    ProgressView("CALLING...")
                        .foregroundColor(.white)
                } else {
                    VStack(spacing: 10) {
                        ActionButton(title: "BOSS", endpoint: "boss", makeApiCall: makeApiCall)
                        ActionButton(title: "MOM", endpoint: "mom", makeApiCall: makeApiCall)
                        ActionButton(title: "POLICE", endpoint: "police", makeApiCall: makeApiCall)
                        ActionButton(title: "SISTER", endpoint: "sister", makeApiCall: makeApiCall)

                        TextField("Custom message", text: $customMessage)
                            .padding()
                            .background(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                            .cornerRadius(20)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            makeApiCall(endpoint: "custom", customMessage: customMessage)
                        }) {
                            Text("SEND CUSTOM MESSAGE")
                                .font(.title2)
                                .bold()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                                .cornerRadius(20)
                        }
                        .padding(.horizontal)
                    }
                }

                Text("GET ME OUT OF HERE!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 30)

                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func makeApiCall(endpoint: String, customMessage: String? = nil) {
        guard !phoneNumber.isEmpty else {
            message = "Please enter a valid phone number."
            return
        }

        isLoading = true
        let fullPhoneNumber = "+1" + phoneNumber.filter { $0.isNumber }
        let encodedPhoneNumber = fullPhoneNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fullPhoneNumber

        var urlString = "\(apiURL)/\(endpoint)?phone_number=\(encodedPhoneNumber)"
        if endpoint == "custom", let customMessage = customMessage {
            let encodedMessage = customMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            urlString += "&custom_message=\(encodedMessage)"
        }

        guard let url = URL(string: urlString) else {
            message = "Invalid API URL."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")

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

struct ActionButton: View {
    let title: String
    let endpoint: String
    let makeApiCall: (String, String?) -> Void

    var body: some View {
        Button(action: { makeApiCall(endpoint, nil) }) {
            Text(title)
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
}
