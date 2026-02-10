# DRFT Sample Code Structure

This directory contains sample implementations for DRFT browser's bubble-style tabs feature. Use these as reference implementations when developing new features.

## Directory Structure

```
drft-core/
├── bubbles/                    # Bubble-style tabs implementation
│   ├── BubbleManager.kt       # Manages bubble lifecycle and state
│   ├── BubbleView.kt          # Individual bubble UI component
│   ├── BubbleAdapter.kt       # Adapter for bubble collections
│   ├── BubbleAnimation.kt     # Bubble entrance/exit animations
│   └── BubbleState.kt         # Bubble state data class
├── navigation/                # Custom navigation logic
│   ├── DRFTNavigationController.kt  # Main navigation controller
│   ├── ContextPreserver.kt    # Preserves current page context
│   ├── BubbleNavigator.kt     # Handles bubble-specific navigation
│   └── LinkInterceptor.kt     # Intercepts link clicks for bubble creation
├── ui/                        # Enhanced UI components
│   ├── BubbleToolbar.kt       # Toolbar with bubble controls
│   ├── BubbleOverlay.kt       # Overlay for bubble display
│   ├── BubbleIndicator.kt     # Visual indicators for bubble states
│   ├── DRFTTheme.kt          # DRFT-specific theme and styling
│   └── BubbleSettings.kt     # Settings UI for bubble preferences
├── utils/                     # Utility classes
│   ├── DRFTPreferences.kt     # Shared preferences management
│   ├── BubblesAnalytics.kt    # Analytics for bubble usage
│   ├── BubbleStorage.kt       # Persistent bubble storage
│   └── WebViewHelper.kt      # WebView utility functions
└── experiments/               # Experimental features
    ├── BubbleGroups.kt        # Bubble grouping functionality
    ├── SmartBubbles.kt        # AI-suggested bubbles
    └── GestureController.kt   # Advanced gesture recognition
```

## Core Implementation Examples

### BubbleManager.kt

```kotlin
package org.drft.bubbles

import android.content.Context
import android.view.ViewGroup
import kotlinx.coroutines.*

class BubbleManager(
    private val context: Context,
    private val container: ViewGroup,
    private val coroutineScope: CoroutineScope = MainScope()
) {
    private val activeBubbles = mutableListOf<BubbleView>()
    private var currentBubble: BubbleView? = null
    private var maxBubbles = 10
    private val bubbleStorage = BubbleStorage(context)
    
    init {
        loadSavedBubbles()
    }
    
    /**
     * Creates a new bubble with the given URL
     */
    fun createBubble(url: String, title: String = "", favicon: Bitmap? = null): BubbleView {
        if (activeBubbles.size >= maxBubbles) {
            removeOldestBubble()
        }
        
        val bubble = BubbleView(context).apply {
            setUrl(url)
            setTitle(title.ifEmpty { "New Bubble" })
            setFavicon(favicon)
            setOnClickListener { switchToBubble(this) }
            setOnLongClickListener { showBubbleMenu(this); true }
        }
        
        activeBubbles.add(bubble)
        container.addView(bubble)
        animateBubbleIn(bubble)
        
        // Save bubble state
        coroutineScope.launch {
            bubbleStorage.saveBubble(bubble.toState())
        }
        
        return bubble
    }
    
    /**
     * Switches to the specified bubble
     */
    fun switchToBubble(bubble: BubbleView) {
        currentBubble?.pause()
        currentBubble = bubble
        bubble.resume()
        updateBubbleStates()
        
        // Track analytics
        coroutineScope.launch {
            BubblesAnalytics.trackBubbleSwitch(bubble.id)
        }
    }
    
    /**
     * Removes a bubble and cleans up resources
     */
    fun removeBubble(bubble: BubbleView) {
        bubble.pause()
        animateBubbleOut(bubble) {
            container.removeView(bubble)
            activeBubbles.remove(bubble)
            
            if (currentBubble == bubble) {
                currentBubble = activeBubbles.lastOrNull()
                currentBubble?.resume()
            }
            
            updateBubbleStates()
            
            // Remove from storage
            coroutineScope.launch {
                bubbleStorage.deleteBubble(bubble.id)
            }
        }
    }
    
    /**
     * Clears all bubbles
     */
    fun clearAllBubbles() {
        activeBubbles.forEach { bubble ->
            bubble.pause()
            animateBubbleOut(bubble) {
                container.removeView(bubble)
            }
        }
        activeBubbles.clear()
        currentBubble = null
        
        coroutineScope.launch {
            bubbleStorage.clearAllBubbles()
        }
    }
    
    private fun updateBubbleStates() {
        activeBubbles.forEachIndexed { index, bubble ->
            bubble.setState(if (bubble == currentBubble) BubbleState.ACTIVE else BubbleState.INACTIVE)
            bubble.setZIndex(activeBubbles.size - index) // Stack bubbles correctly
        }
    }
    
    private fun animateBubbleIn(bubble: BubbleView) {
        bubble.alpha = 0f
        bubble.scaleX = 0.8f
        bubble.scaleY = 0.8f
        
        bubble.animate()
            .alpha(1f)
            .scaleX(1f)
            .scaleY(1f)
            .setDuration(200)
            .setInterpolator(OvershootInterpolator())
            .start()
    }
    
    private fun animateBubbleOut(bubble: BubbleView, onComplete: () -> Unit) {
        bubble.animate()
            .alpha(0f)
            .scaleX(0.8f)
            .scaleY(0.8f)
            .setDuration(150)
            .withEndAction(onComplete)
            .start()
    }
}
```

