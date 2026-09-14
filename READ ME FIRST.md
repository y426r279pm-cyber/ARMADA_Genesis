# Opening Bridge on your Mac

Written for someone who has never used Xcode. Nothing here assumes you know
Terminal, git, or Swift.

---

## The one thing that was confusing

Xcode cannot open a folder, and it cannot open a `.tar.gz` file. There is no
"Bridge.xcodeproj" in here to double-click either — that file gets made later,
and only if you want to *run* the app rather than just build it.

The only file Xcode can open right now is **`Bridge/Package.swift`**.

But you do not need to do that by hand. Read on.

---

## Step 1 · Install Xcode, if it isn't already

Bridge needs the full **Xcode** app. Not "Command Line Tools" — those are a
smaller thing with the same name in places, and they are not enough.

1. Open the **App Store** (blue circle with a white "A", in your Dock).
2. Search for **Xcode**.
3. Click **Get**, then **Install**.
4. It is about **7 GB**. Allow 20–40 minutes, and leave the Mac plugged in.
5. When it finishes, **open Xcode once** and accept the licence agreement it
   shows you. Then quit it.

You only ever do this once.

---

## Step 2 · Put this folder somewhere sensible

If you downloaded the `.tar.gz`, double-click it. macOS unpacks it into a folder
called `ARMADA_Genesis`.

Drag that folder to your **Documents** folder. Anywhere is fine, but avoid
Downloads — things get cleaned out of there.

---

## Step 3 · Double-click `START HERE.command`

Inside the folder there is a file called **`START HERE.command`**.

Double-click it.

**The first time, macOS will refuse and say it is from an unidentified
developer.** That is normal for any downloaded script. To get past it:

- **Right-click** (or Control-click) the file
- Choose **Open**
- Click **Open** again in the box that appears

A black Terminal window opens and the script:

- checks your macOS version
- checks Xcode is installed and set up properly
- builds Bridge
- opens the project in Xcode

You do not have to type anything. It may ask for your Mac password once, which
is Xcode finishing its own setup.

---

## Step 4 · What you will probably see

**Possibly a list of errors.** That is expected, and it is not a problem with
your Mac.

The first run found 95 of them, all from one file — the translations catalog.
Xcode makes a Swift name out of every translation key, and it does that by
ignoring capital letters, so `Accounts` and `accounts` became the same name
twice over. Forty-seven pairs like that, plus four keys that happened to spell
Swift's own words. All fixed, and the build now refuses to produce that class
of error again.

None of them were errors in the console's actual logic.

None of this code has ever been compiled. It was written without a Swift
compiler available, so the first build will find mistakes — wrong names, wrong
argument labels, that kind of thing. They are shallow and quick to fix.

The script saves the full list to a file called **`build-log.txt`** in the same
folder.

**Send me `build-log.txt` and I will fix the errors.** That is the fastest way
through this, and it is the step the whole project has been waiting on.

---

## Step 5 · Once it builds

In Xcode:

- **⌘B** builds it
- **⌘U** runs the tests

Three tests are worth watching:

| Test | What it proves |
|---|---|
| `CanonicalSealTests` | the sealed chain matches the browser version exactly |
| `StringAuditTests` | no wording claims fiscal validity |
| `DemoModeTests` | no model name survives into the client build |

---

## Running it as an actual app

Building and testing does not give you a window to click around in. Bridge is
currently a **library** — the engine, without the car around it.

Making it runnable is a separate job with six fiddly steps in Xcode. The
instructions are in `docs/OPENING_IN_XCODE.md`, section 4.

**My advice: don't do that yet.** Get it building first. Once the errors are
fixed, I can walk you through the app target — or generate the Xcode project for
you so it is another double-click.

---

## If something goes wrong

Whatever Terminal printed, copy it and send it to me. There is no way to break
anything here — the script only reads your Mac's configuration and builds inside
this folder.

If Terminal never opened at all, you probably left-clicked instead of
right-clicking in Step 3.
