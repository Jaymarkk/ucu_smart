# Collecting Chrome Network Details for the Campus Buildings Request

Use this guide on the **actual Chrome window running Flutter**. The browser session is not shared for remote inspection, so copy the requested details from DevTools. This is a read-only diagnostic; do not change application files.

## Find the request

1. Open Chrome DevTools with **F12** or **Ctrl+Shift+I**.
2. Select the **Network** tab.
3. Enable **Preserve log** so the request remains visible if the page reloads.
4. Enter `buildings` in the Network filter box.
5. If the canceled request is listed, select it. Otherwise, reload the Flutter page or use the building-list refresh, then select the canceled `buildings` row.

## Record the request details

With the canceled request selected:

1. In **Headers → General**, record:
   - **Request URL**
   - **Request Method**
   - **Status Code** (if shown)
2. In **Headers → Request Headers**, record only:
   - **Origin**
   - **Accept**
3. In the Network list, check whether an **OPTIONS** request for the same endpoint appears near the canceled request. If present, select it and record its URL and status.
4. Open the **Timing** tab for the canceled request. Record every phase and duration displayed, including phases marked as not applicable or absent. Common phases include:
   - Queueing or Stalled
   - DNS Lookup
   - Initial connection
   - SSL
   - Request sent
   - Waiting for server response (TTFB)
   - Content Download

If Chrome does not show a Timing tab for the canceled row, note that and record the request’s total time from the Network list.

## Share safely

Do **not** use **Copy as cURL**, **Copy all as HAR**, or share cookies, authorization headers, tokens, or other credentials. The requested fields above are sufficient for this diagnosis.

Paste the results in this format:

```text
Flutter page origin:
Request URL:
Request Method:
Origin:
Accept:
OPTIONS request present?:
OPTIONS URL/status (if present):
Canceled request status and total time:
Timing phases and durations:
```

If possible, also state whether the Flutter Chrome window was restarted with `flutter run -d chrome` after the previous request-header change. Do not include any credentials.

## Why these details matter

- An **OPTIONS** request can indicate a browser CORS preflight. Its presence or absence helps distinguish preflight behavior from a stalled GET.
- The **Origin** and **Request URL** establish whether the page and API are cross-origin and whether the app is contacting the expected host.
- Timing phases help distinguish time spent before connecting, waiting for Laravel to respond, and downloading the response.
- A canceled status alone does not establish the underlying cause. The app’s 15-second timeout explicitly aborts its pending request and currently reports a generic timeout message.

No root cause should be concluded from the canceled status alone. Compare these details with the Laravel server’s request logs and the browser console before proposing another code change.
