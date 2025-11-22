# Campus Navigation Backend Requirements

## Executive Summary

Your Flutter web app currently uses:
- ✅ **iTunes Search API** (music previews - no backend needed)
- ✅ **OpenStreetMap APIs** (Overpass API, OSRM routing - no backend needed)
- ✅ **Local storage** (SharedPreferences - user settings/favorites)
- ❌ **Mock data** (events, user profiles - needs backend)

**Backend is needed for:**
1. User authentication & profiles
2. Live events management
3. Real-time notifications
4. Favorites sync across devices
5. Admin dashboard
6. Analytics & reporting

---

## 1. Technology Stack Recommendations

### Option A: Firebase (Recommended - Fastest Setup)
**Best for:** Quick deployment, low initial cost, automatic scaling

```yaml
Services Needed:
- Firebase Authentication (email, Google, Apple sign-in)
- Cloud Firestore (NoSQL database)
- Firebase Storage (user avatars, event images)
- Cloud Functions (serverless backend logic)
- Firebase Cloud Messaging (push notifications)
- Firebase Hosting (web deployment - alternative to Vercel)
- Firebase Analytics (user behavior tracking)
```

**Pros:**
- ✅ No server management
- ✅ Real-time sync out of the box
- ✅ Free tier generous (up to 50k reads/day)
- ✅ Excellent Flutter integration
- ✅ Setup time: 1-2 days

**Cons:**
- ❌ Vendor lock-in
- ❌ Complex queries can be expensive
- ❌ Limited to Firebase SDK patterns

**Cost Estimate:**
- Free tier: Good for 1000+ daily active users
- Paid tier: ~$25-100/month for 5000+ users

### Option B: Node.js + MongoDB + Express (Full Control)
**Best for:** Custom business logic, complex queries, data ownership

```javascript
Stack:
- Node.js + Express.js (REST API)
- MongoDB (database)
- JWT (authentication)
- Socket.io (real-time updates)
- AWS S3 / Cloudinary (file storage)
- Redis (caching, sessions)
- PM2 (process management)
```

**Pros:**
- ✅ Full control over data
- ✅ Can migrate hosting providers
- ✅ Flexible querying
- ✅ Can integrate any third-party service

**Cons:**
- ❌ Requires DevOps knowledge
- ❌ Manual scaling
- ❌ Setup time: 1-2 weeks

**Cost Estimate:**
- VPS (DigitalOcean/Linode): $10-50/month
- Database hosting: $10-30/month
- Storage: $5-20/month
- **Total: ~$25-100/month**

### Option C: Supabase (Firebase Alternative - Open Source)
**Best for:** Firebase-like experience with PostgreSQL power

```yaml
Services:
- Supabase Auth (authentication)
- PostgreSQL (relational database)
- Supabase Storage (file uploads)
- Realtime subscriptions (WebSocket)
- Edge Functions (serverless)
- Row-level security
```

**Pros:**
- ✅ Open source (self-hostable)
- ✅ SQL database (powerful queries)
- ✅ Real-time out of the box
- ✅ Great free tier

**Cons:**
- ❌ Newer platform (less mature than Firebase)
- ❌ Smaller ecosystem

**Cost Estimate:**
- Free tier: 500MB database, 1GB storage
- Pro tier: $25/month

---

## 2. Database Schema Design

### Users Collection/Table
```json
{
  "id": "user_123",
  "email": "student@iuokada.edu.ng",
  "displayName": "John Doe",
  "studentId": "IU/2021/12345",
  "department": "Computer Science",
  "level": "300",
  "phone": "+234812345678",
  "avatarUrl": "https://storage.../avatar.jpg",
  "isPremium": false,
  "registrationDate": "2025-11-22T10:00:00Z",
  "lastLogin": "2025-11-22T14:30:00Z",
  "settings": {
    "mapStyle": "standard",
    "navigationMode": "foot",
    "darkMode": true,
    "notifications": true
  },
  "stats": {
    "routesCreated": 45,
    "eventsAttended": 12,
    "favoriteBuildings": ["library", "cafeteria"]
  }
}
```

### Events Collection/Table
```json
{
  "id": "evt_123",
  "title": "Campus Concert",
  "description": "Annual music festival...",
  "venue": "Main Auditorium",
  "venueId": "main_auditorium",
  "location": {
    "latitude": 6.7415,
    "longitude": 5.4055
  },
  "category": "cultural",
  "organizer": "Student Union",
  "organizerId": "org_456",
  "startTime": "2025-11-25T18:00:00Z",
  "endTime": "2025-11-25T21:00:00Z",
  "imageUrl": "https://storage.../event.jpg",
  "isFeatured": true,
  "isPublished": true,
  "maxAttendees": 500,
  "currentAttendees": 234,
  "requiresRSVP": true,
  "attendees": ["user_123", "user_456"],
  "tags": ["music", "entertainment"],
  "contactEmail": "events@iuokada.edu.ng",
  "contactPhone": "+234801234567",
  "createdAt": "2025-11-20T10:00:00Z",
  "updatedAt": "2025-11-22T14:00:00Z",
  "status": "live" // draft, scheduled, live, ended, cancelled
}
```

