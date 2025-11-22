# Apple Music Integration Guide

## Current Implementation
Your app currently uses the **iTunes Search API** which provides:
- ✅ **FREE** - No authentication required
- ✅ 30-second song previews
- ✅ Song metadata (artist, album, artwork)
- ❌ Cannot play full songs (only 30s previews)

## Can I Use My Personal Apple Music Account?

**Short Answer:** Yes, but with significant limitations on web.

### For Personal Use (Testing/Development)
1. **Apple Music Web Player** - You can embed your own playlists:
   - Go to [music.apple.com](https://music.apple.com)
   - Create a public playlist
   - Get the embed code
   - Embed in your Flutter web app using `iframe`
   
2. **Limitations:**
   - ❌ User must manually authenticate on Apple Music website
   - ❌ Cannot search/browse Apple Music catalog programmatically
   - ❌ Cannot control playback from Flutter code
   - ❌ Web embeds have restricted functionality vs native apps
   - ⚠️ Only works if YOU have Apple Music subscription

### Why You Can't Just "Login" with Personal Account

Apple Music API requires:
- **Developer Token** (you create this with Apple Developer account)
- **User Token** (user logs in with their Apple ID)
- Both tokens together authenticate API requests

**You cannot:**
- Use your personal Apple Music subscription to let others play full songs
- Share your account credentials in the app
- Bypass Apple's authentication system

**This protects:**
- Copyright and licensing agreements
- Artist royalties
- Apple's business model

## Option 1: Apple Music API (Full Song Playback)

### Requirements
1. **Apple Developer Account** ($99/year)
2. **MusicKit JS** for web integration
3. **User must have Apple Music subscription**

### Implementation Steps

#### 1. Register for MusicKit
- Go to [Apple Developer Portal](https://developer.apple.com)
- Navigate to Certificates, Identifiers & Profiles
- Create a new **MusicKit Identifier**
- Generate a **MusicKit Private Key**

#### 2. Add MusicKit JS to `web/index.html`
```html
<head>
  <!-- Add before closing head tag -->
  <script src="https://js-cdn.music.apple.com/musickit/v3/musickit.js"></script>
</head>
```

#### 3. Initialize MusicKit in Flutter Web
Create `lib/utils/apple_music_service.dart`:
```dart
import 'dart:js' as js;

class AppleMusicService {
  bool _isInitialized = false;
  
  Future<void> initialize(String developerToken) async {
    if (_isInitialized) return;
    
    // Configure MusicKit
    js.context.callMethod('eval', ['''
      MusicKit.configure({
        developerToken: '$developerToken',
        app: {
          name: 'Campus Navigation',
          build: '1.0.0'
        }
      });
    ''']);
    
    _isInitialized = true;
  }
  
  Future<void> authorize() async {
    // Request user authorization
    await js.context.callMethod('eval', ['''
      (async function() {
        const music = MusicKit.getInstance();
        await music.authorize();
      })();
    ''']);
  }
  
  Future<void> playSong(String songId) async {
    await js.context.callMethod('eval', ['''
      (async function() {
        const music = MusicKit.getInstance();
        await music.setQueue({ song: '$songId' });
        await music.play();
      })();
    ''']);
  }
}
```

#### 4. Generate Developer Token
You need a server-side component to generate JWT tokens:

**Option A: Use Node.js server**
```javascript
const jwt = require('jsonwebtoken');
const fs = require('fs');

// Your MusicKit private key (.p8 file from Apple)
const privateKey = fs.readFileSync('AuthKey_XXXXXXXXXX.p8');

const token = jwt.sign({}, privateKey, {
  algorithm: 'ES256',
  expiresIn: '180d',
  issuer: 'YOUR_TEAM_ID', // From Apple Developer
  header: {
    alg: 'ES256',
    kid: 'YOUR_KEY_ID' // From MusicKit key
  }
});

console.log(token);
```

**Option B: Use online service**
- [MusicKit Cloud](https://musickit.cloud) - Managed service
- Costs: ~$10-50/month depending on usage

### Limitations
- Users MUST have active Apple Music subscription
- Only works for subscribers
- Web implementation has limited features vs native iOS

---

## Option 2: Spotify Web API (Alternative)

### Benefits
- More generous free tier than Apple Music
- Better web support
- Easier authentication flow
- Works with free Spotify accounts (with ads)

### Implementation
1. Register app at [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Get Client ID and Client Secret
3. Use `spotify` Flutter package or Web API directly
4. Implement OAuth 2.0 flow

**Quick setup:**
```yaml
# pubspec.yaml
dependencies:
  spotify: ^0.13.0
```

```dart
// Spotify authentication
final credentials = SpotifyApiCredentials(
  'YOUR_CLIENT_ID',
  'YOUR_CLIENT_SECRET',
);

final spotify = SpotifyApi(credentials);

// Search and play (requires premium for full playback)
final results = await spotify.search
    .get('Shape of You', types: [SearchType.track])
    .first(5);
```

---

## Option 3: YouTube Music API

### Benefits
- Free playback (ad-supported)
- Largest music library
- No subscription required for basic playback

### Limitations
- Unofficial API (can break)
- Terms of Service concerns
- May require workarounds

---

## Recommended Approach

### For Your Campus Navigation App:

**Keep Current Implementation (iTunes Search API)**
- ✅ No costs
- ✅ No user authentication needed
- ✅ Works for everyone
- ✅ 30s previews are sufficient for navigation mood music

**Add Repeat Functionality (DONE)**
- ✅ Loop 30s preview infinitely
- ✅ No additional cost or setup

**If Full Songs Required:**
1. Use **Spotify Web API** (easier integration, better web support)
2. Require users to connect their Spotify account
3. Display message for non-subscribers: "Preview only - Connect Spotify Premium for full songs"

---

## Current Features Implemented ✅

1. **iOS-style Loading Spinner** - CupertinoActivityIndicator
2. **Repeat Song** - Toggle button to loop current track
3. **Auto-play Next** - When repeat is OFF, plays next song automatically
4. **30s Previews** - From iTunes Search API (free)

## Cost Comparison

| Service | Setup Cost | Monthly Cost | Full Songs | Web Support |
|---------|-----------|--------------|------------|-------------|
| iTunes API (current) | $0 | $0 | ❌ (30s) | ✅ Excellent |
| Apple Music API | $99/year | $0-50 | ✅ | ⚠️ Limited |
| Spotify API | $0 | $0 | ✅ Premium | ✅ Excellent |
| YouTube Music | $0 | $0 | ✅ | ⚠️ Unofficial |

---

## Next Steps to Add Full Songs

If you want to proceed with Spotify integration:

1. Register at [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create new app and get credentials
3. Add to `pubspec.yaml`: `spotify: ^0.13.0`
4. Implement OAuth flow
5. Replace iTunes API calls with Spotify API

**Estimated development time:** 4-6 hours

Let me know if you'd like me to implement Spotify integration!
