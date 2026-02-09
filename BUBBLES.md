# DRFT (Drift Browser) - Bubble-Style Tabs Implementation

## Concept Overview

DRFT introduces a revolutionary browsing paradigm with **bubble-style tabs** that address the core pain points of traditional mobile browsing:

### The Problem with Traditional Tabs
- **Context Loss**: Switching tabs means losing your current page view
- **Cognitive Overhead**: Managing dozens of tabs creates mental stress
- **Interruption Flow**: Jumping between tabs breaks reading/thought patterns
- **UI Clutter**: Tab bars take up valuable screen space

### DRFT's Solution: Bubble-Style Tabs

#### 🫧 Floating Bubbles
- Links open in floating bubbles that overlay your current content
- Your original page remains visible and accessible
- Bubbles can be positioned anywhere on screen
- Natural physics-based bubble movement

#### ⚡ Instant Context Switching
- Tap any bubble to instantly view its content
- Swipe to minimize bubbles and return to main content
- No full-page reloads or navigation delays
- Preserve scroll position and form inputs

#### 🧘 Batch Operations
- Long-press bubbles for batch selection
- Close multiple bubbles with one gesture
- Group related bubbles for organization
- Archive bubble sessions for later

#### 🔄 Adaptive Layout
- Bubbles automatically resize based on content
- Smart positioning to avoid overlap
- Keyboard-aware bubble management
- Responsive to device orientation

## Implementation Architecture

### Core Components

#### 1. BubbleManager
```kotlin
class BubbleManager {
    // Create, position, and manage bubble lifecycle
    fun createBubble(url: String, parentView: View)
    fun updateBubblePosition(bubble: Bubble, x: Float, y: Float)
    fun closeBubble(bubble: Bubble, animate: Boolean = true)
    fun closeAllBubbles(except: Bubble? = null)
}
```

#### 2. BubbleView
```kotlin
class BubbleView : FrameLayout {
    // Custom floating bubble with physics simulation
    fun attachToWindow(windowManager: WindowManager)
    fun setVelocity(vx: Float, vy: Float)
    fun onTapped(bubble: Bubble)
    fun onLongPressed(bubble: Bubble)
}
```

#### 3. BubbleContentProvider
```kotlin
interface BubbleContentProvider {
    suspend fun loadContent(url: String): BubbleContent
    suspend fun preloadContent(urls: List<String>)
    fun cacheContent(content: BubbleContent)
}
```

### User Interaction Patterns

#### Opening Bubbles
1. **Link Tap**: Opens in bubble after 300ms delay (cancelable)
2. **Long Press**: Force open in bubble immediately  
3. **Gestures**: Swipe up on link to create bubble
4. **Context Menu**: "Open in Bubble" option

#### Managing Bubbles
1. **Single Tap**: Maximize and focus bubble
2. **Double Tap**: Minimize bubble to thumbnail
3. **Long Press**: Enter selection mode
4. **Drag**: Reposition bubble on screen
5. **Flick**: Apply physics velocity to bubble

#### Batch Operations
1. **Selection Mode**: Long press any bubble
2. **Multi-Select**: Tap additional bubbles
3. **Batch Actions**: Close, archive, or group selected
4. **Keyboard Shortcuts**: Ctrl+Click for multi-select

## Technical Implementation

### Rendering System
- **SurfaceView**: Hardware-accelerated bubble rendering
- **Physics Engine**: Verlet integration for natural movement
- **Gesture Recognition**: Custom gesture detector for bubble interactions
- **Memory Management**: Efficient texture recycling and caching

### Performance Optimizations
- **Content Preloading**: Background loading of bubble content
- **Intelligent Caching**: LRU cache with size-based eviction
- **Lazy Loading**: Only render visible bubbles
- **Memory Pooling**: Reuse bubble view instances

### Accessibility
- **Screen Reader Support**: Bubble announcements and navigation
- **High Contrast**: Bubble border and background adjustments
- **Large Text**: Scalable text within bubbles
- **Switch Navigation**: Full keyboard control support

## Customization Options

### Appearance
- **Bubble Size**: Small, medium, large (auto or fixed)
- **Opacity**: Transparent to fully opaque bubbles
- **Borders**: Color, thickness, and style options
- **Shadows**: Depth and blur effect controls

### Behavior
- **Physics**: Gravity strength, friction, and bounce settings
- **Positioning**: Auto-arrange or free-form placement
- **Persistence**: Save bubble sessions across app restarts
- **Interruptions**: Bubble behavior during calls/videos

### Productivity
- **Session Management**: Auto-archiving of old bubbles
- **Focus Mode**: Temporarily hide all bubbles
- **Workspaces**: Named bubble groups for different tasks
- **Shortcuts**: Quick actions for common bubble operations

## Roadmap

### Phase 1: Core Functionality
- [x] Basic bubble creation and management
- [x] Touch interaction handling
- [x] Simple physics simulation
- [ ] Content loading in bubbles

### Phase 2: Advanced Features  
- [ ] Batch operations
- [ ] Bubble persistence
- [ ] Customization options
- [ ] Performance optimizations

### Phase 3: AI Integration
- [ ] Smart bubble grouping
- [ ] Contextual bubble suggestions
- [ ] Usage pattern learning
- [ ] Predictive content loading

## Design Principles

1. **Non-Intrusive**: Bubbles enhance, don't replace main content
2. **Instantaneous**: All bubble operations feel immediate
3. **Forgiving**: No wrong way to interact with bubbles
4. **Accessible**: Full functionality for all users
5. **Efficient**: Minimal battery and memory impact

DRFT's bubble-style tabs represent the next evolution in mobile browsing, putting user focus and mental clarity at the center of the experience.