### BubbleView.kt

```kotlin
package org.drft.bubbles

import android.content.Context
import android.graphics.Bitmap
import android.util.AttributeSet
import android.webkit.WebView
import android.widget.FrameLayout
import androidx.cardview.widget.CardView

class BubbleView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : CardView(context, attrs, defStyleAttr) {
    
    private lateinit var webView: WebView
    private lateinit var titleView: TextView
    private lateinit var faviconView: ImageView
    private lateinit var closeButton: ImageButton
    
    private var url: String = ""
    private var title: String = ""
    private var favicon: Bitmap? = null
    private var state: BubbleState = BubbleState.INACTIVE
    private var isPaused: Boolean = true
    
    val id: String = UUID.randomUUID().toString()
    
    init {
        initializeView()
    }
    
    private fun initializeView() {
        radius = 16.dp.toFloat()
        cardElevation = 8.dp.toFloat()
        
        // Create bubble layout
        LayoutInflater.from(context).inflate(R.layout.bubble_view, this, true)
        
        webView = findViewById(R.id.bubble_webview)
        titleView = findViewById(R.id.bubble_title)
        faviconView = findViewById(R.id.bubble_favicon)
        closeButton = findViewById(R.id.bubble_close)
        
        setupWebView()
        setupInteractions()
    }
    
    private fun setupWebView() {
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            setSupportZoom(true)
            builtInZoomControls = false
            displayZoomControls = false
        }
        
        webView.webViewClient = BubbleWebViewClient()
        webView.webChromeClient = BubbleWebChromeClient()
    }
    
    private fun setupInteractions() {
        closeButton.setOnClickListener {
            // Notify parent to remove this bubble
            (parent as? ViewGroup)?.let { parent ->
                BubbleManager.getInstance(context)?.removeBubble(this)
            }
        }
    }
    
    fun setUrl(url: String) {
        this.url = url
        if (webView.url != url) {
            webView.loadUrl(url)
        }
    }
    
    fun setTitle(title: String) {
        this.title = title
        titleView.text = title
    }
    
    fun setFavicon(favicon: Bitmap?) {
        this.favicon = favicon
        faviconView.setImageBitmap(favicon ?: getDefaultFavicon())
    }
    
    fun setState(state: BubbleState) {
        this.state = state
        updateVisualState()
    }
    
    fun pause() {
        isPaused = true
        webView.onPause()
        webView.pauseTimers()
        updateVisualState()
    }
    
    fun resume() {
        isPaused = false
        webView.onResume()
        webView.resumeTimers()
        updateVisualState()
    }
    
    private fun updateVisualState() {
        when (state) {
            BubbleState.ACTIVE -> {
                alpha = 1f
                setCardBackgroundColor(ContextCompat.getColor(context, R.color.bubble_active))
                titleView.setTextColor(ContextCompat.getColor(context, R.color.bubble_title_active))
            }
            BubbleState.INACTIVE -> {
                alpha = 0.85f
                setCardBackgroundColor(ContextCompat.getColor(context, R.color.bubble_inactive))
                titleView.setTextColor(ContextCompat.getColor(context, R.color.bubble_title_inactive))
            }
            BubbleState.LOADING -> {
                alpha = 0.9f
                setCardBackgroundColor(ContextCompat.getColor(context, R.color.bubble_loading))
            }
        }
        
        // Update pause state visual
        if (isPaused) {
            titleView.alpha = 0.7f
            faviconView.alpha = 0.7f
        } else {
            titleView.alpha = 1f
            faviconView.alpha = 1f
        }
    }
    
    fun toState(): BubbleStateData {
        return BubbleStateData(
            id = id,
            url = url,
            title = title,
            favicon = favicon,
            state = state,
            isPaused = isPaused,
            timestamp = System.currentTimeMillis()
        )
    }
    
    fun fromState(stateData: BubbleStateData) {
        setUrl(stateData.url)
        setTitle(stateData.title)
        setFavicon(stateData.favicon)
        setState(stateData.state)
        
        if (stateData.isPaused) {
            pause()
        } else {
            resume()
        }
    }
}
```

