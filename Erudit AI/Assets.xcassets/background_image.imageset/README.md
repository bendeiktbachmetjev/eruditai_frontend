# Background Image Setup

## How to add background photo to AuthView

### Step 1: Add your image file
Place your background image in this folder:
- `background_image.png` (одно изображение)

### Step 2: Image requirements
- **Format**: PNG or JPG
- **Aspect ratio**: 3:4 (portrait) - оптимально для мобильных экранов
- **Resolution**: 750x1000 пикселей (подходит для всех iPhone)

### Alternative aspect ratios (если нужно):
- **Квадратное**: 1:1 (750x750)
- **Широкое**: 4:3 (1000x750)
- **Стандартное мобильное**: 9:16 (750x1334)

### Step 3: Recommended image characteristics
- **Style**: Nature landscapes, abstract patterns, or minimal designs
- **Colors**: Soft, muted tones that work well with glassmorphism
- **Contrast**: Not too high contrast to maintain text readability
- **Content**: Avoid busy patterns that might interfere with UI elements

### Step 4: Alternative approach
If you want to use a different image name, update the code in `AuthView.swift`:

```swift
// Change this line:
if let backgroundImage = UIImage(named: "background_image") {

// To your image name:
if let backgroundImage = UIImage(named: "your_image_name") {
```

### Step 5: Testing
After adding images, build and run the app to see the background effect with glassmorphism overlay.
