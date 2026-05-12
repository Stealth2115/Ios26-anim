# How to build the .deb without a PC or Mac

You don't need any computer. GitHub will compile it for you in the cloud (~3 minutes per build, completely free).

## One-time setup (5 minutes, from your iPhone)

1. **Make a GitHub account** at https://github.com/signup (skip if you have one).

2. **Create a new repository:**
   - Go to https://github.com/new
   - Repository name: `iOS26Anim` (or anything)
   - Set to **Public** (so free Actions minutes apply) or Private (2000 free minutes/month — plenty)
   - Tick "Add a README"
   - Click **Create repository**

3. **Upload these project files:**
   - In your new repo, click "Add file" → "Upload files"
   - From your iPhone, extract the `iOS26Anim.tar.gz` I gave you (use any zip app — Filza, iZip, or just the Files app long-press → Uncompress)
   - Drag/select ALL files including the `.github` folder, `Makefile`, `Tweak.x`, `control`, `iOS26Anim.plist`
   - Commit them

   *Tip: if uploading from iOS is awkward, the app "Working Copy" (free for read/write to one repo) makes this much easier.*

## Every time you want a fresh build

1. **Trigger a build:**
   - Go to your repo → **Actions** tab → **Build .deb** workflow → **Run workflow** → Run.
   - Or just push any change (edit a tunable in `Tweak.x` from the GitHub web UI → commit → CI runs).

2. **Wait ~3 minutes** for the green check.

3. **Download the .deb:**
   - Click the completed workflow run
   - Scroll to **Artifacts** at the bottom
   - Tap **iOS26Anim-deb** — it downloads as a `.zip` containing your `.deb`

4. **Install:**
   - Open the zip on your iPhone (Files app extracts it)
   - Tap the `.deb` → Open in **Sileo** → Install
   - SpringBoard resprings → open any app → enjoy the iOS 26-style animation

## Tuning without rebuilding the project structure

Once your repo is set up, you only ever need to edit **`Tweak.x`** to retune. Open it on github.com, hit the pencil icon, change the constants at the top (`kOpenResponse`, `kOpenDamping`, etc.), commit. The Action automatically rebuilds and you get a new `.deb` in 3 minutes.

## Troubleshooting

- **Action fails on "Install iOS 16.5 SDK"** → GitHub may have rate-limited the SDK download. Re-run the workflow (Actions tab → failed run → "Re-run jobs").
- **`.deb` installs but no effect** → SSH into device and check `/var/log/syslog` for `[iOS26Anim] loaded`. If absent, ellekit isn't injecting — confirm RootHide Dopamine is properly set up.
- **Crashes on respring** → Roll back: in Sileo, remove "iOS26 Animations". Then file an issue / share the crash log and I'll patch.