### LinkInterceptor.kt

```kotlin
package org.drft.navigation

import android.content.Context
import android.view.View
import android.webkit.WebView
import kotlinx.coroutines.*

class LinkInterceptor(
    private val context: Context,
    private val bubbleManager: BubbleManager,
    private val contextPreserver: ContextPreserver
) : WebViewClient() {
    
    private val coroutineScope = MainScope()
    private val drftPreferences = DRFTPreferences(context)
    
    override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
        val url = request?.url?.toString() ?: return false
        
        if (shouldOpenInBubble(url)) {
            openLinkInBubble(view!!, url)
            return true // Prevent default navigation
        }
        
        return false // Use default behavior
    }
    
    override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
        if (url != null && shouldOpenInBubble(url)) {
            openLinkInBubble(view!!, url)
            return true
        }
        return false
    }
    
    private fun shouldOpenInBubble(url: String): Boolean {
        // Don't open in bubble for:
        // 1. File downloads
        // 2. JavaScript protocols
        // 3. Same page navigation
        // 4. User disabled bubbles for certain domains
        
        if (url.startsWith("file://") || 
            url.startsWith("javascript:") ||
            url.startsWith("tel:") ||
            url.startsWith("mailto:")) {
            return false
        }
        
        // Check user preferences
        val domain = url.toHttpUrl().host
        if (drftPreferences.isDomainBlockedForBubbles(domain)) {
            return false
        }
        
        // Check if user has bubble mode enabled
        return drftPreferences.isBubbleModeEnabled()
    }
    
    private fun openLinkInBubble(webView: WebView, url: String) {
        // Preserve current context
        val contextSnapshot = contextPreserver.captureCurrentState(webView)
        
        // Get favicon and title
        val favicon = getFaviconFromWebView(webView)
        val title = webView.title ?: "Loading..."
        
        // Create bubble
        coroutineScope.launch {
            try {
                bubbleManager.createBubble(url, title, favicon)
                
                // Track analytics
                BubblesAnalytics.trackBubbleCreation(url, "link_click")
                
                // Show subtle animation feedback
                showBubbleCreationFeedback(webView)
                
            } catch (e: Exception) {
                // Fallback to regular navigation if bubble creation fails
                webView.loadUrl(url)
                BubblesAnalytics.trackBubbleCreationError(url, e.message)
            }
        }
    }
    
    private fun showBubbleCreationFeedback(webView: WebView) {
        // Subtle animation to indicate bubble was created
        webView.animate()
            .scaleX(0.98f)
            .scaleY(0.98f)
            .setDuration(100)
            .withEndAction {
                webView.animate()
                    .scaleX(1f)
                    .scaleY(1f)
                    .setDuration(100)
                    .start()
            }
            .start()
    }
}
```

