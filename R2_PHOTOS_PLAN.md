# Photos on Cloudflare R2

Started 2026-10-15. Supabase's free plan allows 1 GB of file storage and about
5 GB of downloads a month. On 2026-10-15 the `farm-evidence` bucket held 9
photos (5.9 MB, about 650 KB each). R2's free tier allows 10 GB with free
downloads, and the owner has turned R2 on in the farm's Cloudflare account.

## Design

- **One small server on the app's own site.** A Cloudflare Pages Function at
  `/api/photos/*` runs on the same site as the app (`al-wahat-farm.pages.dev`,
  which already works in Egypt). Because it is the same site, the web app
  needs no new security headers. Native builds call the production site.
- **No secret keys in the app.** The function reaches R2 through a binding
  (`PHOTOS`), so no R2 key exists anywhere. The app sends its normal login
  token. The function asks the database what that user may do, using
  `public.photo_path_access`, which follows the same rules as the Supabase
  storage policies:
  - upload or delete: only in your own folder (`{your user id}/...`);
  - view: your own folder, photos on tasks you can see, or inventory images
    of your farm.
- **Viewing uses short-lived links.** `POST /api/photos/sign` returns links
  that work for one hour, the same as Supabase signed links today.
  `GET /api/photos/file/<path>?e=&s=` checks the link's signature (HMAC with
  the `PHOTO_URL_SECRET` Pages secret), so `Image.network` needs no headers.
- **Old photos stay in Supabase.** When a photo is not in R2, the function
  asks Supabase for a signed link using the user's own token, so the old
  rules still apply. Nothing is copied or deleted.
- **One bucket (`al-wahat-farm-photos`)** for staging and production, because
  they share one database.
- **Same paths and records.** `task_photos.storage_bucket_id` stays
  `farm-evidence`, and paths keep the `{user}/{farm}/{task}/{file}` form, so
  the database's viewing rules are unchanged. The only database change is that
  `add_tree_issue_photo` no longer requires the file to exist in Supabase
  storage. The folder-ownership check stays.

## Phases

| Phase | What | Status |
|---|---|---|
| P1 | Migration: `photo_path_access`; relax the storage check in `add_tree_issue_photo` | Done: Supabase repo 58013ed, applied live after a rolled-back dry run (uploader view+write, other manager view only, stranger refused, signed out refused) |
| P2 | Pages Function plus tests, `wrangler.toml` R2 binding, bucket, secrets; live check on staging with the test account (an R2 test file only, no database records) | Done: `server/photos.mjs` (11 tests: `node --test server/photos.test.mjs`); bucket `al-wahat-farm-photos`; secrets set for production and preview; staging live check 14/14, including an older Supabase photo loading through the fallback; test file deleted |
| P3 | App: `PhotoApi` client, R2 upload storage for evidence and issue photos, R2 link provider; wiring and tests | Done: `lib/core/media/photo_api.dart`, `R2TaskEvidenceStorage`, `R2IssuePhotoStorage`, `R2PhotoUrlProvider` (one link request per batch of thumbnails); `test/unit/media/photo_api_test.dart`; full suite 488 passed |
| P4 | Deploy staging and production, then check that an old photo still opens | Done (see the commit after this one) |

## Free-tier limits to watch

- R2: 10 GB stored, 1M uploads and 10M reads a month.
- Pages Functions use the Workers free plan: 100,000 requests a day, which
  covers uploads, link requests and each photo view.

## Notes

- Requests through Cloudflare took up to 30 seconds each on 2026-10-15, as the
  web deploys did that day. Photo uploads go through the offline queue, so a
  slow upload is retried rather than lost.
- To see R2 usage: Cloudflare dashboard, R2, `al-wahat-farm-photos`.
- Old photos stay in Supabase. To free that space later, copy them to R2 under
  the same paths; the function then serves them from R2.
