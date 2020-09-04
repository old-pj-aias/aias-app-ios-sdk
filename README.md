# Aias iOS sdk
iOS SDK for aias auth system.
## Usage

(see sample Xcode project in `/exsample`)
**You need set URL scheme on you app**
- **to configure aias sdk** 
    Put this code in `application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)` on `AppDelegate`
    ```swift
    Aias.shared.configure(scheme: "your-scheme")
    ```

    Put this code in `application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any)` on `AppDelegate`
    ```swift
    Aias.shared.loadScheme(url: url)
    ```
- **sign in with aias** 
    Put this code when you want start auth process
    ```swift
    Aias.shared.auth()
    ```
- **logout** 
    Put this code when you want logout user
    ```swift
    Aias.shared.logout {}
    ```
- **data json** 
    this code returns json that caught aias format
    ```swift
    Aias.shared.encodeData(dataString: "data", token: "random-token-from-server")
    ```
- **status** 
    returns if user exsists
    ```swift
    Aias.shared.isLoggingIn
    ```