### DRFTNavigationController.kt

```kotlin
package org.drft.navigation

import android.content.Context
import android.view.ViewGroup
import androidx.fragment.app.FragmentActivity

class DRFTNavigationController(
    private val activity: FragmentActivity,
    private val container: ViewGroup
) {
    
    private lateinit var bubbleManager: BubbleManager
    private lateinit var contextPreserver: ContextPreserver
    private lateinit var linkInterceptor: LinkInterceptor
    
    fun initialize() {
        bubbleManager = BubbleManager(activity, container)
        contextPreserver = ContextPreserver(activity)
        linkInterceptor = LinkInterceptor(activity, bubbleManager, contextPreserver)
        
        setupWebViewInterception()
        setupGestureHandling()
    }
    
    private fun setupWebViewInterception() {
        // Find the main WebView and apply our link interceptor
        val mainWebView = findMainWebView()
        mainWebView?.webViewClient = linkInterceptor
    }
    
    private fun setupGestureHandling() {
        // Setup swipe gestures for bubble management
        val gestureDetector = GestureDetector(activity, BubbleGestureListener())
        
        container.setOnTouchListener { _, event ->
            gestureDetector.onTouchEvent(event)
            false // Allow other touch events to pass through
        }
    }
    
    private inner class BubbleGestureListener : GestureDetector.SimpleOnGestureListener() {
        override fun onFling(
            e1: MotionEvent?,
            e2: MotionEvent,
            velocityX: Float,
            velocityY: Float
        ): Boolean {
            val deltaX = e2.x - (e1?.x ?: 0f)
            val deltaY = e2.y - (e1?.y ?: 0f)
            
            // Detect horizontal swipe to close bubbles
            if (abs(deltaX) > abs(deltaY) && abs(deltaX) > SWIPE_THRESHOLD) {
                val bubble = findBubbleUnder(e2.x, e2.y)
                if (bubble != null) {
                    bubbleManager.removeBubble(bubble)
                    return true
                }
            }
            
            return false
        }
        
        override fun onLongPress(e: MotionEvent) {
            // Show bubble options on long press
            val bubble = findBubbleUnder(e.x, e.y)
            if (bubble != null) {
                showBubbleOptions(bubble)
            }
        }
    }
    
    companion object {
        private const val SWIPE_THRESHOLD = 100f
    }
}
```

## How to Use These Examples

1. **Copy the relevant files** to your project under the appropriate packages
2. **Update package names** to match your project structure
3. **Add required resources** (layouts, drawables, colors) to your res/ directory
4. **Integrate with Focus** by hooking into the existing Focus activities
5. **Customize behavior** based on your specific requirements

## Integration Points with Firefox Focus

### 1. Extend BrowserFragment

```kotlin
// In your custom BrowserFragment
class DRFTBrowserFragment : BrowserFragment() {
    
    private lateinit var drftNavController: DRFTNavigationController
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        // Initialize DRFT components
        val bubbleContainer = view.findViewById<ViewGroup>(R.id.bubble_container)
        drftNavController = DRFTNavigationController(requireActivity(), bubbleContainer)
        drftNavController.initialize()
    }
}
```

### 2. Update Settings

```kotlin
// Add DRFT preferences to Focus settings
class DRFTSettingsFragment : PreferencesFragment() {
    
    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        super.onCreatePreferences(savedInstanceState, rootKey)
        
        addPreferencesFromResource(R.xml.drft_preferences)
        
        // Setup bubble mode toggle
        val bubbleModePref = findPreference<SwitchPreferenceCompat>("bubble_mode_enabled")
        bubbleModePref?.setOnPreferenceChangeListener { _, newValue ->
            val enabled = newValue as Boolean
            DRFTPreferences(requireContext()).setBubbleModeEnabled(enabled)
            true
        }
    }
}
```

This sample codebase provides a solid foundation for implementing DRFT's bubble-style tabs while maintaining compatibility with Firefox Focus's existing architecture.