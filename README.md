
# Reskin Sensors Bluetooth Connection/Connect App
The repository is connected to Xcode, BLE App was developed in Xcode. The App is able to connect Reskin Sensors, monitored by Adafruit BLE microcontroller with SAM/SAMD21 help chip. The App can read data transimitted from the sensors, store it as app's storage database, and further useful tools. 
## Requirements and setting-up to open in Xcode
1. Install the latest version of Xcode: https://developer.apple.com/xcode/, in the GitHub, select: <Code> -> "Open with Xcode". 
2. After the system automatically directs you to the Xcode, press "trust and open", to save it on your computer. Make sure you are in the SwiftUI developing environment. 
3. Enable Bluetooth Setup: In your Xcode swiftUI, click the folder button on your left sidebar, which is called "Show the Project Navigator". Select the "USBInterfaceApp", and a new screen on your main view will be popped out. Select target as "USBInterfaceAPP" and select "info" section. In the "Custom IOS Target Properties", in the key list, press "plus" and add the following key names: 
    - "Privacy - Bluetooth Peripheral Usage Description"
    - "Privacy - Bluetooth Always Usage Description"
    - "Required background modes"
## Connect to your iPhone
The published version has not been finished yet since we didn't apply to publish this app to the app store. So it can only connect to the developer's device through Xcode support. 
1. In your "Signing & Capabilities" section of the app, make sure the "Automatically manage signing" checkbox is checked. 
2. Press command + "," to open the Accounts setting, in the accounts section, press the bottom left plus button and add your Apple ID to it. 
3. Now plug in your IOS device to your Mac that opened with the Xcode project, and make sure to trust this computer when it pops out on your phone. 
4. In the picking simulator section, Xcode will automatically display your local device, click it and follow the instructions popped out by Xcode. 
5. Xcode will certainly warn you to change your iPhone to developer mode, change it to develop mode, and then re-open your device, now you should be able to connect!
6. Important: This way of connection will only create a temporary version of this app, it will be disabled after the next few days. You need to re-simulate the app to keep track of it. 
