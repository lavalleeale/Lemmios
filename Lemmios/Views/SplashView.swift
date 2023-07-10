import SwiftUI

struct SplashView: View {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    @AppStorage("splashAccepted") var splashAccepted = false

    var view2: some View {
        VStack {
            Text("What is the Fediverse?")
                .font(.largeTitle)
                .padding(.top, 50)
            Image("fediverse")
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 40)
            Text("The fediverse is just like email: rather than connecting to a cental server like Instagram, Twitter, or Facebook, you connect to a hub that will communicate to other hubs.")
                .font(.headline)
            Spacer()
            NavigationLink("Continue") {
                view3
                    .splashStyle(selectedTheme)
            }.buttonStyle(PositiveButton())
        }
    }

    var view3: some View {
        VStack {
            Text("How do I pick an Instance?")
                .font(.largeTitle)
                .padding(.top, 50)
            Image("lemmy")
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 40)
            Text("Your hub is easily changeable later, and don't worry about picking the wrong one since most hubs will have pulled the content from any others.")
                .font(.headline)
            Spacer()
            Button("Pick one now") {
                splashAccepted = true
            }
                .buttonStyle(PositiveButton())
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome to Lemmios!")
                    .font(.largeTitle)
                    .padding(.top, 50)
                Image("Icon")
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 40)
                Spacer()
                NavigationLink("Get Started") {
                    view2
                        .splashStyle(selectedTheme)
                }
                .buttonStyle(PositiveButton())
                Button("I Have an Instance") {
                    splashAccepted = true
                }
                    .buttonStyle(SecondaryButton())
            }
            .splashStyle(selectedTheme)
        }
    }
}

struct SplashViewPreview: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}

struct PositiveButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .padding()
            .background(Color(hex: "53B0EA"))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
    }
}

struct SecondaryButton: ButtonStyle {
    @AppStorage("selectedTheme") var selectedTheme = Theme.Default
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .padding()
            .background(selectedTheme.secondaryColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .preferredColorScheme(.dark)
    }
}