### Favorites Collection/Table
```json
{
  "id": "fav_123",
  "userId": "user_123",
  "buildingId": "library",
  "buildingName": "Main Library",
  "savedAt": "2025-11-22T12:00:00Z",
  "visitCount": 15,
  "lastVisited": "2025-11-22T14:00:00Z",
  "notes": "Best place to study"
}
```

### Buildings Collection/Table (Enhanced)
```json
{
  "id": "library_001",
  "name": "Main Library",
  "category": "library",
  "location": {
    "latitude": 6.7415,
    "longitude": 5.4055
  },
  "entrance": {
    "latitude": 6.7416,
    "longitude": 5.4056
  },
  "description": "University library with...",
  "openingHours": "Mon-Fri: 8AM-10PM",
  "amenities": ["WiFi", "AC", "Study Rooms"],
  "images": ["url1", "url2"],
  "capacity": 500,
  "currentOccupancy": 234,
  "phoneNumber": "+234801234567",
  "email": "library@iuokada.edu.ng",
  "rating": 4.5,
  "reviews": [
    {
      "userId": "user_123",
      "rating": 5,
      "comment": "Excellent facility",
      "timestamp": "2025-11-20T10:00:00Z"
    }
  ]
}
```

### Notifications Collection/Table
```json
{
  "id": "notif_123",
  "userId": "user_123",
  "type": "event_reminder", // event_reminder, system, announcement
  "title": "Event Starting Soon",
  "message": "Campus Concert starts in 1 hour",
  "data": {
    "eventId": "evt_123",
    "action": "navigate_to_event"
  },
  "isRead": false,
  "createdAt": "2025-11-22T17:00:00Z",
  "expiresAt": "2025-11-25T00:00:00Z"
}
```

### Analytics Collection/Table
```json
{
  "id": "analytics_123",
  "userId": "user_123",
  "eventType": "route_created", // route_created, building_viewed, event_rsvp
  "timestamp": "2025-11-22T14:30:00Z",
  "data": {
    "from": "Main Gate",
    "to": "Library",
    "distance": 1200,
    "transportMode": "foot"
  },
  "sessionId": "session_789",
  "deviceInfo": {
    "platform": "web",
    "browser": "Chrome",
    "screenSize": "1920x1080"
  }
}
```

---

## 3. API Endpoints Required

### Authentication
```
POST   /api/auth/register          - Create new user account
POST   /api/auth/login             - Email/password login
POST   /api/auth/google            - Google OAuth login
POST   /api/auth/logout            - Logout user
POST   /api/auth/forgot-password   - Send password reset email
POST   /api/auth/reset-password    - Reset password with token
GET    /api/auth/me                - Get current user profile
PUT    /api/auth/me                - Update user profile
```

### Events
```
GET    /api/events                 - List all events (with filters)
GET    /api/events/live            - Get currently active events
GET    /api/events/upcoming        - Get upcoming events
GET    /api/events/today           - Get today's events
GET    /api/events/:id             - Get single event details
POST   /api/events                 - Create new event (admin/organizer)
PUT    /api/events/:id             - Update event (admin/organizer)
DELETE /api/events/:id             - Delete event (admin only)
POST   /api/events/:id/rsvp        - RSVP to event
DELETE /api/events/:id/rsvp        - Cancel RSVP
GET    /api/events/:id/attendees   - List event attendees
```

### Favorites
```
GET    /api/favorites              - Get user's favorite buildings
POST   /api/favorites              - Add building to favorites
DELETE /api/favorites/:id          - Remove from favorites
PUT    /api/favorites/:id/note     - Update favorite notes
```

### Buildings
```
GET    /api/buildings              - List all buildings (with filters)
GET    /api/buildings/:id          - Get building details
POST   /api/buildings/:id/review   - Add building review
GET    /api/buildings/:id/reviews  - Get building reviews
PUT    /api/buildings/:id          - Update building (admin only)
```

### Notifications
```
GET    /api/notifications          - Get user notifications
PUT    /api/notifications/:id/read - Mark notification as read
PUT    /api/notifications/read-all - Mark all as read
DELETE /api/notifications/:id      - Delete notification
POST   /api/notifications/token    - Register FCM token for push
```

