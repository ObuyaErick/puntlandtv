# Puntland TV App Proposal

A modern media application requires a seamless blend of live broadcasting, rich text articles, and on-demand video, mirroring the standard set by apps like Citizen Digital and CNN.

## Core Feature Matrix

| Feature                   | Description                                                                                                        | Priority      |
| :------------------------ | :----------------------------------------------------------------------------------------------------------------- | :------------ |
| **Live TV Streaming**     | 24/7 seamless streaming of the Puntland TV broadcast using HLS/DASH protocols with a persistent mini-player.       | High          |
| **Dynamic News Feed**     | Categorized text and media articles (Politics, Sports, Local, Global) with infinite scrolling and pull-to-refresh. | High          |
| **Video on Demand (VOD)** | Catch-up TV for missed shows, organized by program, date, and popularity.                                          | High          |
| **Breaking News Alerts**  | Firebase Cloud Messaging (FCM) integration for real-time push notifications on critical events.                    | High          |
| **Live Radio/Audio**      | Background audio streaming for users who want to listen to broadcasts while using other apps.                      | Medium        |
| **Bookmarks & Offline**   | Local SQLite storage allowing users to save text articles for offline reading.                                     | Medium        |
| **User Authentication**   | Optional login via Google/Apple/Email to sync bookmarks and personalize the news feed.                             | Low (Phase 2) |

## Technical Architecture

Given the scale of a national broadcaster, the system must handle high traffic spikes during breaking news.

- **Frontend (Mobile):** Flutter (Dart) for unified Android and iOS delivery. State management can be handled via Riverpod or BLoC to manage complex video player states and data streams efficiently.
- **Backend Services:** Node.js paired with NestJS to build a robust, scalable REST API.
- **Database:** PostgreSQL managed via Prisma to handle article metadata, user profiles, and categorization.
- **Video Delivery:** Service to transcode the live TV feed into HLS streams, served via a global CDN (like Cloudflare) to minimize latency.
- **Content Management:** A headless CMS (like Strapi) or a custom internal dashboard for journalists to publish articles and upload VOD content instantly.
