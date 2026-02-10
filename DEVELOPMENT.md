# DRFT Browser Development Guide

This document provides guidance for developers who want to contribute to DRFT browser and add new features beyond the base Firefox Focus functionality.

## Development Philosophy

DRFT is built on the principle of **context preservation**. Unlike traditional browsers that force you to choose between staying on your current page or opening a link, DRFT's bubble-style tabs let you do both seamlessly.

## Architecture Overview

### Core Components

1. **BubbleManager** - Manages bubble-style tabs and their lifecycle
2. **ContextPreserver** - Maintains the current page state when bubbles are opened
3. **BubbleUI** - Renders and animates the bubble interface
4. **NavigationController** - Handles transitions between bubbles and main content

### Key Directories

```
drft-core/
├── bubbles/           # Bubble-style tab implementation
│   ├── BubbleManager.kt
│   ├── BubbleView.kt
│   └── BubbleAdapter.kt
├── navigation/        # Custom navigation logic
│   ├── DRFTNavigationController.kt
│   └── ContextPreserver.kt
├── ui/               # Enhanced UI components
│   ├── BubbleToolbar.kt
│   ├── BubbleOverlay.kt
   └── DRFTTheme.kt
└── utils/            # Utility classes
    ├── DRFTPreferences.kt
    └── BubblesAnalytics.kt
```

## Feature Development Guidelines

### 1. Adding New Bubble Features

When implementing new features for bubble-style tabs:

```kotlin
// Example: Adding bubble grouping feature
class BubbleManager {
    fun createBubbleGroup(bubbles: List<Bubble>, groupName: String) {
        // Implementation for grouping related bubbles
    }
    
    fun switchToGroup(groupName: String) {
        // Switch between different bubble groups
    }
}
```

### 2. Preserving Context

Always ensure that opening a bubble doesn't disrupt the current page:

```kotlin
class ContextPreserver {
    fun preserveCurrentContext(webView: WebView): ContextSnapshot {
        // Capture current page state
        return ContextSnapshot(
            url = webView.url,
            title = webView.title,
            scrollPosition = webView.scrollY
        )
    }
    
    fun restoreContext(webView: WebView, snapshot: ContextSnapshot) {
        // Restore the saved state
    }
}
```

### 3. UI/UX Guidelines

#### Bubble Design
- Bubbles should be semi-transparent to show underlying content
- Include favicon, title preview, and close button
- Support drag-and-drop repositioning
- Animate smoothly when opening/closing

#### Interaction Patterns
- Tap link → Create bubble (don't navigate away)
- Tap bubble → Switch to bubble content
- Long press bubble → Show bubble options
- Swipe bubble away → Close bubble
- Pull to refresh → Refresh current bubble content

## Sample Code Structure

Below is an example of how you might implement a basic bubble feature:

```kotlin
// BubbleManager.kt
class BubbleManager(
    private val context: Context,
    private val container: ViewGroup
) {
    private val activeBubbles = mutableListOf<BubbleView>()
    private var currentBubble: BubbleView? = null
    
    fun createBubble(url: String, title: String, favicon: Bitmap?) {
        val bubble = BubbleView(context).apply {
            setUrl(url)
            setTitle(title)
            setFavicon(favicon)
            setOnClickListener { switchToBubble(this) }
        }
        
        activeBubbles.add(bubble)
        container.addView(bubble)
        animateBubbleIn(bubble)
    }
    
    private fun switchToBubble(bubble: BubbleView) {
        currentBubble?.pause()
        currentBubble = bubble
        bubble.resume()
        updateBubbleStates()
    }
}

// BubbleView.kt
class BubbleView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : FrameLayout(context, attrs) {
    
    private lateinit var webView: WebView
    private var isPaused = true
    
    fun setUrl(url: String) {
        webView.loadUrl(url)
    }
    
    fun pause() {
        webView.onPause()
        isPaused = true
        updateVisualState()
    }
    
    fun resume() {
        webView.onResume()
        isPaused = false
        updateVisualState()
    }
    
    private fun updateVisualState() {
        alpha = if (isPaused) 0.7f else 1.0f
        // Update other visual indicators
    }
}
```

## Integration with Firefox Focus

DRFT extends Firefox Focus by:

1. **Overriding Navigation Logic**: Intercept link clicks and create bubbles instead of navigating
2. **Adding UI Components**: Add bubble overlay and toolbar to existing layout
3. **Extending Settings**: Add DRFT-specific preferences and options
4. **Enhancing Tabs**: Replace traditional tabs with bubble-style interface

### Hooking into Focus

```kotlin
// In FocusActivity or equivalent
class DRFTBrowserActivity : FocusActivity() {
    private lateinit var bubbleManager: BubbleManager
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize DRFT components
        bubbleManager = BubbleManager(this, findViewById(R.id.bubble_container))
        
        // Override link clicking behavior
        setupBubbleNavigation()
    }
    
    private fun setupBubbleNavigation() {
        webView.setWebViewClient(object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                val url = request?.url?.toString()
                if (url != null && shouldOpenInBubble(url)) {
                    bubbleManager.createBubble(url, view?.title, getFavicon())
                    return true // Prevent default navigation
                }
                return false // Use default behavior
            }
        })
    }
}
```

## Testing Your Changes

### Unit Testing
```kotlin
@Test
fun `test bubble creation preserves context`() {
    val initialContext = contextPreserver.captureCurrentState(webView)
    bubbleManager.createBubble("https://example.com", "Example", null)
    val currentContext = contextPreserver.captureCurrentState(webView)
    
    assertEquals(initialContext.url, currentContext.url)
    assertEquals(initialContext.scrollPosition, currentContext.scrollPosition)
}
```

### UI Testing
```kotlin
@Test
fun `test bubble interaction`() {
    // Test tapping on bubble switches to it
    onView(withId(R.id.bubble_1)).perform(click())
    onView(withId(R.id.webview)).check(matches(isDisplayed()))
    
    // Test swiping away closes bubble
    onView(withId(R.id.bubble_1)).perform(swipeLeft())
    onView(withId(R.id.bubble_1)).check(doesNotExist())
}
```

## Contributing Guidelines

1. **Follow Android Development Best Practices**
   - Use MVVM architecture where applicable
   - Follow Material Design guidelines for DRFT-specific components
   - Write comprehensive tests for new features

2. **Maintain Performance**
   - Bubbles should pause when not active to save resources
   - Monitor memory usage with multiple bubbles
   - Optimize webview lifecycle management

3. **Privacy and Security**
   - All bubble data should be handled with the same privacy standards as Firefox Focus
   - Ensure bubble content is properly isolated
   - Implement proper cleanup when bubbles are closed

4. **Documentation**
   - Document new bubble features in BUBBLES.md
   - Update code comments for complex interactions
   - Include screenshots/GIFs for new bubble behaviors

## Building and Testing

```bash
# Initialize development environment
./scripts/dev.sh init

# Make your changes

# Build and test locally
./scripts/dev.sh build
./scripts/dev.sh run

# Run tests
./gradlew testDebugUnitTest
./gradlew connectedDebugAndroidTest
```

## Future Feature Ideas

- **Bubble Groups**: Organize related bubbles into groups
- **Bubble History**: Timeline view of recently closed bubbles
- **Smart Bubbles**: AI-suggested bubbles based on browsing patterns
- **Bubble Sharing**: Share bubble states between devices
- **Gestures**: Advanced gestures for bubble management
- **Themes**: Customizable bubble appearances and animations

Remember: DRFT's core value is **preserving mental context**. Every feature should enhance this core principle without adding complexity.