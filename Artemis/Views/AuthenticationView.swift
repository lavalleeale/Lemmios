import SwiftUI
import WebKit

struct AuthenticationView: View {
    @EnvironmentObject var apiModel: ApiModel
    @State var showSafari = false
    @State var urlSuffix = "/login"
    var body: some View {
        ZStack {
            if !apiModel.serverSelected {
                ServerSelectorView()
            } else if apiModel.accounts.count == 0 {
                VStack {
                    Text("No accounts found")
                    Button("Sign in") {
                        urlSuffix = "/login"
                        showSafari.toggle()
                    }
                    Button("Sign up") {
                        urlSuffix = "/signup"
                        showSafari.toggle()
                    }
                }
            } else {
                NavigationView {
                    List(apiModel.accounts) { account in
                        Button {
                            apiModel.selectAuth(username: account.username)
                        } label: {
                            HStack {
                                Text(account.username)
                                Spacer()
                                if account.username == apiModel.selectedAccount {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .swipeActions {
                                Button {
                                    apiModel.deleteAuth(username: account.username)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .toolbar {
                        Menu {
                            Button("Sign in") {
                                urlSuffix = "/login"
                                showSafari.toggle()
                            }
                            Button("Sign up") {
                                urlSuffix = "/signup"
                                showSafari.toggle()
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showSafari, content: {
            NavigationView {
                WebView(url: URL(string: apiModel.url + urlSuffix)!) { username, jwt in
                    apiModel.addAuth(username: username, jwt: jwt)
                    showSafari = false
                }
                .toolbar {
                    Button("Done") {
                        showSafari = false
                    }
                }
            }
        })
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    var webview: WKWebView?

    init(url: URL, jwtHandler: @escaping (_: String, _: String) -> Void) {
        let handler = ScriptMessageHandler(jwtHandler: jwtHandler)
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(handler, name: "test")
        config.userContentController = userContentController
        self.webview = WKWebView(frame: .zero, configuration: config)
        self.webview!.setPullToRefresh()
        handler.webview = self.webview
        self.url = url
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("let previousUrl='';const observer=new MutationObserver(function(){location.href!==previousUrl&&(previousUrl=location.href,window.webkit.messageHandlers.test.postMessage(document.querySelector('#dropdownUser > button').innerText))}),config={subtree:true,childList:true};observer.observe(document,config);")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        return self.webview!
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.navigationDelegate = context.coordinator
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                for: records)
            {
                uiView.load(URLRequest(url: self.url))
            }
        }
    }
}

class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    var webview: WKWebView?
    let jwtHandler: (_: String, _: String) -> Void

    init(jwtHandler: @escaping (_: String, _: String) -> Void) {
        self.jwtHandler = jwtHandler
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.webview?.configuration.processPool = WKProcessPool()
        self.webview?.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            cookies.forEach { cookie in
                if cookie.name == "jwt" {
                    self.jwtHandler(message.body as! String, cookie.value)
                }
            }
        }
    }
}

extension WKWebView {
    var refreshControl: UIRefreshControl? {
        (scrollView.getAllSubviews() as [UIRefreshControl]).first
    }

    func setPullToRefresh() {
        (scrollView.getAllSubviews() as [UIRefreshControl]).forEach {
            $0.removeFromSuperview()
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.webViewPullToRefreshHandler(source:)), for: .valueChanged)
        scrollView.addSubview(refreshControl)
    }

    @objc func webViewPullToRefreshHandler(source: UIRefreshControl) {
        guard let url = self.url else {
            source.endRefreshing()
            return
        }
        load(URLRequest(url: url))
    }
}

extension UIView {
    class func getAllSubviews<T: UIView>(from parentView: UIView) -> [T] {
        return parentView.subviews.flatMap { subView -> [T] in
            var result = getAllSubviews(from: subView) as [T]
            if let view = subView as? T {
                result.append(view)
            }
            return result
        }
    }

    func getAllSubviews<T: UIView>() -> [T] {
        return UIView.getAllSubviews(from: self) as [T]
    }
}
