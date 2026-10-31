# Project: Phone-First Website Updater (working idea)

*Synopsis of a conversation with Claude, Oct 31, 2026*

## Where the idea came from

I built a phone app (`upload.html`) for my photography site, liamdevine.ca, with Claude's help. From my phone I can upload photos, organize them and frame the homepage hero shot. Every time I use it, I think nobody else offers this. When I show people, they're blown away, even though it feels simple to me.

## The idea

Take the same easy, phone-first experience and turn it into a product for **any business with a website**: gyms, butchers, bakers, soap makers, retail stores, artists.

- A business owner gets an idea at 9 PM ("ribeye on special tomorrow").
- They open the app, type a paragraph or post a photo, tap once, and it's live on their existing website in seconds.
- No calling the web developer, no logging into Wix or Squarespace, no training.
- **Why it matters:** when people Google a business, they land on its **website**, not its Instagram, and that page is usually the most out of date.
- Goal: easier than Wix, easier than Squarespace.

## Key decisions and views

- **Sell directly to the business owner**, not through web designers. The owner does all the updates themselves.
- **One-time setup is the only hurdle.** The website has to be connected to the app once. Ways to make that easy:
  - a guided in-app walkthrough ("your site is on Wix? copy this, paste it here")
  - plugins or app-store listings for WordPress, Wix and Shopify
  - early on, setting it up for customers free on a quick call
- **The current build is a proof of concept, not the blueprint.** Cloudinary, GitHub and static pages were the right shortcuts for one site. A product can use different plumbing behind the same front end.
- **Text editing is easy to add.** It uses the same pattern as the existing photo settings files.

## How my current uploader works

- Photos and two settings files (`portfolio-config.json`, `hero-config.json`) live on **Cloudinary**.
- `index.html` reads them from Cloudinary on every visit. `upload.html` is the phone app that changes them.
- The site is hosted from GitHub, with no custom server or database.

### What's tied to my site (would need generalizing)

1. Cloudinary account name (`dywzapiql`) and upload preset (`liam_uploads`), hardcoded in both `upload.html` and `index.html`
2. My 9 photo categories and their default visibility
3. Links from each category to its section on my site
4. My domain (status line, "View on site" button, default hero photo)
5. My hero layout, copied exactly in the preview ("Making the Ordinary Extraordinary" headline, font, gradient)
6. My GoatCounter view counter
7. Branding ("LD Upload", logo, tungsten-orange camera look)
8. **Sign-in:** I paste my Cloudinary API key and secret into the app on each device. Fine for me, not workable for customers. A product needs real accounts and a small server that keeps secrets off the phone.

## What makes mine different (Claude's take)

1. **Phone-first**, not a desktop editor squeezed onto a phone, with a distinctive camera-style interface (viewfinder, shutter button).
2. **The hero editor:** pinch and drag framing with separate computer and phone previews that match exactly what visitors see. Not common in mainstream tools.
3. **Three visibility states per category:** hidden, app-only (build privately) and live on site.
4. **No server or database:** cheap to run, hard to break.
5. **Real-world iPhone polish:** dictation that doesn't glitch, automatic retries, clear error messages, duplicate-name warnings, automatic numbering for batch uploads.

## Competition to keep in mind

- **Website builders** (Squarespace, Wix, Format, Pixieset, SmugMug): good phone apps, but they lock you into their platform.
- **Git-based content editors** (Decap, TinaCMS, CloudCannon, Pages CMS): they work with any site but are built for developers, focus on text and are clunky on phones.
- **Google Business Profile posts and Instagram:** where many shops already post specials, so it's a habit to compete with.
- **Embeddable widget tools:** worth checking whether any already focus on fast phone updates.

## What a product would need

- Accounts and a small server, so each business only sees and edits its own content
- A way to connect any existing site once (a snippet, a plugin or done-for-you setup)
- The phone app: my current interface made general, with flexible "slots" (specials, announcements, hours, photos, paragraphs) and a live preview

## Cheapest way to test it

1. Find one real business I know (a gym, butcher, bakery).
2. Connect their site and give them the app.
3. Watch whether they use it weekly without being reminded, and whether they ask what it costs.

## Status

- Parked for now. No rush. Focus is on my job and on building **Stillforge** with Maxx.
- Possible next steps when I return:
  - mock up the owner's "post something now" screen in the current app's style
  - sketch the product architecture (accounts, server, site connection)
  - add text editing to my own site first as a test

## Side notes from the same conversation

- Looked at **BAMA (Build Any Mac App)**, agent skills from `daveebbelaar/bama` on GitHub. It builds **Mac apps only**, so I skipped it because I'm more interested in iPhone apps. Reminder cancelled.
- For iPhone apps, I already have Xcode, and Claude Code running on my Mac can write Swift and SwiftUI and test in the iPhone simulator. No extra tool needed. (Cloud sessions can't run Xcode.)
