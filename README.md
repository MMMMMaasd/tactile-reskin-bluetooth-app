
# Reskin Sensors Bluetooth Connection/Connect App
The repository is connected to Xcode, BLE App was developed in Xcode. The App can connect Reskin Sensors, monitored by Adafruit BLE microcontroller with SAM/SAMD21 help chip. The App can read data transmitted from the sensors, store it as the app's storage database, and further useful tools. 
*****
New app development updates: the app now provides an AR camera developed by Apple ARKit. The BLE App's AR camera can record real-world tracking frames used for analysis including format of: 
    - RGB video file (.mp4)  
    - Depth video file(.mp4)
    - RGB images (.png)
    - Depth images (.png)
    - Pose Data (.txt)

## Requirements and setting-up to open in Xcode
1. Install the latest version of Xcode: https://developer.apple.com/xcode/, in the GitHub, select: Code -> "Open with Xcode".
<img width="468" alt="截屏2024-06-12 13 15 33" src="https://github.com/MMMMMaasd/reskin_bluetooth_app/assets/166888204/9382ea6e-c2c2-4198-af35-e057d292cbfb">

2. After the system automatically directs you to the Xcode, press "trust and open", to save it on your computer. Make sure you are in the SwiftUI developing environment.

3. Ensure the Correct Environment Setup for the App's functionalities: In your Xcode swiftUI, click the folder button on your left sidebar called "Show the Project Navigator". Select the "USBInterfaceApp", and a new screen on your main view will be popped out. Select the target as "ReskinBLEApp" and select the "info" section. In the "Custom IOS Target Properties", in the key list, make sure the following keys are added:
    - "Privacy - Bluetooth Peripheral Usage Description"
    - "Privacy - Bluetooth Always Usage Description"
    - "Required background modes"
    - "Privacy - Camera Usage Description"
    - "Supported interface orientations (iPhone)" - Item 0: "Portrait (bottom home button)"
<img width="1377" alt="截屏2024-06-12 13 06 27" src="https://github.com/MMMMMaasd/reskin_bluetooth_app/assets/166888204/f6e9726e-6e34-4b8e-87a8-5364f5bdace5">

4. Ensure the Background Mode Configuration: In ReskinBLEApp's Signing & Capabilities, make sure the only following background mode options are enabled:
    - "External accessory communication"
    - "Uses Bluetooth LE accessories"
    - "Acts as Bluetooth LE accessories"
    - "Background fetch"
    - "Background processing"
   
## Connect to your iPhone as a Xcode developer
The published version has not been finished yet since we didn't apply to publish this app to the app store. So it can only connect to the developer's device through Xcode support. 
1. In your "Signing & Capabilities" section of the app, make sure the "Automatically manage signing" checkbox is checked.
<img width="1378" alt="截屏2024-06-12 13 09 02" src="https://github.com/MMMMMaasd/reskin_bluetooth_app/assets/166888204/c5e72148-3862-4cc9-96ba-5078061c0ef9">

2. Press command + "," to open the Accounts setting, in the Accounts section, press the bottom left plus button and add your Apple ID to it.
<img width="825" alt="截屏2024-06-12 13 11 53" src="https://github.com/MMMMMaasd/reskin_bluetooth_app/assets/166888204/556e6cbb-b03d-442f-b2f9-65e430773953">
   
3. Now plug in your IOS device to your Mac that opened with the Xcode project, and make sure to trust this computer when it pops out on your phone.
   
4. In the picking simulator section, Xcode will automatically display your local device, click it and follow the instructions popped out by Xcode.
<img width="1105" alt="截屏2024-06-12 13 13 06" src="https://github.com/MMMMMaasd/reskin_bluetooth_app/assets/166888204/d3862d94-8379-4018-8791-836b685f2870">

5. Xcode will certainly warn you to change your iPhone to developer mode, change it to develop mode, and then re-open your device (How to change to develop mode? https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device), now you should be able to connect!
 
6. Important: This way of connection will only create a temporary version of this app, it will be disabled after the next few days. You need to re-simulate the app to keep track of it. 
