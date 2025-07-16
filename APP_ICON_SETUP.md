# Setting Up Your App Icon

## Option 1: Using Xcode (Easiest)

1. **Open your project in Xcode**
2. **Navigate to Assets.xcassets** in the project navigator
3. **Click on AppIcon** in the asset catalog
4. **Drag and drop your icon images** into the appropriate slots
   - You'll need a 1024x1024 image for the App Store
   - Xcode will automatically generate other sizes

## Option 2: Using the Icon Generator Script

1. **Prepare your icon image** (at least 1024x1024 pixels, PNG format)
2. **Run the generator script:**
   ```bash
   swift generate_app_icon.swift your_icon.png ./AppIcons
   ```
3. **Copy the generated files** to your `AppIcon.appiconset` folder
4. **Update the Contents.json** file to reference the new images

## Option 3: Manual Setup

### Required Icon Sizes for iOS:
- **1024x1024** - App Store
- **180x180** - iPhone 6 Plus and later
- **167x167** - iPad Pro
- **152x152** - iPad, iPad mini
- **120x120** - iPhone 4 and later
- **87x87** - iPhone 6 Plus and later
- **80x80** - Spotlight
- **76x76** - iPad
- **60x60** - iPhone
- **40x40** - Spotlight

### Steps:
1. Create icons in all required sizes
2. Name them appropriately (e.g., `1024x1024.png`, `180x180.png`)
3. Add them to the `AppIcon.appiconset` folder
4. Update the `Contents.json` file to reference each image

## Icon Design Guidelines

- **Keep it simple** - Icons should be recognizable at small sizes
- **Use solid colors** - Avoid gradients and complex patterns
- **Test at small sizes** - Make sure it looks good at 40x40
- **Follow Apple's guidelines** - No transparency, no rounded corners (iOS adds them automatically)
- **Use PNG format** - Best quality for icons

## Testing Your Icon

After setting up your icon:
1. **Clean and rebuild** your project in Xcode
2. **Run on simulator** to see how it looks
3. **Test on device** if possible
4. **Check different backgrounds** (light/dark mode)

## Troubleshooting

- **Icon not showing**: Clean build folder and rebuild
- **Blurry icon**: Make sure you're using the correct resolution
- **Wrong size**: Check that all required sizes are present
- **Build errors**: Verify the Contents.json file is valid JSON 