### Admin
```
GET    /api/admin/users            - List all users
GET    /api/admin/analytics        - Get usage analytics
POST   /api/admin/broadcast        - Send notification to all users
PUT    /api/admin/users/:id/role   - Update user role
GET    /api/admin/events/pending   - Get events pending approval
PUT    /api/admin/events/:id/approve - Approve event
```

### Search
```
GET    /api/search?q=library       - Search buildings, events, etc.
GET    /api/search/suggestions     - Get search suggestions
```

---

## 4. Real-time Features (WebSocket/Firebase Realtime)

### Live Event Updates
```javascript
// Subscribe to live events
socket.on('events:live', (events) => {
  // Update UI with new live events
});

// Event started notification
socket.on('event:started', (event) => {
  // Show "Event is now live!" notification
});

// Event ended notification
socket.on('event:ended', (eventId) => {
  // Remove from live events banner
});
```

### Building Occupancy (Future)
```javascript
socket.on('building:occupancy', (data) => {
  // Update building capacity display
  // { buildingId: 'library', occupancy: 75, capacity: 500 }
});
```

---

## 5. File Storage Requirements

### User Avatars
- **Size**: Max 2MB
- **Format**: JPEG, PNG, WebP
- **Resolution**: 512x512px (auto-resize)
- **Storage**: ~50MB per 1000 users

### Event Images
- **Size**: Max 5MB
- **Format**: JPEG, PNG
- **Resolution**: 1920x1080px (auto-resize to multiple sizes)
- **Storage**: ~200MB per 1000 events

### Building Images
- **Multiple photos per building**
- **Size**: Max 10MB each
- **Format**: JPEG, PNG
- **Storage**: ~500MB for all campus buildings

**Total Storage Estimate:** ~1-2GB for first year

---

## 6. Security Requirements

### Authentication
- JWT tokens with 7-day expiry
- Refresh tokens for persistent sessions
- Email verification required
- Password requirements: min 8 chars, 1 uppercase, 1 number
- Rate limiting: 5 failed login attempts = 15min lockout

### Authorization
- Role-based access control (RBAC)
  - **User**: Basic access (view, RSVP, favorites)
  - **Organizer**: Create/edit own events
  - **Admin**: Full access (approve events, manage users)
  - **Super Admin**: System configuration

### Data Protection
- HTTPS only (SSL/TLS)
- Encrypt sensitive data at rest
- Hash passwords with bcrypt (salt rounds: 12)
- Sanitize all user inputs (prevent XSS, SQL injection)
- CORS configured for your domain only

### API Rate Limiting
```
Anonymous users: 100 requests/hour
Authenticated users: 1000 requests/hour
Admin users: 5000 requests/hour
```

---

## 7. Push Notifications

### Firebase Cloud Messaging (FCM) Setup
```dart
// Flutter side (already implemented in your app)
await FirebaseMessaging.instance.requestPermission();
String? token = await FirebaseMessaging.instance.getToken();
// Send token to backend
```

### Backend sends notifications:
```javascript
// Event reminder (1 hour before)
await sendNotification({
  userId: 'user_123',
  title: 'Event Starting Soon',
  body: 'Campus Concert starts in 1 hour at Main Auditorium',
  data: { eventId: 'evt_123', action: 'open_event' }
});

// New event posted
await sendBroadcast({
  title: 'New Event: Tech Workshop',
  body: 'AI & Machine Learning workshop this Saturday',
  data: { eventId: 'evt_456' }
});
```

### Notification Types
1. **Event Reminders** (1 hour before, 15 mins before)
2. **New Featured Events**
3. **Event Updates** (time/venue changed)
4. **Event Cancellations**
5. **System Announcements**
6. **RSVP Confirmations**

---

## 8. Analytics & Reporting

### User Metrics
- Daily/Monthly Active Users (DAU/MAU)
- New registrations per day
- User retention rate
- Most popular routes
- Peak usage times

### Event Metrics
- Total events created
- Average attendance rate
- Most popular event categories
- RSVP → Attendance conversion
- Event engagement time

### Building Metrics
- Most searched buildings
- Most favorited buildings
- Average route distance
- Popular destinations by time of day

### System Health
- API response times
- Error rates
- Database query performance
- Storage usage

---

## 9. Admin Dashboard Requirements

### Overview Page
- Total users, events, buildings
- Real-time active users
- Today's events
- System health metrics

### User Management
- List all users (search, filter)
- View user details
- Suspend/activate accounts
- Assign roles (organizer, admin)
- View user activity logs

### Event Management
- Approve pending events
- Edit/delete any event
- Feature/unfeature events
- Send event reminders
- View attendance reports

### Analytics Dashboard
- Charts (users over time, popular routes)
- Export data to CSV/Excel
- Custom date range reports

### Content Management
- Update building information
- Upload building photos
- Manage amenities list
- Update opening hours

### Notifications
- Send broadcast notifications
- Schedule notifications
- View notification history
- Notification templates

---

## 10. Implementation Roadmap

### Phase 1: Core Backend (Week 1-2)
- [ ] Setup Firebase/Backend infrastructure
- [ ] User authentication (email/password)
- [ ] User profile CRUD
- [ ] Events CRUD API
- [ ] Basic admin dashboard

### Phase 2: Real-time Features (Week 3)
- [ ] Live events WebSocket/Firebase Realtime
- [ ] Push notifications setup
- [ ] Event RSVP system
- [ ] Favorites sync across devices

### Phase 3: Enhanced Features (Week 4)
- [ ] Google/Apple OAuth login
- [ ] Advanced search & filters
- [ ] Analytics dashboard
- [ ] Building reviews/ratings

### Phase 4: Admin & Polish (Week 5-6)
- [ ] Full admin dashboard
- [ ] Event approval workflow
- [ ] Bulk notification system
- [ ] API documentation
- [ ] Load testing & optimization

---

## 11. Flutter App Integration Changes

### Add Firebase to Flutter
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  firebase_messaging: ^14.7.0
  firebase_storage: ^11.5.0
```

### Initialize Firebase
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### Authentication Service
```dart
// lib/services/auth_service.dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }
  
  Future<User?> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }
  
  Future<void> signOut() => _auth.signOut();
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
```

### API Service (if using REST backend)
```dart
// lib/services/api_service.dart
class ApiService {
  final String baseUrl = 'https://your-api.com';
  String? _token;
  
  Future<List<CampusEvent>> getLiveEvents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/events/live'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    final data = jsonDecode(response.body);
    return (data['events'] as List)
      .map((e) => CampusEvent.fromJson(e))
      .toList();
  }
  
  Future<void> rsvpEvent(String eventId) async {
    await http.post(
      Uri.parse('$baseUrl/api/events/$eventId/rsvp'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );
  }
}
```

---

## 12. Cost Breakdown

### Option 1: Firebase (Recommended for MVP)
```
Free Tier Limits:
- 50,000 document reads/day
- 20,000 document writes/day
- 1GB storage
- 10GB/month bandwidth
- 125K Cloud Function invocations

Estimated Costs (5000 DAU):
- Firestore: $25-50/month
- Storage: $10-20/month
- Functions: $10-15/month
- FCM: Free
Total: $45-85/month
```

### Option 2: Custom Backend
```
- VPS (4GB RAM, 2 CPU): $40/month
- MongoDB Atlas (Shared): $15/month
- Cloudinary (images): $25/month
- SendGrid (emails): $15/month
Total: $95/month
```

### Option 3: Supabase
```
Free Tier: Good for 1000 DAU
Pro Tier: $25/month (10K DAU)
```

---

## 13. Development Resources Needed

### Backend Developer Skills
- Node.js/Express OR Firebase Admin SDK
- Database design (SQL/NoSQL)
- REST API design
- Authentication (JWT, OAuth)
- Real-time systems (WebSockets/Firebase)
- Cloud deployment (Firebase/AWS/Heroku)

### Tools & Services
- Postman (API testing)
- MongoDB Compass / Firestore Console
- Git (version control)
- VS Code / WebStorm
- Cloudinary/AWS S3 (image hosting)
- SendGrid/Mailgun (emails)

### Documentation
- Swagger/OpenAPI (API docs)
- Postman Collections
- Database schema diagrams
- Deployment guides

---

## 14. Testing Strategy

### Unit Tests
- API endpoint logic
- Database queries
- Authentication flows
- Data validation

### Integration Tests
- End-to-end API flows
- Firebase rules testing
- Notification delivery
- File upload/download

### Load Testing
- 1000 concurrent users
- API response time < 200ms
- Database query optimization
- CDN caching strategy

---

## Next Steps to Start Backend Development:

1. **Choose Stack** (Firebase recommended for speed)
2. **Setup Project** (create Firebase project or deploy Node.js server)
3. **Design Database** (implement schemas above)
4. **Build Auth API** (login, signup, profile)
5. **Build Events API** (CRUD operations)
6. **Integrate with Flutter** (update LiveEventsService to use real API)
7. **Add Push Notifications** (FCM setup)
8. **Build Admin Dashboard** (React/Vue or Flutter Web)
9. **Deploy & Test** (production deployment)
10. **Monitor & Optimize** (analytics, error tracking)

**Estimated Timeline:** 4-6 weeks for full backend MVP

Let me know which stack you prefer and I can provide detailed setup instructions!
